//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import MapKit
import CoreData

protocol PhotoAlbumViewControllerDelegate {
    
    func photoAlbum(photoAlbum: PhotoAlbumViewController, didUpdatePin pin: Pin?)
}

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var emptyPlaceholderView: UIView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    @IBOutlet weak var defaultToolbar: UIToolbar!
    @IBOutlet weak var selectionToolbar: UIToolbar!

    var pin: Pin!
    var delegate: PhotoAlbumViewControllerDelegate?

    var updates: (() -> ()) = {}
    var shouldReloadCollectionView = false

    var sharedContext: NSManagedObjectContext {

        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController

    }()

    private let itemSpacer: CGFloat = 8.0
    private let itemPerRow: CGFloat = 3.0


    override func viewDidLoad() {

        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        mapView.delegate = self
        fetchedResultsController.delegate = self

        photoCollectionView.allowsMultipleSelection = true
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        // setup photos
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("Error in retrieving photos: \(error)")
        }

        // setup pin
        mapView.addAnnotation(pin)

        centerMapOnPinLocation()
        setupViewInsets()
        recalculateItemDimension()
        toggleToolbar()
        toggleEmptyPlaceholder()
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func getNewBarButtonTapped(sender: UIBarButtonItem) {

        fetchedResultsController.fetchedObjects?.forEach {
            sharedContext.deleteObject($0 as! NSManagedObject)
            CoreDataStackManager.sharedInstance().saveContext()
        }

        let blockerView = BlockerView(frame: view.frame)
        blockerView.backgroundShade.backgroundColor = UIColor.blackColor()
        view.addSubview(blockerView)

        let bBox = createBoundingBoxStringFromAnnotation(pin)
        FlickrClient.sharedInstance().getPublicPhotosWithBoundingBox(bBox) { photos, errorString in

            defer {
                self.refreshPinAsync(self.pin)
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                    do {
                        try self.fetchedResultsController.performFetch()
                    } catch {}
                })
            }

            self.removeViewAsync(blockerView)

            if let err = errorString {
                self.displayErrorAsync(err)
                return
            }

            if let fetchedPhotos = photos {
                dispatch_async(dispatch_get_main_queue(), {
                    let _ = fetchedPhotos.map() { (dictionary: [String: AnyObject]) -> Photo in
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        photo.pin = self.pin
                        return photo
                    }
                })
            }
        }
    }

    @IBAction func addToFavoritesBarButtonTapped(sender: UIBarButtonItem) {

        if let indexPaths = photoCollectionView.indexPathsForSelectedItems() {
            let sortedIndexes = indexPaths.sort { $1.item < $0.item }
            sortedIndexes.forEach { indexPath in

                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

                let dict = [
                    Constants.Flickr.JSONResponse.Id: photo.id,
                    Constants.Flickr.JSONResponse.Title: photo.title,
                    Constants.Flickr.JSONResponse.Url: photo.url
                ]

                let _ = Favorite(dictionary: dict, context: self.sharedContext)
                CoreDataStackManager.sharedInstance().saveContext()

                photoCollectionView.deselectItemAtIndexPath(indexPath, animated: true)
            }

            photoCollectionView.reloadData()
            self.toggleToolbar()

            let alertCtrl = UIAlertController(title: "Notice", message: "Photo(s) have been added to your favorite list", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertCtrl.addAction(okAction)
            presentViewController(alertCtrl, animated: true, completion: nil)
        }
    }

    @IBAction func deleteBarButtonTapped(sender: UIBarButtonItem) {

        if let indexPaths = photoCollectionView.indexPathsForSelectedItems() {
            let sortedIndexes = indexPaths.sort { $1.item < $0.item }
            sortedIndexes.forEach { indexPath in

                let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                sharedContext.deleteObject(photo)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            refreshPinAsync(pin)
        }
    }

    private func centerMapOnPinLocation() {

        let initialLocation = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
        let regionRadius: CLLocationDistance = 5000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }

    private func setupViewInsets() {

        photoCollectionView.contentInset = UIEdgeInsetsMake(itemSpacer, itemSpacer, itemSpacer, itemSpacer)
    }

    private func recalculateItemDimension() {

        // add spacing in between items and at both left/right ends
        let dimension = (self.view.frame.size.width - ((itemPerRow + 1) * itemSpacer)) / itemPerRow
        flowLayout.minimumLineSpacing = itemSpacer
        flowLayout.minimumInteritemSpacing = itemSpacer
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }

    private func configureCell(cell: PhotoCollectionViewCell, withPhoto photo: Photo) {

        toggleCellAlpha(cell)

        if let localImage = photo.locationImage {
            cell.photoImageView.image = localImage

        } else {
            
            let placeholderView = PlaceholderView(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
            cell.addSubview(placeholderView)

            FlickrClient.sharedInstance().taskForImageWithUrl(photo.url) { imageData, error in

                self.removeViewAsync(placeholderView)
                if let data = imageData {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        if (!photo.fault) {
                            photo.locationImage = image
                        }
                        cell.photoImageView.image = image
                    }
                }
            }
        }
    }

    private func refreshPinAsync(pin: Pin) {

        dispatch_async(dispatch_get_main_queue(), {
            pin.shouldDrop = false
            self.mapView.removeAnnotation(pin)
            self.mapView.addAnnotation(pin)
            self.delegate?.photoAlbum(self, didUpdatePin: pin)
        })
    }

    private func toggleToolbar() {

        if photoCollectionView.indexPathsForSelectedItems()?.count == 0 {
            defaultToolbar.hidden = false
            selectionToolbar.hidden = true
        } else {
            defaultToolbar.hidden = true
            selectionToolbar.hidden = false
        }
    }

    private func toggleEmptyPlaceholder() {

        if(fetchedResultsController.fetchedObjects?.count == 0) {
            emptyPlaceholderView.hidden = false
        } else {
            emptyPlaceholderView.hidden = true
        }
    }

    private func toggleCellAlpha(cell: UICollectionViewCell) {

        if cell.selected {
            cell.alpha = 0.3
        } else {
            cell.alpha = 1.0
        }
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        if let annotation = annotation as? Pin {
            let identifier = "pin"
            var view: MKPinAnnotationView

            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }

            let pinColor = annotation.hasPhoto ? MKPinAnnotationView.greenPinColor() : MKPinAnnotationView.redPinColor()
            view.pinTintColor = pinColor

            view.canShowCallout = false
            view.animatesDrop = false

            return view
        }
        return nil
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        let collectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionCell", forIndexPath: indexPath) as! PhotoCollectionViewCell

        configureCell(collectionCell, withPhoto: photo)

        return collectionCell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath)!
        toggleCellAlpha(cell)
        toggleToolbar()
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath)!
        toggleCellAlpha(cell)
        toggleToolbar()
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        shouldReloadCollectionView = false
        return
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

        switch type {
        case .Insert:
            photoCollectionView.insertSections(NSIndexSet(index: sectionIndex))

        case .Delete:
            photoCollectionView.deleteSections(NSIndexSet(index: sectionIndex))

        default:
            return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {

        case .Insert:

            guard let idxPath = indexPath where
                photoCollectionView.numberOfItemsInSection(idxPath.section) != 0 else {

                self.shouldReloadCollectionView = true
                return
            }
            updates = {
                self.photoCollectionView.insertItemsAtIndexPaths([newIndexPath!])
            }

        case .Delete:

            guard let idxPath = indexPath where
                photoCollectionView.numberOfItemsInSection(idxPath.section) != 1 else {

                    self.shouldReloadCollectionView = true
                    return
            }
            updates = {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
            }

        case .Update:

            let cell = photoCollectionView.cellForItemAtIndexPath(indexPath!) as! PhotoCollectionViewCell
            let photo = controller.objectAtIndexPath(indexPath!) as! Photo
            configureCell(cell, withPhoto: photo)

        case .Move:
            
            updates = {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
                self.photoCollectionView.insertItemsAtIndexPaths([newIndexPath!])
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        if(shouldReloadCollectionView) {
            photoCollectionView.reloadData()
        } else {
            photoCollectionView.performBatchUpdates(updates, completion: nil)
        }

        toggleToolbar()
        toggleEmptyPlaceholder()
    }
}