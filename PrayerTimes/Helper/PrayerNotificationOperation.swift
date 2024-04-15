//
//  PrayerNotificationOperation.swift
//  PrayerTimes
//
//  Created by Admin on 03/04/24.
//

import Foundation

class PrayerNotificationOperation: Operation {
    
    var completion: (() -> Void)?
    
    let notificationManager = LocalNotificationManager.shared
    
    override func main() {
        performBackgroundTask()
    }
    
    func performBackgroundTask() {
        if let prayerTimings = fetchPrayerTimings(), checkPrayerMonth() {
            getPrayerTime(prayerTimings: prayerTimings)
        } else {
            if let coordinates = getLocationCoordinates() {
                fetchDataFromAPI(lat: coordinates["latitude"] ?? 0.0, lon: coordinates["longitude"] ?? 0.0)
            }
        }
    }
    
    func fetchDataFromAPI(lat: Double, lon: Double) {
        let (currentYear, currentMonth) = getCurrentMonthAndYear()
        
        let apiUrlString = "https://api.aladhan.com/v1/calendar/\(currentYear)/\(currentMonth)?latitude=\(lat)&longitude=\(lon)&method=2"
        
        if let apiUrl = URL(string: apiUrlString) {
            let session = URLSession.shared
            
            let task = session.dataTask(with: apiUrl) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                guard let responseData = data else {
                    print("No data received")
                    return
                }
                
                do {
                    UserDefaults.standard.set(currentMonth, forKey: "prayerMonth")
                    
                    let decoder = JSONDecoder()
                    let prayerTimingsResponse = try decoder.decode(PrayerTimingsResponse.self, from: responseData)
                    
                    self.storePrayerTimings(prayerTimingsResponse)
                    self.getPrayerTime(prayerTimings: prayerTimingsResponse)
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            
            task.resume()
        } else {
            print("Invalid URL")
        }
    }
    
    func storePrayerTimings(_ prayerTimings: PrayerTimingsResponse) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(prayerTimings)
            UserDefaults.standard.set(encodedData, forKey: "prayerTimings")
        } catch {
            print("Error encoding prayer timings data: \(error)")
        }
    }
    
    func getLocationCoordinates() -> [String: Double]? {
        let defaults = UserDefaults.standard
        if let savedCoordinates = defaults.dictionary(forKey: "savedCoordinates") as? [String: Double] {
            return savedCoordinates
        }
        return nil
    }
    
    func checkPrayerMonth() -> Bool {
        let (_, currentMonth) = getCurrentMonthAndYear()
        
        if let prayerMonth = UserDefaults.standard.value(forKey: "prayerMonth") as? Int {
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
            return (0, 0)
        }
    }
    
    func getPrayerTime(prayerTimings: PrayerTimingsResponse) {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        if let todayTimings = prayerTimings.data.first(where: { data in
            if let date = dateFormatter.date(from: data.date.readable) {
                return Calendar.current.isDate(date, inSameDayAs: currentDate)
            }
            return false
        }) {
            notificationManager.scheduleLocalNotifications(for: todayTimings) { error in
                if let error = error {
                    print("Error scheduling notifications: \(error.localizedDescription)")
                } else {
                    print("All notifications scheduled successfully!")
                }
                
                self.taskCompleted()
            }
        } else {
            print("No timings found for today")
        }
    }
    
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
    
    func taskCompleted() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.completion?()
        }
    }
}
