//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

struct Constants {

    struct Flickr {
        
        static let BaseUrlSecure = "https://api.flickr.com/services/rest/"
        static let ApiKey = "API_KEY_HERE"


        struct Methods {
            static let PhotoSearch = "flickr.photos.search"
        }

        struct JSONBody {
            static let Method = "method"
            static let ApiKey = "api_key"
            static let BoundingBox = "bbox"
            static let SafeSearch = "safe_search"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJsonCallback = "nojsoncallback"
            static let Limit = "per_page"
            static let Sort = "sort"
        }

        struct JSONResponse {
            static let Photos = "photos"
            static let Status = "stat"
            static let Photo = "photo"
            static let Id = "id"
            static let Title = "title"
            static let Url = "url_m"
        }
    }

    struct Pin {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }

    struct MapRegion {

        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }

}