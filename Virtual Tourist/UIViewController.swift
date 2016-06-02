//
//  UIViewController.swift
//  On The Map
//
//  Created by Andrew Tantomo on 2016/02/16.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import Foundation
import MapKit

extension UIViewController {
    
    func displayErrorAsync(errorString: String?) {
        
        dispatch_async(dispatch_get_main_queue(), {
            let alertCtrl = UIAlertController(title: "Error", message: errorString, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertCtrl.addAction(okAction)
            self.presentViewController(alertCtrl, animated: true, completion: nil)
        })
    }

    func removeViewAsync(view: UIView) {
        
        dispatch_async(dispatch_get_main_queue(), {
            view.removeFromSuperview()
        })
    }

    func createBoundingBoxStringFromAnnotation(annotation: MKAnnotation) -> String {

        let boundingBoxHalfWidth = 0.5
        let latMin = -90.0
        let latMax = 90.0
        let lonMin = -180.0
        let lonMax = 180.0

        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude

        let bottomLeftLon = max(longitude - boundingBoxHalfWidth, lonMin)
        let bottomLeftLat = max(latitude - boundingBoxHalfWidth, latMin)
        let topRightLon = min(longitude + boundingBoxHalfWidth, lonMax)
        let topRightLat = min(latitude + boundingBoxHalfWidth, latMax)

        return "\(bottomLeftLon),\(bottomLeftLat),\(topRightLon),\(topRightLat)"
    }
}