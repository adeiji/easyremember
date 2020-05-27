//
//  SceneDelegate+PDFConverter.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/26/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import DephynedFire

protocol HandleSyncingEventsProtocol {
    
    var window:UIWindow? { get set }
    
    func syncingFinished(_ notification: Notification)
    
    func restoringPurchasesFailed(_ notification: Notification)
        
    func errorSyncing (_ notification: Notification)
}

extension HandleSyncingEventsProtocol {
    
    internal func handleErrorSyncing (_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? String {
            print(error)
            AnalyticsManager.logError(message: error)
        }
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
                        
        messageCard.draw(message: "Uh oh! Looks like there was a problem syncing your data.  The most common cause for this is internet problems.  Check to make sure you have a decent internet connection and then try again.", title: "Syncing Failed", superview: window, isError: true)
    }
    
    internal func handleRestoringPurchasesFailed (_ notification: Notification) {
        if let error = notification.userInfo?["error"] as? String {
            print(error)
            AnalyticsManager.logError(message: error)
        }
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
                        
        messageCard.draw(message: "Uh oh! Looks like there was a problem restoring your purchases.  The most common cause for this is internet problems.  Check to make sure you have a decent internet connection and then try again.", title: "Syncing Failed", superview: window, isError: true)
    }
    
    internal func handleSyncingFinished (_ notification: Notification) {
        
        guard let window = self.window else { return }
        
        let messageCard = GRMessageCard()
        
        messageCard.draw(message: "Awesome! You've synced your data using your email.  Now your cards and your epubs can be viewed on other devices, and you can use your email address to retrieve your data any time in the future.  Just make sure you don't forget your email address! Please restart the app now.\n\nHappy learning!", title: "Sync Successful!", superview: window)
    }
    
}

protocol PDFEpubHandlerProtocol: RulesProtocol {
    var window:UIWindow? { get set }
    var toastHandler:ToastHandler { get }
    
    func finishedConvertingPDF(_ notification: Notification)
}

extension PDFEpubHandlerProtocol {
        
    func startUnfinishedPDFConversionProcess () {
        ConvertToEpubHandler.shared.isStillDownloadingEpubs { (stillDownloadingEpubs) in
            if stillDownloadingEpubs {
                self.toastHandler.showToast("Converting PDF to ePub...this may take a while")
            }
        }
    }
    
    func handleDocImportedIntoAppWithUrl (_ url: URL) {
        if UtilityFunctions.urlIsEpub(url: url) {
            self.showBookWithUrl(url)
        } else if UtilityFunctions.urlIsPDF(url: url) {
            self.convertPDFAtUrl(url)
        } else {
            let messageCard = GRMessageCard(color: UIColor.white.dark(Dark.coolGrey700))
            if let window = self.window {
                messageCard.draw(message: "This app can only be used to read ePubs and PDFs, sorry.", title: "Format Not Allowed", superview: window)
            }
        }
    }
    
    internal func showBookWithUrl (_ url: URL) {
        guard let topController = (GRCurrentDevice.shared.getTopController()?.children.first as? UINavigationController)?.topViewController as? ShowEpubReaderProtocol else { return }
        
        topController.showBookReader(url: url)
        if self.userHasSubscription() {
            EBookHandler().backupEbooksAtUrls(urls: [url])
        }
    }
    
    func handleFinishedConvertingPDF (_ notification: Notification) {
           guard let window = self.window else { return }
           
           self.toastHandler.hideToast()
           guard let bookName = notification.userInfo?["bookName"] as? String else { return }
           let card = GRMessageCard()
           
           card.draw(message: "Your PDF \(bookName) has finished converting to Epub.\n\nWould you like to open it now?", title: "Finished Converting PDF to Epub", superview: window, buttonText:"Read Now", cancelButtonText: "No")
           
           card.okayButton?.addTargetClosure(closure: { (_) in
               card.close()
               guard let bookUrl = URL(string: EBookHandler().getURLForBookNamed(bookName)) else { return }
               self.showBookWithUrl(bookUrl)
           })
           
       }
    
    func convertPDFAtUrl (_ url: URL) {
        self.showNeedsConversionMessageCard()
        ConvertToEpubHandler.shared.convertPDFAtUrl(url) { (started) in
            DispatchQueue.main.async {
                self.toastHandler.showToast("Converting PDF to ePub...this may take a while", superview: self.window)
            }
        }
    }
    
    private func showNeedsConversionMessageCard () {
        guard let window = self.window else { return }
        let card = GRMessageCard()
        card.draw(message: "We are currently converting your PDF to an ePub so that you can use it within the app.  This may take a while...", title: "Converting PDF", superview: window)
    }
}