//
//  UserNotificationScheduler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct UserNotificationScheduler {
    
    let disposeBag = DisposeBag()
    
    public func scheduleNotifications (_ notifications:[GRNotification], times: [Int]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        self.sendNotifications(notifications, times: times)
    }
    
    private func sendNotifications (_ notifications: [GRNotification], times: [Int]) {
        let notificationsToSend = notifications.filter( { $0.active == true } )

        notificationsToSend.forEach { (notification) in
            times.forEach { (time) in
                let notificationRequest = self.createNotification(notification, time: time)
                UNUserNotificationCenter.current().add(notificationRequest)
            }
        }
    }
    
    private func createNotification (_ notification: GRNotification, time: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Your Reminder"
        content.body = "\(notification.description)\n\(notification.caption)"
        content.sound = UNNotificationSound.default

        var date = DateComponents()
        date.hour = 15
        date.minute = 21
        
        // show this notification five seconds from now
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        return request
    }
    
}
