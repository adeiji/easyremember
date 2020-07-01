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

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate, PDFEpubHandlerProtocol, TabControllerProtocol, HandleSyncingEventsProtocol {
    
    let toastHandler: ToastHandler = ToastHandler()
    
    var window: UIWindow?
    
    let disposeBag = DisposeBag()
        
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print(URLContexts.description)
        guard let url = URLContexts.first?.url else { return }
        self.handleDocImportedIntoAppWithUrl(url)        
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
    
    @objc internal func finishedConvertingPDF(_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleFinishedConvertingPDF(notification)
        }
        
    }
    
    @objc internal func errorSyncing (_ notification: Notification) {
        DispatchQueue.main.async {
            self.handleErrorSyncing(notification)
        }
    }
                   
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
                            
        self.startUnfinishedPDFConversionProcess()
        BookHandler().prepareBooks()
        
        window.rootViewController = self.createTabController()
        self.window = window
        
        self.setRootControllerForAppDelegate()
        window.makeKeyAndVisible()
        self.addObservers()
        self.removeTempFolder()
                        
    }
    
    private func setRootControllerForAppDelegate () {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.window = self.window
    }
    
    private func addObservers () {
        NotificationCenter.default.addObserver(self, selector: #selector(syncingFinished(_:)), name: .FinishedDownloadingBooks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorSyncing(_:)), name: .ErrorDownloadingBooks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishedConvertingPDF(_:)), name: .FinishedConvertingPDF, object: nil)
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

