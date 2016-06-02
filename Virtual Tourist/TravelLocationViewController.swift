//
//  TravelLocationViewController.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import MapKit
import CoreData

class TravelLocationViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    var pins = [Pin]()

    var sharedContext: NSManagedObjectContext {

        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    private var filePath: String {

        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    

    override func viewDidLoad() {

        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        mapView.delegate = self

        pins = fetchAllPins()
        mapView.addAnnotations(pins)
        
        restoreMapRegion(false)
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let pin = sender as? Pin else {
            return
        }

        let photoAlbumVc = segue.destinationViewController as! PhotoAlbumViewController
        photoAlbumVc.pin = pin
        photoAlbumVc.delegate = self
    }


    @IBAction func clearAllBarButtonTapped(sender: UIBarButtonItem) {

        pins.forEach { pin in
            sharedContext.deleteObject(pin)
            CoreDataStackManager.sharedInstance().saveContext()
        }

        mapView.removeAnnotations(mapView.annotations)
    }

    @IBAction func mapViewLongPressed(sender: UILongPressGestureRecognizer) {

        if sender.state == .Began {
            let point = sender.locationInView(view)
            let coordinate = mapView.convertPoint(point, toCoordinateFromView: view)

            let dict: [String: AnyObject] = [
                Constants.Pin.Latitude: coordinate.latitude,
                Constants.Pin.Longitude: coordinate.longitude
            ]

            let pin = Pin(dictionary: dict, context: sharedContext)

            pins.append(pin)
            mapView.addAnnotation(pin)
            retrieveNewPhotosForPin(pin)
        }
    }

    private func retrieveNewPhotosForPin(pin: Pin) {

        pin.photos.forEach {
            sharedContext.deleteObject($0)
            CoreDataStackManager.sharedInstance().saveContext()
        }

        let blockerView = BlockerView(frame: view.frame)
        blockerView.backgroundShade.backgroundColor = UIColor.blackColor()
        view.addSubview(blockerView)

        let bBox = createBoundingBoxStringFromAnnotation(pin)
        FlickrClient.sharedInstance().getPublicPhotosWithBoundingBox(bBox) { photos, errorString in

            defer {
                self.refreshPinAsync(pin)
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            }

            self.removeViewAsync(blockerView)

            if let err = errorString {
                self.displayErrorAsync(err)
                return
            }

            let hasPhoto = photos?.count > 0
            if !hasPhoto {
                self.displayErrorAsync("Could not find any photos in that location")
                return
            }

            if let fetchedPhotos = photos {
                dispatch_async(dispatch_get_main_queue(), {
                    let _ = fetchedPhotos.map() { (dictionary: [String: AnyObject]) in
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        photo.pin = pin
                        return
                    }
                })
            }
        }

    }

    private func refreshPinAsync(pin: Pin) {

        dispatch_async(dispatch_get_main_queue(), {
            pin.shouldDrop = false
            self.mapView.removeAnnotation(pin)
            self.mapView.addAnnotation(pin)
        })
    }

    private func fetchAllPins() -> [Pin] {

        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch  let error as NSError {
            print("Error in fecthing pins: \(error)")
            return [Pin]()
        }
    }

    private func saveMapRegion() {

        let dictionary = [
            Constants.MapRegion.Latitude: mapView.region.center.latitude,
            Constants.MapRegion.Longitude: mapView.region.center.longitude,
            Constants.MapRegion.LatitudeDelta: mapView.region.span.latitudeDelta,
            Constants.MapRegion.LongitudeDelta: mapView.region.span.longitudeDelta
        ]

        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }

    private func restoreMapRegion(animated: Bool) {

        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String: AnyObject] {

            let latitude = regionDictionary[Constants.MapRegion.Latitude] as! CLLocationDegrees
            let longitude = regionDictionary[Constants.MapRegion.Longitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            let longitudeDelta = regionDictionary[Constants.MapRegion.LatitudeDelta] as! CLLocationDegrees
            let latitudeDelta = regionDictionary[Constants.MapRegion.LongitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

            let savedRegion = MKCoordinateRegionMake(center, span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}


extension TravelLocationViewController: MKMapViewDelegate {

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

            view.animatesDrop = annotation.shouldDrop
            view.draggable = true
            view.canShowCallout = false

            let tapRec = UITapGestureRecognizer(target: self, action: "pinTapped:")
            view.addGestureRecognizer(tapRec)

            return view
        }
        return nil
    }

    func pinTapped(sender: UITapGestureRecognizer) {

        let annotationView = sender.view as? MKAnnotationView
        guard let pin = annotationView?.annotation as? Pin else {
            return
        }
        performSegueWithIdentifier("PhotoAlbumSegue", sender: pin)
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        saveMapRegion()
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {

        if newState == .Ending {
            if let pin = view.annotation as? Pin {
                retrieveNewPhotosForPin(pin)
            }
        }
    }

    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {

        views.forEach {
            $0.setSelected(true, animated: true)
        }
    }
}

extension TravelLocationViewController: PhotoAlbumViewControllerDelegate {

    func photoAlbum(photoAlbum: PhotoAlbumViewController, didUpdatePin pin: Pin?) {

        if let updatedPin = pin {
            refreshPinAsync(updatedPin)
        }
    }
}