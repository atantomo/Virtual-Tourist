//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/03.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import Foundation

internal enum ErrorType: Int {

    case Exception = 0
    case BadRequest
    case Forbidden
    case NotFound
    case Unknown
}

extension NSError {

    convenience init(domain: String, errorType: ErrorType, userInfo: [NSObject: AnyObject]?) {

        self.init(domain: domain, code: errorType.rawValue, userInfo: userInfo)
    }

    var errorType: ErrorType {
        return ErrorType(rawValue: code)!
    }
}

final class FlickrClient: NSObject {

    var session: NSURLSession

    let randomizedResultCount = 8


    override init() {
        
        session = NSURLSession.sharedSession()
        super.init()
    }

    class func sharedInstance() -> FlickrClient {

        struct Singleton {
            static var sharedInstance = FlickrClient()
        }

        return Singleton.sharedInstance
    }

    struct Caches {
        static let imageCache = ImageCache()
    }

    func taskForGETMethod(params: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {

        let urlString = Constants.Flickr.BaseUrlSecure + escapedParameters(params)
        let url = NSURL(string: urlString)!

        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"

        let task = session.dataTaskWithRequest(request) { data, response, error in

            self.handleRequestData(data, response: response, error: error, domain: "taskForGETMethod", completionHandler: completionHandler)
        }
        task.resume()
        
        return task
    }

    private func handleRequestData(data: NSData?, response: NSURLResponse?, error: NSError?, domain: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        guard error == nil else {
            print("Request returned an error: \(error)")
            let userInfo = [NSLocalizedDescriptionKey: "Connection could not be established"]
            completionHandler(result: nil, error: NSError(domain: domain, errorType: .Exception, userInfo: userInfo))
            return
        }

        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where
            statusCode >= 200 && statusCode <= 299 else {

                var err: ErrorType
                if let response = response as? NSHTTPURLResponse {
                    print("Request returned status code: \(response.statusCode)")

                    switch response.statusCode {
                    case 400:
                        err = .BadRequest
                    case 403:
                        err = .Forbidden
                    case 404:
                        err = .NotFound
                    default:
                        err = .Unknown
                    }
                } else {
                    print("Request returned invalid response: \(response)")
                    err = .Unknown
                }
                completionHandler(result: nil, error: NSError(domain: domain, errorType: err, userInfo: nil))
                return
        }

        guard let data = data else {

            let userInfo = [NSLocalizedDescriptionKey: "Request returned no data"]
            completionHandler(result: nil, error: NSError(domain: domain, errorType: .Exception, userInfo: userInfo))
            return
        }

        var parsedData = NSDictionary()
        do {
            parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Failed parsing JSON data"]
            completionHandler(result: nil, error: NSError(domain: domain, errorType: .Exception, userInfo: userInfo))
            return
        }

        completionHandler(result: parsedData, error: nil)
    }

    func taskForImageWithUrl(urlString: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {

        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }

        task.resume()

        return task
    }

    private func escapedParameters(parameters: [String: AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            urlVars += [key + "=" + "\(escapedValue!)"]

        }

        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}