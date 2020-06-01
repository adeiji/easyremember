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
        
        let rememberedNotification = UNNotificationAction(identifier: "REMEMBERED", title: "Yes", options: UNNotificationActionOptions(rawValue: 0))
        
        let notRememberedNotification = UNNotificationAction(identifier: "NOT_REMEMBERED", title: "No", options: UNNotificationActionOptions(rawValue: 0))
        
        let masteredNotification = UNNotificationAction(identifier: "MASTERED", title: "I've Mastered This Card", options: UNNotificationActionOptions(rawValue: 0))
                        
        let notificationCategory = UNNotificationCategory(identifier: "NOTIFICATIONS", actions: [rememberedNotification, notRememberedNotification, masteredNotification], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        
        // SENTENCE CATEGORY
        
        let finishedSentence = UNTextInputNotificationAction(
        identifier: "WRITTEN.SENTENCE",
        title: "Write your sentence",
        options: [UNNotificationActionOptions.foreground],
        textInputButtonTitle: "Check if correct",
        textInputPlaceholder: "")
                        
        let sentenceCategory = UNNotificationCategory(identifier: "SENTENCE", actions: [finishedSentence], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([notificationCategory, sentenceCategory])
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
