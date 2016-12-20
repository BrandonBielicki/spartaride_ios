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

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,GMSMapViewDelegate {
    
    @IBOutlet weak var routeSelectButton: UIButton!
    @IBOutlet weak var stopsToggleButton: UIButton!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var routePickerView: UIPickerView!
    
    var currentBusMarkers = [GMSMarker]()
    var currentStopMarkers = [GMSMarker]()
    var route = ""
    
    let routeNumbers = ["#","01","02","03","05","07","08","09","10","11","12","13","14","15","16","20","22","23","24","25","26","30","31","32","33","34","35","36","39","46","48"]
    
    var fbTrips: FIRDatabaseReference!
    var fbStops: FIRDatabaseReference!
    var fbRoot: FIRDatabaseReference!
    var tripsHandle: FIRDatabaseHandle!
    var stopsHandle: FIRDatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fbTrips = FIRDatabase.database().reference(withPath: "trips")
        fbStops = FIRDatabase.database().reference(withPath: "stops")
        fbRoot = FIRDatabase.database().reference()
        tripsHandle = fbTrips.queryOrdered(byChild: "route").queryEqual(toValue: "#").observe(FIRDataEventType.value, with: { (snapshot) in
        })
        stopsHandle = fbStops.queryOrderedByKey().queryEqual(toValue: "#").observe(FIRDataEventType.value, with: { (snapshot) in
        })
        
        let camera = GMSCameraPosition.camera(withLatitude: 42.7369792, longitude: -84.48386540000001, zoom: 15.0)
        
        mapView.isMyLocationEnabled = true
        mapView.camera = camera
        mapView.settings.rotateGestures = false
        self.mapView.delegate = self
        
        self.routePickerView.delegate = self
        self.routePickerView.dataSource = self
        pickerContainerView.isHidden = true
        
        roundButtons()
    }
    
    func roundButtons() {
        routeSelectButton.layer.cornerRadius = 0.5 * routeSelectButton.bounds.size.width
        routeSelectButton.clipsToBounds = true
        
        stopsToggleButton.layer.cornerRadius = 0.5 * stopsToggleButton.bounds.size.width
        stopsToggleButton.clipsToBounds = true
        
        pickerContainerView.layer.cornerRadius = 0.5 * pickerContainerView.bounds.size.width
        pickerContainerView.clipsToBounds = true
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        if(marker.userData as! NSString == "bus") {
            return true
        }
        
        fbTrips.queryOrdered(byChild: "route").queryEqual(toValue: self.route).observeSingleEvent(of: .value, with: { (snapshot) in
            var stopTimes = [NSString]()
            if snapshot.exists() {
                for trip in snapshot.children {
                    let trip = trip as! FIRDataSnapshot
                    let stops = trip.childSnapshot(forPath: "stops")
                    for stopData in stops.children {
                        let stopData = stopData as! FIRDataSnapshot
                        if(stopData.childSnapshot(forPath: "stop_id").value as! NSString == marker.userData as! NSString) {
                            stopTimes.append(stopData.childSnapshot(forPath: "arrival").value as! NSString)
                        }
                    }
                    
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
            }
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
    
    func displayRoute(route: String){
        routeSelectButton.setTitle(route, for: .normal)
        fbTrips.removeObserver(withHandle: tripsHandle)
        
        stopsHandle = fbStops.queryOrderedByKey().queryEqual(toValue: route).observe(FIRDataEventType.value, with: { (snapshot) in
            if snapshot.exists() {
                for item in self.currentStopMarkers {
                    item.map = nil
                }
                
                for route in snapshot.children {
                    let y = route as! FIRDataSnapshot
                    for item in y.children {
                        let x = item as! FIRDataSnapshot
                        let latitude = (x.childSnapshot(forPath: "latitude").value)
                        let longitude = (x.childSnapshot(forPath: "longitude").value)
                        let code = (x.childSnapshot(forPath: "code").value)
                        
                        let marker = GMSMarker()
                        marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees((latitude as! NSString).floatValue), longitude: CLLocationDegrees((longitude as! NSString).floatValue))
                        marker.icon = UIImage(named: "marker_stop_green")
                        marker.title = "Arriving at:"
                        marker.snippet = "No Time Available"
                        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                        marker.userData = code as! NSString
                        marker.tracksInfoWindowChanges = true
                        marker.map = self.mapView
                        self.currentStopMarkers.append(marker)
                    }
                }
            }
        })
        
        tripsHandle = fbTrips.queryOrdered(byChild: "route").queryEqual(toValue: route).observe(FIRDataEventType.value, with: { (snapshot) in
            if snapshot.exists() {
                for item in self.currentBusMarkers {
                    item.map = nil
                }
                
                for item in snapshot.children {
                    let x = item as! FIRDataSnapshot
                    let bearing = (x.childSnapshot(forPath: "bearing").value as! NSString)
                    let latitude = (x.childSnapshot(forPath: "latitude").value)
                    let longitude = (x.childSnapshot(forPath: "longitude").value)
                    
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
        })
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

}

