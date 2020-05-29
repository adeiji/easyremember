//
//  Notifications+EZRemember.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/9/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    static let NotificationsSaved = NSNotification.Name("NotificationsSaved")
    static let DeckSaved = NSNotification.Name("DeckSaved")
    static let DeckRemoved = NSNotification.Name("DeckRemoved")
    static let LanguagesUpdated = NSNotification.Name("LanguagesUpdated")
    static let ShowPurchaseViewController = NSNotification.Name("ShowPurchaseViewController")
    static let SyncingFinished = NSNotification.Name("SyncingFinished")
    static let SyncingError = NSNotification.Name("SyncingError")
    static let ErrorDownloadingBooks = NSNotification.Name("ErrorDownloadBooks")
    static let FinishedDownloadingBooks = NSNotification.Name("FinishedDownloadingBooks")
    static let FinishedConvertingPDF = NSNotification.Name("FinishedConvertingPDF")
    
}
