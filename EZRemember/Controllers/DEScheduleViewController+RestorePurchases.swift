//
//  DEScheduleViewController+RestorePurchases.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/30/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import DephynedPurchasing
import DephynedFire

extension DEScheduleViewController {
    
    fileprivate func showRestorePurchasesSuccessfulCard() {
        let successCard = GRMessageCard()
        let purchasesRetrievedMessage = NSLocalizedString("purchasesRetrievedMessage", comment: "when the previous purchases are finished being retrieved than this is the message displayed on the card that you see")
        let purchasesRestored = NSLocalizedString("purchasesRestoredTitle", comment: "When the purchases are restored and the message card shows, this is the title of that card")
        
        successCard.draw(message: purchasesRetrievedMessage, title: purchasesRestored, superview: self.view)
    }
    
    fileprivate func restorePurchases(_ actionButton: UIButton) {
        let loading = actionButton.showLoadingNVActivityIndicatorView()
        PKIAPHandler.shared.restorePurchase { (alertType, product, transaction) in
            actionButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
            if alertType == .error {
                return
            }
            
            self.showRestorePurchasesSuccessfulCard()
        }
    }
    
    internal func setupPurchaseCardPurchaseButton(_ restorePurchaseCard: GRTitleAndButtonCard) {
        restorePurchaseCard.actionButton?.addTargetClosure(closure: { [weak self] (actionButton) in
            guard let self = self else { return }
            self.promptForTypeOfPurchasesToRestore { (appStorePurchase) in
                if appStorePurchase {
                    self.restorePurchases(actionButton)
                }
            }
        })
    }
    
    fileprivate func promptForTypeOfPurchasesToRestore (_ completion: @escaping (Bool) -> Void) {
        
        // There's two different options for purchasing
        
        // 1. Purchasing through the app store
        // 2. Purchasing online
        
        // If they made their purchase online, than we need to prompt the user to enter their purchase Id.
        // When they use this purchase Id, we will automatically also sync with the email attached to the purchase id
        
        let messageCard = GRMessageCard(addTextField: true, textFieldPlaceholder: "Enter your purchase Id...", showFromTop: true)
        messageCard.draw(message: "If you made your purchase online, please enter your 'Purchase Id'.  If you purchased from within the app, please click 'Restore App Store Purchases'", title: "Restore Purchases", superview: self.view, buttonText: "Verify Purchase Id", cancelButtonText: "Restore App Store Purchases")
        messageCard.addExitButton()
        messageCard.firstButton?.addTargetClosure(closure: { [weak self] (verifyButton) in
            guard let self = self else { return }
            // Verify the purchase on our servers
            guard let purchaseId = messageCard.textField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            if self.validatePurchaseId(purchaseId) {
                messageCard.firstButton?.showLoadingNVActivityIndicatorView()
                self.verifyPurchaseWithId(purchaseId, verifyButton: messageCard.firstButton)
            }
        })
        
        messageCard.secondButton?.addTargetClosure(closure: { [weak self] (restoreAppStorePurchases) in
            guard let _ = self else { return }
            completion(true)
            messageCard.close()
        })
    }
    
    func validatePurchaseId (_ purchaseId: String) -> Bool {
        
        if purchaseId == "" { return false }
        if purchaseId.count < 8 {
            GRMessageCard().draw(message: "Please enter an Id of at least 8 letters", title: "Invalid Id", superview: self.view, isError: true)
            return false
        }
                
        return true
    }
    
    fileprivate func updateVerifyButtonToSuccessfulState (_ verifyButton: UIButton?) {
        verifyButton?.backgroundColor = UIColor.Style.htMintGreen
        verifyButton?.setTitle("Purchase Verified!!", for: .normal)
    }
    
    fileprivate func handleVerifiedPurchaseId(_ purchasedPackage: String, verifyButton: UIButton?) {
        self.saveSchedule()
        ScheduleManager.shared.setPurchasePackage(purchasedPackage) { (success, error) in
            verifyButton?.showFinishedLoadingNVActivityIndicatorView()
            
            if let error = error {
                print(error.localizedDescription)
                AnalyticsManager.logError(message: error.localizedDescription)
                GRMessageCard().draw(message: "Your purchase was verified, but we had an issue syncing with your email address. Please check your internet connection and try again", title: "Error Sync", superview: self.view, isError: true)
            } else {
                self.updateVerifyButtonToSuccessfulState(verifyButton)
            }
        }
    }
    
    fileprivate func verifyPurchaseWithId (_ sessionId: String, verifyButton: UIButton?) {
        ScheduleManager.shared.getSubscriptionForSessionId(sessionId).subscribe { [weak self] (event) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                    
                if event.isCompleted { return }
                
                if let error = event.error {
                    print(error.localizedDescription)
                    AnalyticsManager.logError(message: error.localizedDescription)
                    GRMessageCard().draw(message: "There was an error when verifying your Purchase Id.  Please check your internet connection and try again", title: "Error Verifying Id", superview: self.view, isError: true)
                    return
                }
                
                if let unwrappedElement = event.element, let purchasedPackage = unwrappedElement {
                    self.handleVerifiedPurchaseId(purchasedPackage, verifyButton: verifyButton)
                } else {
                    verifyButton?.showFinishedLoadingNVActivityIndicatorView()
                    GRMessageCard().draw(message: "There is no purchase with this ID.  Please make sure you entered the 'Purchase Id' correctly", title: "Invalid Purchase Id", superview: self.view, isError: true)
                }
            }
        }.disposed(by: self.disposeBag)
    }
}
