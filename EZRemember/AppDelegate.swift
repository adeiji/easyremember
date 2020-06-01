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
import FirebaseMessaging
import SwiftyBootstrap
import DephynedPurchasing
import FirebaseCrashlytics
import BackgroundTasks
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TabControllerProtocol, PDFEpubHandlerProtocol, HandleSyncingEventsProtocol {
            
    var toastHandler: ToastHandler = ToastHandler()
    
    var window:UIWindow? {
        didSet {
            guard let notificationId = self.remoteNotificationOpenedId else { return }
            self.showNotificationWithId(notificationId)
        }
    }
    
    /// Key for the user's device Id stored in UserDefaults
    let kDeviceId = "deviceId"
    
    /// An Id given to this device when app is first launched.  This Id is used to store and retrieve user's information using Firebase
    var deviceId:String?
    
    let disposeBag = DisposeBag()
    
    /// If a remote notification was clicked to open this app then set it's Id here so that after the root view controller has been set we can display
    /// the notification
    var remoteNotificationOpenedId:String? = nil
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        self.handleDocImportedIntoAppWithUrl(url)
        
        return true
    }
    
    @objc internal func syncingFinished(_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleSyncingFinished(notification)
        }
        
    }
    
    @objc internal func restoringPurchasesFailed(_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleRestoringPurchasesFailed(notification)
        }
    }
    
    @objc internal func errorSyncing(_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleErrorSyncing(notification)
        }
        
    }
        
    @objc internal func finishedConvertingPDF(_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleFinishedConvertingPDF(notification)
        }
    }
    
    private func addObservers () {
        NotificationCenter.default.addObserver(self, selector: #selector(syncingFinished(_:)), name: .FinishedDownloadingBooks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorSyncing(_:)), name: .ErrorDownloadingBooks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishedConvertingPDF(_:)), name: .FinishedConvertingPDF, object: nil)
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
                
        return true
    }
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        // Override point for customization after application launch.
        FirebaseApp.configure()

        let _ = ScheduleManager.shared // instantiate our schedule manager singleton object
        let _ = GRCurrentDevice.shared // instantiate the current device object
        
        PKIAPHandler.shared.loadProductIds(Purchasing.inAppPurchaseProductIds)
        
        if application.isRegisteredForRemoteNotifications {
            self.setupRemoteNotifications(application: application)
        }
        
        // If we're on iOS 13 then the loading of the view should be handle by the scene delegate
        if #available(iOS 13.0, *) {
            return true
        }
        
        self.startUnfinishedPDFConversionProcess()
        EBookHandler().unzipEpubs()
        
        self.loadInitialView()
        self.addObservers()
        
        return true
    }
    
    func loadInitialView () {
        let bounds = UIScreen.main.bounds
        self.window = UIWindow(frame: bounds)
        self.window?.rootViewController = self.createTabController()
        self.window?.makeKeyAndVisible()
    }
    
    func handleRememberedNotification (response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let notificationId = userInfo["notificationId"] as? String else { return }
        guard let creationDate = userInfo["creationDate"] as? String else { return }
        guard let creationDateDouble = Double(creationDate) else { return }
                
        switch response.actionIdentifier {
        case "REMEMBERED":
            NotificationsManager.shared.incrementNotificationRememberCount(notificationId: notificationId)
            if let mainViewController = (self.window?.rootViewController as? GRTabController)?.getNotificationsViewController() {
                mainViewController.incrementNotificationRememberedCount(notificationId: notificationId)
            }
            break
        case "NOT_REMEMBERED":
            break;
        case "MASTERED":
            NotificationsManager.shared.rememberNotificationWithId(notificationId)
            NotificationsManager.shared.setNextNotificationToActive(creationDate: creationDateDouble)
            break;
        default:
            if (self.window?.rootViewController != nil) {
                self.showNotificationWithId(notificationId)
            }
            
            break;
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        switch response.notification.request.content.categoryIdentifier {
        case "NOTIFICATIONS":
            self.handleRememberedNotification(response: response)
            break;
        case "SENTENCE":
            if let textResponse =  response as? UNTextInputNotificationResponse {
                let sentence =  textResponse.userText
                ScheduleManager.shared.saveSentence(sentence)
                let mainViewController = (self.window?.rootViewController as? GRTabController)?.getNotificationsViewController()
                mainViewController?.mainView?.showLoadingNVActivityIndicatorView()
                TranslateManager.translateText(sentence).subscribe { [weak self] (event) in
                    mainViewController?.mainView?.showFinishedLoadingNVActivityIndicatorView()
                    guard let _ = self else { return }
                    if let translations = event.element {
                        let translation = translations.translated[Locale.current.languageCode ?? "en"]
                        guard let view = mainViewController?.view else { return }
                        GRMessageCard().draw(message: translation ?? "Could not get translation", title: "Is this what you wanted to say?", superview: view, buttonText: "Yeah! I did it", cancelButtonText: "Not quite right...")
                    }
                }.disposed(by: self.disposeBag)
            }
            break;
        default:
            break;
        }
                        
        completionHandler()
    }
    
    private func showNotificationWithId (_ notificationId: String) {
        NotificationsManager.shared.getNotificationWithId(notificationId) { [weak self] (notification) in
            guard let self = self else { return }
            self.showNotificationViewController(notification: notification)
        }
    }
    
    private func showNotificationViewController (notification: GRNotification?) {
        let tabController = self.window?.rootViewController as? GRTabController
        tabController?.showNotificationsViewController()
        let mainVC = tabController?.getNotificationsViewController()
        
        guard let notification = notification else { return }
        mainVC?.present(GRNotificationViewController(notification: notification, isEditingCard: true), animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if (application.applicationState == .active) {
            // App was opened from a push notification
            
        }
    }
        
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        FirebasePersistenceManager.shared.saveFcmToken(fcmToken)
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}


