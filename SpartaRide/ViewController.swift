//
//  ViewController.swift
//  SpartaRide
//
//  Created by Brandon Bielicki on 12/13/16.
//  Copyright © 2016 Brandon Bielicki. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseDatabase
import GoogleMobileAds
import Foundation

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,GMSMapViewDelegate {
    
    var bannerView: GADBannerView!
    
    @IBOutlet weak var routeSelectButton: UIButton!
    @IBOutlet weak var stopsToggleButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    
    @IBOutlet weak var notificationMessage: UILabel!
    @IBOutlet weak var notificationTitle: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var notificationView: UIView!
    
    @IBOutlet weak var notificationOffButton: UIButton!
    
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var routePickerView: UIPickerView!
    
    var currentBusMarkers = [GMSMarker]()
    var currentStopMarkers = [GMSMarker]()
    var route = ""
    
    let routeNumbers = ["01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","20","22","23","24","25","26","30","31","32","33","34","35","36","39","46","48","261"]
    
    var fbTrips: FIRDatabaseReference!
    var fbBuses: FIRDatabaseReference!
    var fbRoot: FIRDatabaseReference!
    var fbNotifications: FIRDatabaseReference!
    var busesHandle: FIRDatabaseHandle!
    var stopsDict = Dictionary<String, Any>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationView.isHidden = true
        notificationOffButton.isHidden = true
        notificationButton.isHidden = true
        
        
        self.routePickerView.delegate = self
        self.routePickerView.dataSource = self
        pickerContainerView.isHidden = true
        
        
        configureFirebase()
        configureMap()
        roundButtons()
        
        initNotifications()
        initStops()
        
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        addBannerViewToView(bannerView)
        bannerView.adUnitID = "ca-app-pub-7940513604745520/4309034775"
        //bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    func initStops() {
        do {
            if let file = Bundle.main.url(forResource: "stops", withExtension: "json") {
                let data = try? String(contentsOf: file, encoding: .utf8)
                
                stopsDict = convertToDictionary(text: data!)!
            }
        }
    }
    
    func initNotifications() {
        fbNotifications.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            for notification in snapshot.children {
                let notification = notification as! FIRDataSnapshot
                self.notificationTitle.text = notification.childSnapshot(forPath: "Title").value as! String?
                self.notificationMessage.text = notification.childSnapshot(forPath: "Message").value as! String?
                let active_notification = notification.childSnapshot(forPath: "Active").value as! String?
            
                if(active_notification == "True") {
                    self.notificationButton.isHidden = false
                }
            }
        })
        
    }
    
    func configureFirebase() {
        fbNotifications = FIRDatabase.database().reference(withPath: "notifications")
        fbBuses = FIRDatabase.database().reference(withPath: "buses")
        fbTrips = FIRDatabase.database().reference(withPath: "trips")
        fbRoot = FIRDatabase.database().reference()
        busesHandle = fbBuses.queryOrderedByKey().queryEqual(toValue: "00").observe(FIRDataEventType.childChanged, with: { (snapshot) in
        })
    }
    
    func configureMap() {
        let camera = GMSCameraPosition.camera(withLatitude: 42.7369792, longitude: -84.48386540000001, zoom: 15.0)
        
        mapView.isMyLocationEnabled = true
        mapView.camera = camera
        mapView.settings.rotateGestures = false
        mapView.settings.myLocationButton = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        self.mapView.delegate = self
    }
    
    func roundButtons() {
        notificationView.layer.cornerRadius = 25
        notificationView.layer.borderColor = UIColor.black.cgColor
        notificationView.layer.borderWidth = 1
        
        notificationView.clipsToBounds = true
        
        notificationButton.layer.cornerRadius = 0.5 * notificationButton.bounds.size.width
        notificationButton.clipsToBounds = true
        
        routeSelectButton.layer.cornerRadius = 0.5 * routeSelectButton.bounds.size.width
        routeSelectButton.clipsToBounds = true
        
        stopsToggleButton.layer.cornerRadius = 0.5 * stopsToggleButton.bounds.size.width
        stopsToggleButton.clipsToBounds = true
        stopsToggleButton.isHidden = true
        
        pickerContainerView.layer.cornerRadius = 0.5 * pickerContainerView.bounds.size.width
        pickerContainerView.clipsToBounds = true
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func displayBusStops(route: String) {
        for item in self.currentStopMarkers {
            item.map = nil
        }
        
        if let route = stopsDict[route] as? [String: Any] {
            for (id, values) in route {
                let id_values = values as! [String:String]
                let stop_latitude = id_values["latitude"]
                let stop_longitude = id_values["longitude"]
                let stop_id = id
                
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(Double(stop_latitude!)!), longitude: CLLocationDegrees(Double(stop_longitude!)!))
                marker.icon = UIImage(named: "marker_stop_green")
                marker.title = "Arriving at stop #" + (stop_id) + " at:"
                marker.snippet = "No Time Available"
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                marker.userData = stop_id
                marker.tracksInfoWindowChanges = true
                marker.map = self.mapView
                self.currentStopMarkers.append(marker)
            }
        }
    }
    
    func stopClickEvent(snapshot: FIRDataSnapshot, marker: GMSMarker) {
        var stopTimes = [NSString]()

    
        for trip in snapshot.childSnapshot(forPath: marker.userData as! String).children {
            let arrival = ((trip as AnyObject).childSnapshot(forPath: "arrival").value)
            stopTimes.append(arrival as! String as NSString)
        }
        
        
        let sortedStopTimes = stopTimes.sorted { $0.localizedCaseInsensitiveCompare($1 as String) == ComparisonResult.orderedAscending }
        
        let currentDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        let currentTime = dateFormatter.string(from: currentDate as Date)
        if(sortedStopTimes.count > 0) {
            marker.snippet = sortedStopTimes[0] as String
            if(sortedStopTimes.count > 1 && currentTime.compare(sortedStopTimes[0] as String) == ComparisonResult.orderedDescending) {
                marker.snippet = sortedStopTimes[1] as String
            }
        }
        marker.infoWindowAnchor = CGPoint(x: 0.5, y: 0.5)
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        if(marker.userData as! NSString == "bus") {
            return true
        }
        fbTrips.child(route).queryOrderedByKey().queryEqual(toValue: marker.userData).observeSingleEvent(of: .value, with: { (snapshot) in
            self.stopClickEvent(snapshot: snapshot, marker: marker)
        })
        
        return false
    }
    
    func clearMap() {
        for item in self.currentBusMarkers {
            item.map = nil
        }
        for item in self.currentStopMarkers {
            item.map = nil
        }
        
        self.currentBusMarkers = [GMSMarker]()
        self.currentStopMarkers = [GMSMarker]()
    }
    
    func busUpdateEvent(snapshot: FIRDataSnapshot) {
        for item in self.currentBusMarkers {
            item.map = nil
        }
        for bus in snapshot.children {
            let bus = bus as! FIRDataSnapshot
            let bearing = (bus.childSnapshot(forPath: "bearing").value as! NSString)
            let latitude = (bus.childSnapshot(forPath: "latitude").value)
            let longitude = (bus.childSnapshot(forPath: "longitude").value)
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees((latitude as! NSString).floatValue), longitude: CLLocationDegrees((longitude as! NSString).floatValue))
            marker.userData = "bus"
            
            switch bearing {
            case "0":
                marker.icon = UIImage(named: "marker_bus_green_0")
            case "45.0":
                marker.icon = UIImage(named: "marker_bus_green_45")
            case "90.0":
                marker.icon = UIImage(named: "marker_bus_green_90")
            case "135.0":
                marker.icon = UIImage(named: "marker_bus_green_135")
            case "180.0":
                marker.icon = UIImage(named: "marker_bus_green_180")
            case "225.0":
                marker.icon = UIImage(named: "marker_bus_green_225")
            case "270.0":
                marker.icon = UIImage(named: "marker_bus_green_270")
            case "315.0":
                marker.icon = UIImage(named: "marker_bus_green_315")
            default:
                marker.icon = UIImage(named: "marker_bus_green_0")
            }
            marker.map = self.mapView
            self.currentBusMarkers.append(marker)
        }
    }
    
    func displayRoute(route: String){
        routeSelectButton.setTitle(route, for: .normal)
        fbBuses.removeObserver(withHandle: busesHandle)
        
        self.displayBusStops(route: route)
        
        fbBuses.queryOrderedByKey().queryEqual(toValue: route).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            self.busUpdateEvent(snapshot: snapshot.childSnapshot(forPath: route))
        })
        
        busesHandle = fbBuses.queryOrderedByKey().queryEqual(toValue: route).observe(FIRDataEventType.childChanged, with: { (snapshot) in
            self.busUpdateEvent(snapshot: snapshot)
        })
    }
    
    @IBAction func notificationOffButtonClick(_ sender: Any) {
        notificationView.isHidden = true
        notificationOffButton.isHidden = true
    }
    @IBAction func notificationButtonClick(_ sender: Any) {
        if(notificationView.isHidden) {
            notificationView.isHidden = false
        } else {
            notificationView.isHidden = true
        }
        notificationOffButton.isHidden = false
    }
    
    @IBAction func stopToggleButtonClick(_ sender: Any) {
        if(currentStopMarkers.count > 0) {
            if(currentStopMarkers[0].map == nil) {
                for item in currentStopMarkers {
                    item.map = mapView
                }
            }
            else {
                for item in currentStopMarkers {
                    item.map = nil
                }
            }
        }
    }
    
    @IBAction func routeSelectButtonClick(_ sender: Any) {
        pickerContainerView.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return routeNumbers.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return routeNumbers[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        clearMap()
        displayRoute(route: routeNumbers[row])
        self.route = routeNumbers[row]
        pickerContainerView.isHidden = true
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.text = routeNumbers[row]
        pickerLabel.font = UIFont.boldSystemFont(ofSize: 35.0)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .bottom,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
        view.addConstraints(
            [NSLayoutConstraint(item: pickerContainerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bannerView,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0)
            ])
        view.addConstraints(
            [NSLayoutConstraint(item: notificationButton,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bannerView,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0)
            ])

    }

}

