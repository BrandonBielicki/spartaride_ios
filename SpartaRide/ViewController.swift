//
//  ViewController.swift
//  SpartaRide
//
//  Created by Brandon Bielicki on 12/13/16.
//  Copyright © 2016 Brandon Bielicki. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var routeSelectButton: UIButton!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.camera(withLatitude: 42.7369792, longitude: -84.48386540000001, zoom: 15.0)
        //let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        //mapView.isMyLocationEnabled = true
        //view = mapView
        
        mapView.isMyLocationEnabled = true
        mapView.camera = camera
        
        routeSelectButton.layer.cornerRadius = 0.5 * routeSelectButton.bounds.size.width
        routeSelectButton.clipsToBounds = true
        view.addSubview(routeSelectButton)
        
    }
    
    @IBAction func routeSelectButtonClick(_ sender: Any) {
        print("CLICK")
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

