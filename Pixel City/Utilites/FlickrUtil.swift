//
//  FlickrUtil.swift
//  Pixel City
//
//  Created by Jibran Syed on 10/17/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import Foundation


// Flickr API Key
let API_KEY_FLICKR = "a7ab261b1c06eb13fcdc5e14ab20462f"



// Flicker API Helper Functions

func getFlickrSearchUrl(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String
{
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}


func getFlickrPhotoInfoUrl(forApiKey key: String, withPhoto photo: FlickrPhoto) -> String
{
    return "https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=\(key)&photo_id=\(photo.id)&secret=\(photo.secret)&format=json&nojsoncallback=1"
}


func convertTimeStampToReadableDate(fromString dateString: String, withFormatter formatter: DateFormatter) -> String
{
    // Flickr Time format:
    // "2017-03-21 20:22:54"
    // ISO 8610 format:
    // "2017-03-21T20:22:54Z"
    var isoString = dateString.replacingOccurrences(of: " ", with: "T")
    isoString.append("Z")
    
    
    
    let isoFormatter = ISO8601DateFormatter()
    let isoDateOpt = isoFormatter.date(from: isoString)
    
    if let isoDate = isoDateOpt
    {
        let americanDate = formatter.string(from: isoDate)
        return americanDate
    }
    
    return "<<Invalid Time Stamp Format>>"
}


