//
//  LocalNotificationManager.swift
//  PrayerTimes
//
//  Created by Admin on 31/03/24.
//

import UserNotifications

class LocalNotificationManager {
    static let shared = LocalNotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    func scheduleLocalNotifications(for timings: PrayerTimings) {
        
        removeAllLocalNotifications()
        
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                
                let calendar = Calendar.current
                
                // Schedule notifications for each prayer time
                for (prayer, timeString) in [("Fajr", timings.timings.fajr), ("Dhuhr", timings.timings.dhuhr), ("Asr", timings.timings.asr), ("Maghrib", timings.timings.maghrib), ("Isha", timings.timings.isha)] {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm (zzz)"
                    
                    if let date = dateFormatter.date(from: timeString ?? "") {
                        let triggerDate = calendar.dateComponents([.hour, .minute, .second], from: date)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                        
                        let sdateFormatter = DateFormatter()
                        sdateFormatter.dateFormat = "hh:mm a"
                        
                        // Notification settings
                        let content = UNMutableNotificationContent()
                        
                        if let locality = UserDefaults.standard.string(forKey: "prayerLocation"){
                            content.title = "\(prayer) at \(sdateFormatter.string(from: date))"
                            content.body = "It's time for \(prayer) prayer in \(locality)"
                        }else{
                            content.title = "Prayer Notification"
                            content.body = "It's time for \(prayer) prayer"
                        }
                        
                        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "beep.mp3"))
                        
                        let identifier = UUID().uuidString
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                        
                        self.center.add(request) { (error) in
                            if let error = error {
                                print("Error scheduling notification: \(error.localizedDescription)")
                            } else {
                                print("Notification scheduled for \(prayer) at \(date)")
                            }
                        }
                    }
                }
            } else {
                print("Notification permission not granted.")
            }
        }
    }
    
    func scheduleLocalNotifications(for timings: PrayerTimings, completion: @escaping (Error?) -> Void) {
        removeAllLocalNotifications()
        
        let notificationsToSchedule: [(String, String?)] = [
            ("Fajr", timings.timings.fajr),
            ("Dhuhr", timings.timings.dhuhr),
            ("Asr", timings.timings.asr),
            ("Maghrib", timings.timings.maghrib),
            ("Isha", timings.timings.isha)
        ]
        
        var successfullyScheduledCount = 0
        
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            guard granted else {
                completion(error)
                return
            }
            
            let calendar = Calendar.current
            
            // Schedule notifications for each prayer time
            for (prayer, timeString) in notificationsToSchedule {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm (zzz)"
                
                if let date = dateFormatter.date(from: timeString ?? "") {
                    let triggerDate = calendar.dateComponents([.hour, .minute, .second], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    
                    let sdateFormatter = DateFormatter()
                    sdateFormatter.dateFormat = "hh:mm a"
                    
                    // Notification settings
                    let content = UNMutableNotificationContent()
                    if let locality = UserDefaults.standard.string(forKey: "prayerLocation") {
                        content.title = "\(prayer) at \(sdateFormatter.string(from: date))"
                        content.body = "It's time for \(prayer) prayer in \(locality)"
                    } else {
                        content.title = "Prayer Notification"
                        content.body = "It's time for \(prayer) prayer"
                    }
                    
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "beep.mp3"))
                    
                    let identifier = UUID().uuidString
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    self.center.add(request) { (error) in
                        if let error = error {
                            print("Error scheduling notification: \(error.localizedDescription)")
                            completion(error)
                        } else {
                            successfullyScheduledCount += 1
                            print("Notification scheduled for \(prayer) at \(date)")
                            if successfullyScheduledCount == notificationsToSchedule.count {
                                completion(nil) // All notifications scheduled successfully
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeAllLocalNotifications() {
        // Remove all pending notifications
        center.removeAllPendingNotificationRequests()
        
        // Remove all delivered notifications
        center.removeAllDeliveredNotifications()
        
        print("All local notifications removed.")
    }
    
    func getAllScheduledNotifications() {
        center.getPendingNotificationRequests { requests in
            for request in requests {
                print("Scheduled Notification ID: \(request.content.title)")
            }
        }
    }
}
