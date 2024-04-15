//
//  LocationManager.swift
//  PrayerTimes
//
//  Created by Admin on 24/03/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentLocationName: String?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location

        // Reverse geocode to get location name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            if let locality = placemark.locality {
                self.currentLocationName = locality
                print("Current Location Name: \(locality)")
            }
        }
    }
}

// Usage
let locationManager = LocationManager()
