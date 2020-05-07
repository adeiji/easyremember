//
//  AppDelegate.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import UIKit
import Firebase
import DephynedFire
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Key for the user's device Id stored in UserDefaults
    let kDeviceId = "deviceId"
    
    /// An Id given to this device when app is first launched.  This Id is used to store and retrieve user's information using Firebase
    var deviceId:String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // If this user does not have a DeviceId assigned to it then assign it now
        let userDefaults = UserDefaults()
        
        // Get the id assigned to this device
        self.deviceId = userDefaults.object(forKey: self.kDeviceId) as? String
        
        if (self.deviceId == nil) {
            self.deviceId = UUID().uuidString
            userDefaults.set(self.deviceId, forKey: self.kDeviceId)
        }
        
        FirebaseApp.configure()
        self.setupRemoteNotifications(application: application)
                        
        UNUserNotificationCenter.current().requestAuthorization(options: [ .alert, .badge, .sound ]) { (success, error) in
            if success {
                AnalyticsManager.logGenericEvent(name: .AllowNotifications)
            } else if let error = error {
                AnalyticsManager.logError(message: error.localizedDescription)
                print(error.localizedDescription)
            }
        }
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        FirebasePersistenceManager.updateDocument(withId: UtilityFunctions.deviceId(), collection: Schedule.Keys.kCollectionName, updateDoc: [
            Schedule.Keys.kFcmToken: fcmToken
        ], completion: nil)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

