//
//  AppDelegate+RemoteNotifications.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/6/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import Messages
import Firebase
import FirebaseMessaging

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    
    public func setupRemoteNotifications (application: UIApplication) {
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        let rememberedNotification = UNNotificationAction(identifier: "REMEMBERED", title: "Remembered", options: UNNotificationActionOptions(rawValue: 0))
        
        let notificationCategory = UNNotificationCategory(identifier: "NOTIFICATIONS", actions: [rememberedNotification], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([notificationCategory])
        
    }
}
