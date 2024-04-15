//
//  QiblaViewController.swift
//  PrayerTimes
//
//  Created by Admin on 31/03/24.
//

import UIKit
import CoreLocation

class QiblaViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var compassImageView: UIImageView!
    
    let locationDelegate = LocationDelegate()
    var latestLocation: CLLocation? = nil
    var yourLocationBearing: CGFloat { return latestLocation?.bearingToLocationRadian(CLLocation(latitude: 0, longitude: 0)) ?? 0 }
    var yourLocation: CLLocation?
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Qibla"
        
        locationManager.delegate = locationDelegate
        var qiblaAngle : CGFloat = 0.0
        
        locationDelegate.errorCallback = { error in
            self.compassImageView.isHidden = true
            print(error)
        }
        
        locationDelegate.locationCallback = { location in
            self.latestLocation = location
            
            let phiK = 21.4*CGFloat.pi/180.0
            let lambdaK = 39.8*CGFloat.pi/180.0
            let phi = CGFloat(location.coordinate.latitude) * CGFloat.pi/180.0
            let lambda =  CGFloat(location.coordinate.longitude) * CGFloat.pi/180.0
            qiblaAngle = 180.0/CGFloat.pi * atan2(sin(lambdaK-lambda),cos(phi)*tan(phiK)-sin(phi)*cos(lambdaK-lambda))
            
            self.compassImageView.isHidden = false
        }
        
        locationDelegate.headingCallback = { newHeading in
            
            func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
                let heading = self.yourLocationBearing - newAngle.degreesToRadians
                return CGFloat(heading)
            }
            
            UIView.animate(withDuration: 0.5) {
                let angle = (CGFloat.pi/180 * -(CGFloat(newHeading) - qiblaAngle))
                self.compassImageView.transform = CGAffineTransform(rotationAngle: angle)
            }
        }
    }
}

public extension CLLocation {
  func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
    
    let lat1 = self.coordinate.latitude.degreesToRadians
    let lon1 = self.coordinate.longitude.degreesToRadians
    
    let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
    let lon2 = destinationLocation.coordinate.longitude.degreesToRadians
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    
    return CGFloat(radiansBearing)
  }
  
  func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
    return bearingToLocationRadian(destinationLocation).radiansToDegrees
  }
}

extension CGFloat {
  var degreesToRadians: CGFloat { return self * .pi / 180 }
  var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

private extension Double {
  var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
  var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
}

class LocationDelegate: NSObject, CLLocationManagerDelegate {
  var locationCallback: ((CLLocation) -> ())? = nil
  var headingCallback: ((CLLocationDirection) -> ())? = nil
  var errorCallback: ((String) -> ())? = nil
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let currentLocation = locations.last else { return }
    locationCallback?(currentLocation)
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    headingCallback?(newHeading.trueHeading)
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("⚠️ Error while updating location " + error.localizedDescription)
    errorCallback?("⚠️ Please enable Location!")
  }
}
