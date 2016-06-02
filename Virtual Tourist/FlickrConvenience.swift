//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import UIKit
import Foundation


extension FlickrClient {

    func getPublicPhotosWithBoundingBox(boundingBox: String, completionHandler: (photos: [[String: AnyObject]]?, errorString: String?) -> Void) {

        let params = [
            Constants.Flickr.JSONBody.Method: Constants.Flickr.Methods.PhotoSearch,
            Constants.Flickr.JSONBody.ApiKey: Constants.Flickr.ApiKey,
            Constants.Flickr.JSONBody.BoundingBox: boundingBox,
            Constants.Flickr.JSONBody.SafeSearch: "1",
            Constants.Flickr.JSONBody.Extras: "url_m",
            Constants.Flickr.JSONBody.Format: "json",
            Constants.Flickr.JSONBody.NoJsonCallback: "1",
            Constants.Flickr.JSONBody.Limit: "250",
            Constants.Flickr.JSONBody.Sort: "interestingness-desc"
        ]
        
        taskForGETMethod(params) { result, error in

            if let error = error {

                var errorString = error.localizedDescription

                if (error.errorType != ErrorType.Exception) {
                    
                    switch error.errorType {
                    case .NotFound:
                        errorString = "Data not found"
                    default:
                        errorString = "An unknown error has occurred"
                    }
                }
                print(errorString)

                completionHandler(photos: nil, errorString: errorString)
            } else {

                print(result)

                guard let stat = result[Constants.Flickr.JSONResponse.Status] as? String where stat == "ok" else {
                    completionHandler(photos: nil, errorString: "Flick API returned an error")
                    return
                }

                guard let photos = result[Constants.Flickr.JSONResponse.Photos] as? NSDictionary else {
                    completionHandler(photos: nil, errorString: "Could not find photos key in data")
                    return
                }

                guard let photoCollection = photos[Constants.Flickr.JSONResponse.Photo] as? [[String: AnyObject]] else {
                    completionHandler(photos: nil, errorString: "Could not find photo key in data")
                    return
                }
                
                let randomizedPhotos = self.pickRandom(photoCollection, withDesiredCount: self.randomizedResultCount)

                completionHandler(photos: randomizedPhotos, errorString: nil)
            }
        }
    }

    private func pickRandom<T>(var collection: [T], withDesiredCount desiredCount: Int) -> [T] {

        // make sure that the desired count does not exceed the real count
        let resultCount = min(collection.count, desiredCount)

        var randomizedCollection = [T]()
        
        for _ in 0 ..< resultCount {

            let randomIndex = Int(arc4random()) % collection.count
            randomizedCollection.append(collection[randomIndex])

            // remove current element from sample to ensure the element in the next loop is unique
            collection.removeAtIndex(randomIndex)
        }
        
        return randomizedCollection
    }

}