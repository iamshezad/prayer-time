//
//  HomeViewController.swift
//  PrayerTimes
//
//  Created by Admin on 23/03/24.
//

import UIKit
import Foundation
import CoreLocation

class HomeViewController: UIViewController {
    
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var locationSubtitleLabel: UILabel!
    
    @IBOutlet weak var fajrTimeLabel: UILabel!
    @IBOutlet weak var duhurTimeLabel: UILabel!
    @IBOutlet weak var asrTimeLabel: UILabel!
    @IBOutlet weak var maghribTimeLabel: UILabel!
    @IBOutlet weak var ishaTimeLabel: UILabel!
    @IBOutlet weak var sunriseTimeLabel: UILabel!
    @IBOutlet weak var sunsetTimeLabel: UILabel!
    
    @IBOutlet weak var nextPrayerTimeLabel: UILabel!
    @IBOutlet weak var nextPrayerTimeZoneLabel: UILabel!
    @IBOutlet weak var nextPrayerNameLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var prayerLocation: String = ""
    var prayerSubLocation: String = ""
    
    var timings: Timings?
    var date: DateInfo?
    
    let notificationManager = LocalNotificationManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initialize location manager methods
        initilazeLocationManager()
        
        //Enable local notification
        registerNotification()
        
        notificationManager.getAllScheduledNotifications()
        
        BackgroundTaskManager.shared.checkScheduledRefreshTask { tasks in
            print("Refresh Task")
            print(tasks)
            print("----")
            if tasks.isEmpty{
                BackgroundTaskManager.shared.scheduleNextBackgroundTask()
            }
        }
        
        BackgroundTaskManager.shared.checkScheduledDailyTask { tasks in
            print("Daily Task")
            print(tasks)
            print("----")
            if tasks.isEmpty{
                BackgroundTaskManager.shared.scheduleDailyBackgroundTask()
            }
        }
        
        if let refreshValue = UserDefaults.standard.object(forKey: "refreshValue") as? Int {
            print("refreshValue")
            print(refreshValue)
            print("----")
        }else{
            print("No refreshValue")
        }
        
        if let dailyValue = UserDefaults.standard.object(forKey: "dailyValue") as? Int {
            print("dailyValue")
            print(dailyValue)
            print("----")
        }else{
            print("No dailyValue")
        }
    }
    
    func registerNotification(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if !granted {
                print("Permission not granted for notifications")
            }
        }
    }
    
    func setNavigationBar(title: String, subtitle: String){
        // Create a stack view to hold the main title and subtitle
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4 // Adjust as needed
        
        // Create the main title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18) // Adjust font size as needed
        titleLabel.textAlignment = .center
        
        // Create the subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = UIColor.gray
        
        // Add labels to the stack view
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        // Set the stack view as the title view of the navigation item
        self.navigationItem.titleView = stackView
    }
    
    func initilazeLocationManager(){
        
        if let locality = UserDefaults.standard.string(forKey: "prayerLocation"),
           let subLocality = UserDefaults.standard.string(forKey: "prayerSubLocation"),
           let prayerTimings = fetchPrayerTimings(),
           checkPrayerMonth(){
            self.locationTitleLabel.text = locality
            self.locationSubtitleLabel.text = subLocality
            self.getPrayerTime(prayerTimings: prayerTimings)
        }else{
            locationManager.delegate = self // Set delegate to receive location updates
            locationManager.requestWhenInUseAuthorization() // Request location authorization
            locationManager.startUpdatingLocation() // Start receiving location updates
        }
    }
    
    func checkPrayerMonth() -> Bool{
        let (_, currentMonth) = getCurrentMonthAndYear()
        
        if let prayerMonth = UserDefaults.standard.value(forKey: "prayerMonth") as? Int{
            return prayerMonth == currentMonth
        }
        
        return false
    }
    
    func getCurrentMonthAndYear() -> (Int, Int) {
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        
        if let year = components.year, let month = components.month {
            return (year, month)
        } else {
            // Handle error or default values
            return (0, 0)
        }
    }
    
    func fetchDataFromAPI(currentLocation: CLLocation) {
        
        let (currentYear, currentMonth) = getCurrentMonthAndYear()
        
        // Define the API endpoint URL
        let apiUrlString = "https://api.aladhan.com/v1/calendar/\(currentYear)/\(currentMonth)?latitude=\(currentLocation.coordinate.latitude)&longitude=\(currentLocation.coordinate.longitude)&method=2"
        
        // Create a URL object from the endpoint string
        if let apiUrl = URL(string: apiUrlString) {
            // Create a URLSession object
            let session = URLSession.shared
            
            // Create a data task to perform the request
            let task = session.dataTask(with: apiUrl) { data, response, error in
                // Check for errors
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                // Check if data was received
                guard let responseData = data else {
                    print("No data received")
                    return
                }
                
                do {
                    UserDefaults.standard.set(currentMonth, forKey: "prayerMonth")
                    UserDefaults.standard.set(self.prayerLocation, forKey: "prayerLocation")
                    UserDefaults.standard.set(self.prayerSubLocation, forKey: "prayerSubLocation")
                    
                    // Decode the JSON data into your Codable structs
                    let decoder = JSONDecoder()
                    let prayerTimingsResponse = try decoder.decode(PrayerTimingsResponse.self, from: responseData)
                    
                    self.storePrayerTimings(prayerTimingsResponse)
                    self.getPrayerTime(prayerTimings: prayerTimingsResponse,setNotification: true)
                    
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            // Start the data task
            task.resume()
        } else {
            print("Invalid URL")
        }
    }
    
    
    // Function to store prayer timings data to UserDefaults
    func storePrayerTimings(_ prayerTimings: PrayerTimingsResponse) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(prayerTimings)
            UserDefaults.standard.set(encodedData, forKey: "prayerTimings")
        } catch {
            print("Error encoding prayer timings data: \(error)")
        }
    }
    
    // Function to fetch prayer timings data from UserDefaults
    func fetchPrayerTimings() -> PrayerTimingsResponse? {
        if let storedData = UserDefaults.standard.data(forKey: "prayerTimings") {
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(PrayerTimingsResponse.self, from: storedData)
                return decodedData
            } catch {
                print("Error decoding stored data: \(error)")
            }
        }
        return nil
    }
    
    func getPrayerTime(prayerTimings: PrayerTimingsResponse, setNotification: Bool = false){
        // Get today's date
        let currentDate = Date()
        
        print("i'm here -------------")
        
        // Formatter for comparing date strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        // Filter the data array to find the object matching today's date
        if let todayTimings = prayerTimings.data.first(where: { data in
            if let date = dateFormatter.date(from: data.date.readable) {
                return Calendar.current.isDate(date, inSameDayAs: currentDate)
            }
            return false
        }) {
            timings = todayTimings.timings
            date = todayTimings.date
            
            print("here -------------")
            
            if(setNotification){
                notificationManager.scheduleLocalNotifications(for: todayTimings)
                
                BackgroundTaskManager.shared.checkScheduledRefreshTask { tasks in
                    if tasks.isEmpty{
                        BackgroundTaskManager.shared.scheduleNextBackgroundTask()
                    }
                }
                
                BackgroundTaskManager.shared.checkScheduledDailyTask { tasks in
                    if tasks.isEmpty{
                        BackgroundTaskManager.shared.scheduleDailyBackgroundTask()
                    }
                }
            }
            
            //Set all data to display
            setData()
        } else {
            print("No timings found for today")
        }
    }
    
    func setData(){
        guard let timeData = timings, let dateData = date else { return }
        let hijri = dateData.hijri
        
        DispatchQueue.main.async {
            self.setNavigationBar(title: "\(hijri.day) \(hijri.month.en) \(hijri.year) \(hijri.designation.abbreviated)", subtitle: dateData.readable)
            
            self.fajrTimeLabel.text = self.formatTime(from: timeData.fajr ?? "NA")
            self.duhurTimeLabel.text = self.formatTime(from:timeData.dhuhr ?? "NA")
            self.asrTimeLabel.text = self.formatTime(from:timeData.asr  ?? "NA")
            self.maghribTimeLabel.text = self.formatTime(from:timeData.maghrib  ?? "NA")
            self.ishaTimeLabel.text = self.formatTime(from:timeData.isha  ?? "NA")
            
            self.sunriseTimeLabel.text = self.formatTime(from: timeData.sunrise  ?? "NA", requiredFormat: "hh:mm")
            self.sunsetTimeLabel.text = self.formatTime(from: timeData.sunset  ?? "NA", requiredFormat: "hh:mm")
            
            if let nextPrayer = self.findNextPrayer(timings: timeData) {
                self.nextPrayerNameLabel.text = nextPrayer.0
                self.nextPrayerTimeLabel.text = self.formatTime(from: nextPrayer.1)
                self.nextPrayerTimeZoneLabel.text = self.formatTime(from: nextPrayer.1, requiredFormat: "a")
            } else {
                print("No next prayer found")
                self.nextPrayerNameLabel.text = "Fajr"
                self.nextPrayerTimeLabel.text = "Tomorrow"
            }
        }
    }
    
    func formatTime(from time: Date, requiredFormat: String = "hh:mm") -> String? {
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = requiredFormat
        
        return outputDateFormatter.string(from: time)
    }
    
    func formatTime(from timeString: String, requiredFormat: String = "hh:mm a") -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm (zzz)"
        
        if let date = dateFormatter.date(from: timeString) {
            let outputDateFormatter = DateFormatter()
            outputDateFormatter.dateFormat = requiredFormat
            
            return outputDateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
    
    // Compare current time with timings and find the next time and corresponding prayer name
    func findNextPrayer(timings: Timings) -> (String, Date)? {
        
        let currentTime = Date()
        
        let allTimes = [("Fajr", timings.fajr),  ("Dhuhr", timings.dhuhr), ("Asr", timings.asr),  ("Maghrib", timings.maghrib), ("Isha", timings.isha)]
        
        // Convert all time strings to Date objects
        let timeObjects = allTimes.compactMap { (prayer, time) -> (String, Date)? in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm (zzz)"
            guard let timeDate = dateFormatter.date(from: time ?? "") else { return nil }
            return (prayer, timeDate)
        }
        
        // Filter times that are after the current time
        let nextTimes = timeObjects.filter { (_, time) in
            let calendar = Calendar.current
            let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            if let currentTime = calendar.date(from: currentTimeComponents),
               let time = calendar.date(from: timeComponents) {
                return currentTime < time
            } else {
                return false
            }
        }
        
        // Sort the next times and get the first one
        let sortedNextTimes = nextTimes.sorted { $0.1 < $1.1 }
        
        if let nextTime = sortedNextTimes.first {
            return nextTime
        } else {
            return nil
        }
    }
    
    @IBAction func showQiblaAction(_ sender: UIButton) {
        if let qiblaViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QiblaViewController") as? QiblaViewController{
            self.show(qiblaViewController, sender: nil)
        }
    }
    
    @IBAction func showTasbihAction(_ sender: UIButton) {
        //        notificationManager.removeAllLocalNotifications()
        if let tasbihViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TasbihViewController") as? TasbihViewController{
            self.show(tasbihViewController, sender: nil)
        }
    }
    
    @IBAction func refreshLocationAction(_ sender: UIButton) {
        currentLocation = nil
        locationManager.delegate = self // Set delegate to receive location updates
        locationManager.requestWhenInUseAuthorization() // Request location authorization
        locationManager.startUpdatingLocation() // Start receiving location updates
    }
}

extension HomeViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if(self.currentLocation == nil){
            fetchDataFromAPI(currentLocation: location)
        }
        
        self.currentLocation = location
        
        let defaults = UserDefaults.standard
        defaults.set(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude], forKey: "savedCoordinates")
        
        
        // Reverse geocode to get location name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            if let locality = placemark.locality,  let administrativeArea = placemark.administrativeArea, let country = placemark.country{
                self.locationTitleLabel.text = locality
                self.prayerLocation = locality
                self.prayerSubLocation = "\(administrativeArea), \(country)"
                self.locationSubtitleLabel.text = "\(administrativeArea), \(country)"
            }
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location update errors, if any
        print("Location update error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Handle authorization status changes, if needed
            break
        case .denied, .restricted:
            // Handle denied or restricted access to location services
            break
        case .notDetermined:
            // Location authorization status not determined yet
            break
        @unknown default:
            break
        }
    }
}
