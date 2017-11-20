//
//  ViewController.swift
//  Pixel City
//
//  Created by Jibran Syed on 10/15/17.
//  Copyright © 2017 Jishenaz. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapViewController: UIViewController, UIGestureRecognizerDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var viewPhotosPullUp: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    
    let clAuthorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadiusInMeters: Double = 1000
    var locationManager = CLLocationManager()
    
    var spinner: UIActivityIndicatorView?
    var lblProgress: UILabel?
    var collectionViewPhotos: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()   // Needed to make a collection view programatically
    
    var images = [FlickrPhoto]()
    
    var screenSize = UIScreen.main.bounds
    
    let readableFormatter = DateFormatter()
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.mapView.delegate = self
        self.locationManager.delegate = self
        
        configureLocationServices()
        
        self.addDoubleTapGesture()
        
        
        readableFormatter.dateFormat = "MMM d, YYYY @ h:mm a"
        
        
        // Create collection view for the photos pull up
        collectionViewPhotos = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionViewPhotos?.register(PhotoCell.self, forCellWithReuseIdentifier: REUSE_ID_PHOTO_CELL)
        collectionViewPhotos?.delegate = self
        collectionViewPhotos?.dataSource = self
        collectionViewPhotos?.backgroundColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        self.viewPhotosPullUp.addSubview(collectionViewPhotos!)
        
        
        
        // 3d Touch registration
        registerForPreviewing(with: self, sourceView: self.collectionViewPhotos!)
        
    }
    
    
    
    func addDoubleTapGesture()
    {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(sender:)) )
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        self.mapView.addGestureRecognizer(doubleTap)
    }
    
    
    func addSwipeDown()
    {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MapViewController.animateViewDown))
        swipe.direction = .down
        self.viewPhotosPullUp.addGestureRecognizer(swipe)
    }
    
    
    func animateViewUp()
    {
        self.pullUpViewHeightConstraint.constant = 300 // Mod the constraint by 300 pts
        UIView.animate(withDuration: 0.3) {
            
            self.view.layoutIfNeeded()  // Redraw changes
        }
        
    }
    
    
    @objc
    func animateViewDown()
    {
        // Stop downloading photos
        cancelAllSession()
        
        self.pullUpViewHeightConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()  // Redraw changes
        }
    }
    
    
    func addSpinner()
    {
        self.spinner = UIActivityIndicatorView()
        self.spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        self.spinner?.activityIndicatorViewStyle = .whiteLarge
        self.spinner?.color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.spinner?.startAnimating()
        self.collectionViewPhotos?.addSubview(self.spinner!)
    }
    
    
    func removeSpinner()
    {
        if spinner != nil
        {
            spinner?.stopAnimating()
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel()
    {
        self.lblProgress = UILabel()
        let labelWidth : CGFloat = 240
        self.lblProgress?.frame = CGRect(x: (screenSize.width / 2) - (labelWidth / 2), y: 175, width: labelWidth, height: 40)
        self.lblProgress?.font = UIFont(name: "Avenir Next - Demi Bold", size: 14)
        self.lblProgress?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.lblProgress?.textAlignment = .center
        self.collectionViewPhotos?.addSubview(self.lblProgress!)
    }
    
    func removeProgressLabel()
    {
        if lblProgress != nil
        {
            lblProgress?.removeFromSuperview()
        }
    }
    
    
    @IBAction func onCenterMapBtnPressed(_ sender: Any) 
    {
        if self.clAuthorizationStatus == .authorizedAlways || self.clAuthorizationStatus == .authorizedWhenInUse
        {
            centerMapOnUserLocation()
        }
    }
    
    
}





extension MapViewController: MKMapViewDelegate
{
    // Customize the map pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? 
    {
        // Don't modify the pin representing the user's location
        if annotation is MKUserLocation
        {
            return nil
        }
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: MKA_DROP_PIN_REUSE_ID)
        pin.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pin.animatesDrop = true
        return pin
    }
    
    
    
    
    func centerMapOnUserLocation()
    {
        guard let coordinatee = locationManager.location?.coordinate else {return}
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinatee, regionRadiusInMeters * 2.0, regionRadiusInMeters * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    
    
    @objc
    func dropPin(sender: UITapGestureRecognizer)
    {
        // Clear previous pins
        removeEveryPin()
        removeSpinner()
        removeProgressLabel()
        cancelAllSession()      // Stop downloading photos
        
        // Clear existing photos
        images = []
        collectionViewPhotos?.reloadData()
        
        // Open the photos pull up
        animateViewUp()
        addSwipeDown()  // Add gesture to swipe down
        
        // Add subviews for the pullup
        addSpinner()
        addProgressLabel()
        
        // Convert tap screen coordinate to map's GPS coordinates
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        // Create a pin at the coordinate and add it to the map
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: MKA_DROP_PIN_REUSE_ID)
        mapView.addAnnotation(annotation)
        
        // Center the map view onto that coordinate
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadiusInMeters * 2.0, regionRadiusInMeters * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        self.retrieveUrls(forAnnotation: annotation) { (success) in
            if success
            {
                self.retrieveMetadata(handler: { (success) in
                    if success
                    {
                        self.retrieveImages(handler: { (success) in
                            if success
                            {
                                // Hide spinner, hide label, reload collection view
                                self.removeSpinner()
                                self.removeProgressLabel()
                                self.collectionViewPhotos?.reloadData()
                            }
                        })
                    }
                })
                
            }
        }
    }
    
    
    
    
    func removeEveryPin()
    {
        for annomation in mapView.annotations
        {
            mapView.removeAnnotation(annomation)
        }
    }
    
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping CompletionHandler)
    {
        self.lblProgress?.text = "SEARCHING FOR PHOTOS..."
        
        Alamofire.request(getFlickrSearchUrl(forApiKey: API_KEY_FLICKR, withAnnotation: annotation, andNumberOfPhotos: NUM_OF_PHOTOS)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, Any> else {
                debugPrint(response.result.error as Any)
                handler(false) 
                return
            }
            
            let photoCollection = json["photos"] as! Dictionary<String, Any>
            let photos = photoCollection["photo"] as! [Dictionary<String, Any>]
            
            // Go through every photo that was returned from the Flickr API
            for photo in photos
            {
                let farmNum = photo["farm"]!
                let serverNum = photo["server"]!
                let uniqueId = photo["id"]!
                let secret = photo["secret"]!
                // Construct the Flickr photo download URL
                let photoUrl = "https://farm\(farmNum).staticflickr.com/\(serverNum)/\(uniqueId)_\(secret)_h_d.jpg"
                
                // Create a new Flickr Photo
                let photoId = uniqueId as? String ?? ""
                let photoSecret = secret as? String ?? ""
                let photo = FlickrPhoto(newId: photoId, newSecret: photoSecret, newUrl: photoUrl)
                
                // Store it in an array to retrieve later
                self.images.append(photo)
            }
            
            handler(true)
        }
    }
    
    
    func retrieveImages(handler: @escaping CompletionHandler)
    {
        var tally = 0
        
        
        for photo in self.images
        {
            // Using AlamofireImage to download a photo into a UIImage
            Alamofire.request(photo.url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {
                    debugPrint(response.result.error as Any)
                    return
                }
                
                // Somehow magically casts Image to UIImage
                photo.image = image
                
                tally += 1
                self.lblProgress?.text = "\(tally)/\(NUM_OF_PHOTOS) IMAGES DOWNLOADED"
                
                
                if self.images.count == tally
                {
                    handler(true)
                }
                else
                {
                    handler(false)
                }
            })
        }
        
    }
    
    
    
    func retrieveMetadata(handler: @escaping CompletionHandler)
    {
        self.lblProgress?.text = "DOWNLOADING METADATA..."
        
        var tally = 0
        
        for photo in self.images
        {
            Alamofire.request(getFlickrPhotoInfoUrl(forApiKey: API_KEY_FLICKR, withPhoto: photo)).responseJSON(completionHandler: { (response) in
                guard let json = response.result.value as? Dictionary<String, Any> else {
                    debugPrint(response.result.error as Any)
                    handler(false) 
                    return
                }
                
                let photoMetaData = json["photo"] as! Dictionary<String, Any>
                
                let titleDict = photoMetaData["title"] as! Dictionary<String, Any>
                var title = titleDict["_content"] as? String ?? "Untitled Photo"
                if title.isEmpty || title == ""
                {
                    title = "Untitled Photo"
                }
                photo.title = title
                
                let ownerDict = photoMetaData["owner"] as! Dictionary<String, Any>
                var username = ownerDict["username"] as? String ?? "<<Flickr Username Not Found>>"
                if username.isEmpty || username == ""
                {
                    username = "Untitled Photo"
                }
                photo.user = username
                
                let datesDict = photoMetaData["dates"] as! Dictionary<String, Any>
                let flickrDate = datesDict["taken"] as? String ?? "<<Invalid Time Stamp Format>>"
                let photoDate = convertTimeStampToReadableDate(fromString: flickrDate, withFormatter: self.readableFormatter)
                photo.timeStamp = photoDate
                
                let locationDict = photoMetaData["location"] as! Dictionary<String, Any>
                let latOpt = locationDict["latitude"]
                let lonOpt = locationDict["longitude"]
                if let latStr = latOpt as? String, let lat = Double(latStr)
                {
                    if let lonStr = lonOpt as? String, let lon = Double(lonStr)
                    {
                        //print("(Lat,Long): (\(lat)),(\(lon))")
                        photo.setGeoTag(latitude: lat, longitude: lon)
                    }
                }
                
                tally += 1
                
                if self.images.count == tally
                {
                    handler(true)
                }
                else
                {
                    handler(false)
                }
            })
        }
    }
    
    
    
    func cancelAllSession()
    {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach( { $0.cancel() } )
            downloadData.forEach( { $0.cancel() } )
            // Stop downloading
        }
    }
    
    
}




extension MapViewController: CLLocationManagerDelegate
{
    func configureLocationServices()
    {
        if self.clAuthorizationStatus == .notDetermined
        {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) 
    {
        centerMapOnUserLocation()
    }
    
    
    
}



extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int 
    {
        // Number of items in an array
        return images.count//imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell 
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: REUSE_ID_PHOTO_CELL, for: indexPath) as? PhotoCell else {return UICollectionViewCell()}
        
        let imageFromIndex = images[indexPath.row].image //imageArray[indexPath.row]
        
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int 
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) 
    {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: STYBRD_ID_POP_VC) as? PopPhotoViewController else {return}
        
        popVC.initData(withPhoto: images[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}





// 3D Touch Stuff
extension MapViewController: UIViewControllerPreviewingDelegate
{
    
    
    // Pop
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? 
    {
        guard let indexPath = collectionViewPhotos?.indexPathForItem(at: location), let cell = collectionViewPhotos?.cellForItem(at: indexPath) else { return nil }
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: STYBRD_ID_POP_VC) as? PopPhotoViewController else {return nil}
        
        popVC.initData(withPhoto: images[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    // Peek
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) 
    {
        // viewControllerToCommit is already set in the function above ^
        show(viewControllerToCommit, sender: self)
    }
    
    
}



