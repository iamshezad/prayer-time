//
//  BackgroundManager.swift
//  PrayerTimes
//
//  Created by Admin on 31/03/24.
//

import UIKit
import BackgroundTasks

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private let refreshTaskIdentifier = "com.PrayerTimes.refreshTask"
    private let dailyTaskIdentifier = "com.PrayerTimes.dailyTask"
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            self.scheduleNextBackgroundTask()
            
            if var currentCounterValue = UserDefaults.standard.object(forKey: "refreshValue") as? Int {
                currentCounterValue += 1
                UserDefaults.standard.set(currentCounterValue, forKey: "refreshValue")
            } else {
                UserDefaults.standard.set(1, forKey: "refreshValue")
            }
            
            self.checkScheduledDailyTask { tasks in
                if tasks.isEmpty{
                    self.scheduleDailyBackgroundTask()
                }
            }
            
            // Perform your background task here
            self.performBackgroundTask(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: dailyTaskIdentifier, using: nil) { task in
            self.scheduleDailyBackgroundTask()
            
            if var currentCounterValue = UserDefaults.standard.object(forKey: "dailyValue") as? Int {
                currentCounterValue += 1
                UserDefaults.standard.set(currentCounterValue, forKey: "dailyValue")
            } else {
                UserDefaults.standard.set(1, forKey: "dailyValue")
            }
            
            self.checkScheduledRefreshTask { tasks in
                if tasks.isEmpty{
                    self.scheduleNextBackgroundTask()
                }
            }
            
            // Perform your background task here
            self.performBackgroundTask(task as! BGProcessingTask)
        }
    }
    
    func scheduleDailyBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: dailyTaskIdentifier)
        request.requiresNetworkConnectivity = true // Set to true if your task requires network connectivity
        
        // Calculate the next occurrence of 1:30 AM for today
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = 9
        dateComponents.minute = 15
        
        
        if let nextDate = calendar.date(from: dateComponents) {
            // Ensure the next scheduled date is in the future
            if nextDate <= now {
                dateComponents.day! += 1 // Move to the next day
            }
            request.earliestBeginDate = calendar.date(from: dateComponents)
        } else {
            print("Error calculating next scheduled date")
            return
        }
        
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to schedule background task: \(error.localizedDescription)")
        }
    }
    
    
    func scheduleNextBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: refreshTaskIdentifier)
        request.requiresNetworkConnectivity = true // Set to true if your task requires network connectivity
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60 * 60) // Start task in 3 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to schedule background task: \(error.localizedDescription)")
        }
    }
    
    func performBackgroundTask(_ task: BGProcessingTask) {
        
        // Create an operation that performs the main part of the background task.
        let operation = PrayerNotificationOperation()
        let operationQueue = OperationQueue()
        
        // Provide the background task with an expiration handler that cancels the operation.
        task.expirationHandler = {
            operation.cancel()
        }
        
        // Inform the system that the background task is complete
        // when the operation completes.
        operation.completionBlock = {
            print("completed after all scheduling")
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        // Start the operation.
        operationQueue.addOperation(operation)
    }
    
    func checkScheduledRefreshTask(completionHandler: @escaping ([BGTaskRequest]) -> Void) {
        BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
            let pendingRequests = taskRequests.filter { $0.identifier == self.refreshTaskIdentifier }
            completionHandler(pendingRequests)
        }
    }
    
    func checkScheduledDailyTask(completionHandler: @escaping ([BGTaskRequest]) -> Void) {
        BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
            let pendingRequests = taskRequests.filter { $0.identifier == self.dailyTaskIdentifier }
            completionHandler(pendingRequests)
        }
    }
}
