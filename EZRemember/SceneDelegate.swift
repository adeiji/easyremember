//
//  SceneDelegate.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import UIKit
import RxSwift
import SwiftyBootstrap
import DephynedFire

class SceneDelegate: UIResponder, UIWindowSceneDelegate, RulesProtocol {
        
    var window: UIWindow?
    
    var mainViewController:DEMainViewController?
    
    var timeSlots:[Int]?
    
    let disposeBag = DisposeBag()

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print(URLContexts.description)
        guard let url = URLContexts.first?.url else { return }
        
        if UtilityFunctions.urlIsEpub(url: url) {
            guard let topController = (GRCurrentDevice.shared.getTopController()?.children.first as? UINavigationController)?.topViewController as? ShowEpubReaderProtocol else { return }
            
            topController.showBookReader(url: url)
            if self.userHasSubscription() {
                EBookHandler().backupEbooksAtUrls(urls: [url])
            }
        } else {
            let messageCard = GRMessageCard(color: UIColor.white.dark(Dark.coolGrey700))
            if let window = self.window {
                messageCard.draw(message: "This app can only be used to read ePubs, sorry.", title: "Format Not Allowed", superview: window)
            }
        }
    }
    
    @objc private func syncingFinished (_ notification: Notification) {
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
        
        messageCard.draw(message: "Awesome! You've synced your data using your email.  Now your cards and your epubs can be viewed on other devices, and you can use your email address to retrieve your data any time in the future.  Just make sure you don't forget your email address! Please restart the app now.\n\nHappy learning!", title: "Sync Successful!", superview: window)
    }
    
    @objc private func errorSyncing (_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? String {
            print(error)
            AnalyticsManager.logError(message: error)
        }
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
                        
        messageCard.draw(message: "Uh oh! Looks like there was a problem syncing your data.  The most common cause for this is internet problems.  Check to make sure you have a decent internet connection and then try again.", title: "Syncing Failed", superview: window, isError: true)
    }
    
    @objc private func restoringPurchasesFailed (_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? String {
            print(error)
            AnalyticsManager.logError(message: error)
        }
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
                        
        messageCard.draw(message: "Uh oh! Looks like there was a problem restoring your purchases.  The most common cause for this is internet problems.  Check to make sure you have a decent internet connection and then try again.", title: "Syncing Failed", superview: window, isError: true)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        let testUrl = Bundle.main.url(forResource: "test", withExtension: "pdf")
        let convert = ConvertToEpubHandler()
        convert.downloadConvertedEPUB(jobId: "12742178")
        
        EBookHandler().unzipEpubs()
        
        window.rootViewController = self.createTabController()
        self.window = window
        window.makeKeyAndVisible()
        NotificationCenter.default.addObserver(self, selector: #selector(syncingFinished(_:)), name: .FinishedDownloadingBooks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorSyncing(_:)), name: .ErrorDownloadingBooks, object: nil)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

