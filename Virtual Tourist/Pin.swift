//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//


import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]

    var coordinate: CLLocationCoordinate2D {

        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    var hasPhoto: Bool {

        return photos.count > 0
    }

    var shouldDrop = true // for drop animation

    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)

        latitude = dictionary[Constants.Pin.Latitude] as! Double
        longitude = dictionary[Constants.Pin.Longitude] as! Double
    }
}


