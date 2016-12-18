//
//  ViewController.swift
//  SpartaRide
//
//  Created by Brandon Bielicki on 12/13/16.
//  Copyright © 2016 Brandon Bielicki. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate {
    
    @IBOutlet weak var routeSelectButton: UIButton!
    @IBOutlet weak var stopsToggleButton: UIButton!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var routePickerView: UIPickerView!
    
    let routeNumbers = ["01","02","03","05","07","08","09","10","11","12","13","14","15","16","20","22","23","24","25","26","30","31","32","33","34","35","36","39","46","48"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    @IBAction func stopToggleButtonClick(_ sender: Any) {
        print("STOPS TOGGLE")
    }
    
    @IBAction func routeSelectButtonClick(_ sender: Any) {
        print("ROUTE SELECT")
        pickerContainerView.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return routeNumbers.count
    }
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return routeNumbers[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        routeSelectButton.setTitle(routeNumbers[row], for: .normal)
        pickerContainerView.isHidden = true
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = routeNumbers[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 35.0),NSForegroundColorAttributeName:UIColor.white])
        return myTitle
    }

}

