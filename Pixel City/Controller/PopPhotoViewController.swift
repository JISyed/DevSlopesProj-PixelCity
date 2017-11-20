//
//  PopPhotoViewController.swift
//  Pixel City
//
//  Created by Jibran Syed on 10/17/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import UIKit
import MapKit

class PopPhotoViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate
{
    @IBOutlet weak var imgPoppedPhoto: UIImageView!
    @IBOutlet weak var lblPhotoTitle: UILabel!
    @IBOutlet weak var lblFlickrUser: UILabel!
    @IBOutlet weak var lblPhotoDate: UILabel!
    @IBOutlet weak var mapViewPhotoLocation: MKMapView!
    
    
    var passedPhoto: FlickrPhoto!   // Will have a value
    var locationManager = CLLocationManager()
    
    
    let regionDiameterMeters: Double = 350
    
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //self.imgPoppedPhoto.image = self.passedImage
        self.imgPoppedPhoto.image = passedPhoto.image
        self.lblPhotoTitle.text = passedPhoto.title
        self.lblFlickrUser.text = passedPhoto.user
        self.lblPhotoDate.text = passedPhoto.timeStamp
        
        self.setupMiniMap()
        
        self.addDoubleTapGesture()
    }
    
    
    
    func initData(withPhoto photo: FlickrPhoto)
    {
        //self.passedImage = image
        self.passedPhoto = photo
    }
    
    
    
    func addDoubleTapGesture()
    {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PopPhotoViewController.onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    
    @objc
    func onDoubleTap()
    {
        dismiss(animated: true, completion: nil)
    }
    
    
    func setupMiniMap()
    {
        if self.passedPhoto.hasGeoTag
        {
            self.mapViewPhotoLocation.isHidden = false
            let coordinate = CLLocationCoordinate2DMake(self.passedPhoto.lat, self.passedPhoto.lon)
            
            // Create a pin at the coordinate and add it to the map
            for pin in self.mapViewPhotoLocation.annotations
            {
                self.mapViewPhotoLocation.removeAnnotation(pin)
            }
            let annotation = DroppablePin(coordinate: coordinate, identifier: MKA_DROP_PIN_REUSE_ID)
            self.mapViewPhotoLocation.addAnnotation(annotation)
            
            // Center the map view onto that coordinate
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, self.regionDiameterMeters, self.regionDiameterMeters)
            self.mapViewPhotoLocation.setRegion(coordinateRegion, animated: false)
            
        }
    }
    

    
    
}








