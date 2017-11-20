//
//  FlickrPhoto.swift
//  Pixel City
//
//  Created by Jibran Syed on 10/17/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import UIKit

class FlickrPhoto 
{
    let id: String
    let secret: String
    let url: String
    var image: UIImage?
    var title: String?
    var user: String?
    var timeStamp: String?
    private(set) public var lat: Double
    private(set) public var lon: Double
    private(set) public var hasGeoTag: Bool
    
    
    init(newId: String, newSecret: String, newUrl: String) 
    {
        self.id = newId
        self.secret = newSecret
        self.url = newUrl
        
        self.lat = 0
        self.lon = 0
        self.hasGeoTag = false
    }
    
    func setGeoTag(latitude: Double, longitude: Double)
    {
        if self.hasGeoTag == false
        {
            self.hasGeoTag = true
            self.lat = latitude
            self.lon = longitude
        }
    }
}
