//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var title: String
    @NSManaged var url: String
    @NSManaged var pin: Pin?

    var fileName: String {

        return String(id)
    }

    var locationImage: UIImage? {

        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName)
        }
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: fileName)
        }
    }
    

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        id = Int(dictionary[Constants.Flickr.JSONResponse.Id] as! String)!
        title = dictionary[Constants.Flickr.JSONResponse.Title] as! String
        url = dictionary[Constants.Flickr.JSONResponse.Url] as! String
    }

    override func prepareForDeletion() {

        FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: fileName)
    }
}



