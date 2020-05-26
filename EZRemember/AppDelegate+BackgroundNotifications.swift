//
//  AppDelegate+BackgroundNotifications.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/19/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import BackgroundTasks
import RxSwift

class GRGetNotificationsAndSchedule: Operation {
    
    override var isAsynchronous: Bool {
        return true
    }
    
    private let lockQueue = DispatchQueue(label: "com.ezremember.getnotifications", attributes: .concurrent)
    
    private var _isExecuting: Bool = false
    
    override private(set) var isExecuting: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return self._isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.sync(flags: [.barrier]) {
                self._isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _isFinished: Bool = false
    override private(set) var isFinished: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return _isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.sync(flags: [.barrier]) {
                _isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    let disposeBag = DisposeBag()
    
    var schedule:Schedule?
    
    var notifications:[GRNotification]?
    
    override func start() {
        print("starting")
        self.isFinished = false
        self.isExecuting = true
        self.main()
    }
    
    override func main() {
        
        if isCancelled {
            self.finish()
            return
        }
        
        // We have to cast these objects to any object so that we can merge observables of the same type
        let notifications = NotificationsManager.getNotifications(deviceId: UtilityFunctions.deviceId()).map { $0 as AnyObject }
        let schedule = ScheduleManager.shared.getSchedule().map { $0 as AnyObject }
        
        Observable.zip([notifications, schedule])
            .subscribe { [weak self] (event) in
                guard let self = self else { return }
                guard let elements = event.element else { return }
                
                elements.forEach { (element) in
                    if let schedule = element as? Schedule {
                        self.schedule = schedule
                    } else if let notifications = element as? [GRNotification] {
                        self.notifications = notifications.filter({ $0.active == true })
                    }
                }
                
                self.sendNotifications()
                
        }.disposed(by: self.disposeBag)
    }
    
    private func finish() {
        self.isFinished = true
        self.isExecuting = false
    }
    
    private func sendNotifications () {
        guard let notifications = self.notifications else { return }
        guard let schedule = self.schedule else { return }
        
        let nextHour = UtilityFunctions.getNextHour()
        if schedule.timeSlots.contains(nextHour) {
            UserNotificationScheduler().scheduleNotifications(notifications, times: [nextHour])
        }
        
        self.finish()
    }
    
}

@available(iOS 13.0, *)
extension AppDelegate {
    
    func scheduleAppRefresh() {
        
        let backgroundThread = DispatchQueue(label: "BGAppRefreshTaskRequest.Submit", qos: .background)
        
        backgroundThread.async {
            let request = BGAppRefreshTaskRequest(identifier: "com.dephyned.ezremember-sendnotifications")
            // Fetch no earlier than 60 minutes from now
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30)
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("successfully submitted the sendnotifications task")
            } catch {
                print("Could not schedule app refresh: \(error)")
            }
        }
    }
    
    func registerTask () {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.dephyned.ezremember-sendnotifications",
                                        using: nil)
        { (task) in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
                        
        // Schedule a new refresh task
        scheduleAppRefresh()
        
        let queue = OperationQueue()
        
        // Create an operation that performs the main part of the background task
        let operation = GRGetNotificationsAndSchedule()
        
        // Provide an expiration handler for the background task
        // that cancels the operation
        task.expirationHandler = {
            operation.cancel()
        }
        
        // Start the operation
        queue.addOperations([operation], waitUntilFinished: true)
        task.setTaskCompleted(success: !operation.isCancelled)
        
    }
    
}
