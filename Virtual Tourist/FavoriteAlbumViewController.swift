//
//  FavoriteAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/11.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import UIKit
import CoreData

class FavoriteAlbumViewController: UIViewController {

    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var emptyPlaceholderView: UIView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    var updates: (() -> ()) = {}
    var shouldReloadCollectionView = false

    var sharedContext: NSManagedObjectContext {

        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Favorite")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

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

        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("Error in retrieving favorites: \(error)")
        }
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self

        setupViewInsets()
        recalculateItemDimension()
        toggleEmptyPlaceholder()
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    private func configureCell(cell: PhotoCollectionViewCell, withFavorite favorite: Favorite) {

        if let localImage = favorite.locationImage {
            cell.photoImageView.image = localImage

        } else {

            let placeholderView = PlaceholderView(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
            cell.addSubview(placeholderView)

            FlickrClient.sharedInstance().taskForImageWithUrl(favorite.url) { imageData, error in

                self.removeViewAsync(placeholderView)
                if let data = imageData {

                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        favorite.locationImage = image
                        cell.photoImageView.image = image
                    }
                }
            }
        }
    }

    private func toggleEmptyPlaceholder() {

        if(fetchedResultsController.fetchedObjects?.count == 0) {
            emptyPlaceholderView.hidden = false
        } else {
            emptyPlaceholderView.hidden = true
        }
    }
}

extension FavoriteAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return fetchedResultsController.sections![section].numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let favorite = fetchedResultsController.objectAtIndexPath(indexPath) as! Favorite

        let collectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("FavoriteCollectionCell", forIndexPath: indexPath) as! PhotoCollectionViewCell

        configureCell(collectionCell, withFavorite: favorite)
        
        return collectionCell
    }


}