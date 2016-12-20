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

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    
    @IBOutlet weak var routeSelectButton: UIButton!
    @IBOutlet weak var stopsToggleButton: UIButton!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var routePickerView: UIPickerView!
    
    var currentBusMarkers = [GMSMarker]()
    
    let routeNumbers = ["#","01","02","03","05","07","08","09","10","11","12","13","14","15","16","20","22","23","24","25","26","30","31","32","33","34","35","36","39","46","48"]
    
    var fbTrips: FIRDatabaseReference!
    var fbStops: FIRDatabaseReference!
    var fbRoot: FIRDatabaseReference!
    var tripsHandle: FIRDatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fbTrips = FIRDatabase.database().reference(withPath: "trips")
        fbStops = FIRDatabase.database().reference(withPath: "stops")
        fbRoot = FIRDatabase.database().reference()
        tripsHandle = fbTrips.queryOrdered(byChild: "route").queryEqual(toValue: "#").observe(FIRDataEventType.value, with: { (snapshot) in
        })
        
        let camera = GMSCameraPosition.camera(withLatitude: 42.7369792, longitude: -84.48386540000001, zoom: 15.0)
        
        mapView.isMyLocationEnabled = true
        mapView.camera = camera
        
        routeSelectButton.layer.cornerRadius = 0.5 * routeSelectButton.bounds.size.width
        routeSelectButton.clipsToBounds = true
        
        stopsToggleButton.layer.cornerRadius = 0.5 * stopsToggleButton.bounds.size.width
        stopsToggleButton.clipsToBounds = true
        
        pickerContainerView.layer.cornerRadius = 0.5 * pickerContainerView.bounds.size.width
        pickerContainerView.clipsToBounds = true
        
        self.routePickerView.delegate = self
        self.routePickerView.dataSource = self
        pickerContainerView.isHidden = true
    }
    
    func clearMap() {
        for item in self.currentBusMarkers {
            item.map = nil
        }
    }
    
    func displayRoute(route: String){
        routeSelectButton.setTitle(route, for: .normal)
        fbTrips.removeObserver(withHandle: tripsHandle)
        print(route)
        
        
        
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
        displayRoute(route: routeNumbers[row])
        clearMap()
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

