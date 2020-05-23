//
//  DESyncViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/11/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift
import DephynedFire

class DESyncViewController: UIViewController, AddCancelButtonProtocol, RulesProtocol {
        
    weak var syncButton: UIButton?
    
    weak var syncEmailButton: UIButton?
    
    weak var syncIdTextField:UITextField?
    
    weak var saveEmailTextField:UITextField?
    
    let disposeBag = DisposeBag()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let syncView = GRViewWithScrollView().setup(superview: self.view, showNavBar: true, navBarHeaderText: "")
        syncView.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.addCancelButton(view: syncView)
        syncView.containerView.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.drawScreen(syncView: syncView)
        
        self.syncButtonPressed()
        self.saveEmailButtonPressed()
        
        NotificationCenter.default.addObserver(self, selector: #selector(syncFinished), name: .FinishedDownloadingBooks, object: nil)
    }
    
    private func validate () -> Bool {
        guard let count = self.syncIdTextField?.text?.count else { return false }
        if count < 8 {
            let idTooSmallCard = GRMessageCard(color: UIColor.white.dark(Dark.coolGrey700))
            idTooSmallCard.draw(message: NSLocalizedString("syncIdValidationError", comment: "The error message when the user enters an invalid sync id"), title: NSLocalizedString("syncIdTooShort", comment: "Sync Id Too Short"), buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: self.view)
            self.syncIdTextField?.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    private func syncButtonPressed () {
        self.syncButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            guard let syncId = self.syncIdTextField?.text else { return }
            if self.validate() {
                UtilityFunctions.addSyncId(syncId)
                self.updateSyncButton(finishedSyncing: true)
            }
        })
    }
    
    private func handleSyncError(_ error: Error?) {
        if let error = error {
            AnalyticsManager.logError(message: error.localizedDescription)
            let errorCard = GRMessageCard()
            errorCard.draw(message: NSLocalizedString("syncingError", comment: "Error storing email address for sycing message"), title:  NSLocalizedString("emailNotSaved", comment: "Email not saved"), superview: self.view)
        }
    }
    
    private func saveSyncInformationToServer(_ emailAddress: String) {
        let sync = Sync(email: emailAddress, deviceId: UtilityFunctions.deviceId())
        let loading = self.syncEmailButton?.showLoadingNVActivityIndicatorView()
        SyncManager.shared.syncWithEmail(sync: sync) { (success, error) in
            self.syncEmailButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            self.syncEmailButton?.backgroundColor = UIColor.Style.htLightOrange
            self.syncEmailButton?.setTitle(NSLocalizedString("processing", comment: "Processing...do not close app"), for: .normal)
            
            self.handleSyncError(error)
        }
    }
    
    @objc private func syncFinished () {
        self.syncEmailButton?.backgroundColor = UIColor.Style.htMintGreen
        self.syncEmailButton?.setTitle(NSLocalizedString("finishedSyncing", comment: "Finished syncing!!"), for: .normal)
    }
    
    private func saveEmailButtonPressed () {
        self.syncEmailButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            self.saveEmailTextField?.resignFirstResponder()
            if !self.userHasSubscription(ruleName: Purchasing.Rules.kRequiresPurchase) {                
                return
            }
            
            guard let emailAddress = self.saveEmailTextField?.text else {
                self.invalidEmail()
                return
            }
            
            if emailAddress.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                if emailAddress.isValidEmailAddress() == true {
                    self.saveSyncInformationToServer(emailAddress.lowercased())
                } else {
                    self.invalidEmail()
                }
            } else {
                self.invalidEmail()
            }
        })
    }
    
    private func invalidEmail () {
        let errorCard = GRMessageCard()
        errorCard.draw(message: NSLocalizedString("promptValidEmail", comment: "Please enter a valid email address"), title: NSLocalizedString("invalidEmail", comment: "Invalid Email"), superview: self.view, buttonText: NSLocalizedString("okay", comment: "generic okay throughout the app"), isError: true)
    }
    
    private func showErrorMessage (error: Error){
                        
        var message = NSLocalizedString("syncIssue", comment: "Something went wrong while syncing")
        
        if let error = error as? NotificationsManager.SyncingError {
            if error == .NoNotifications {
                message = NSLocalizedString("syncIdInvalid", comment: "This Sync Id is invalid")
            }
        }
        
        let errorCard = GRMessageCard()
        errorCard.draw(message: message, title: NSLocalizedString("errorSyncingTitle", comment: "Error Syncing"), superview: self.view)
        
    }
    
    private func updateSyncButton (finishedSyncing: Bool) {
        if finishedSyncing {
            self.syncButton?.backgroundColor = UIColor.Style.htMintGreen
            self.syncButton?.setTitle(NSLocalizedString("syncFinishedButtonText", comment: "The text that shows when the syncing has finished"), for: .normal)
        }
    }
    
    private func drawScreen (syncView: GRViewWithScrollView) {
        
        let syncInstructions = NSLocalizedString("syncInstructions", comment: "The sync instructions")
        
        let card = GRBootstrapElement(
            color: .clear,
            anchorWidthToScreenWidth: true,
            margin: BootstrapMargin(left: .Five, top: .Five, right: .Five, bottom: .Five),
            superview: syncView.containerView)
        
        let syncIdTextField = Style.wideTextField(withPlaceholder: NSLocalizedString("enterSyncId", comment: "The placeholder for the sync id text field"), superview: nil, color: UIColor.black)
        syncIdTextField.font = CustomFontBook.Regular.of(size: .small)
        
        let syncButton = Style.largeButton(with: NSLocalizedString("sync", comment: "generic sync"), backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), fontColor: UIColor.white.dark(Dark.coolGrey900))
                        
        let deviceId = UtilityFunctions.deviceId()
        let indexOfHyphen = deviceId.firstIndex(of: "-") ?? deviceId.endIndex
        let shortDeviceId = deviceId[..<indexOfHyphen]
        
        // EMAIL ADDRESS INSTRUCTIONS LABEL
        
        let emailAddressSyncMessage = NSLocalizedString("emailAddressSyncMessage", comment: "Explanation of how the syncing with email works")
        let emailInstructionsLabel = Style.label(withText: emailAddressSyncMessage, superview: nil, color: UIColor.black.dark(.white))
        emailInstructionsLabel.font = CustomFontBook.Regular.of(size: .medium)
        
        let saveEmailButton = Style.largeButton(with: NSLocalizedString("emailSyncButton", comment: "Button text for sync email button"), backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), fontColor: UIColor.white.dark(Dark.coolGrey900))
        
        let emailAddressSyncTextField = Style.wideTextField(withPlaceholder: NSLocalizedString("enterEmail", comment: "Enter your email address"), superview: nil, color: UIColor.black)
        emailAddressSyncTextField.font = CustomFontBook.Regular.of(size: .small)
        if let syncEmail = UtilityFunctions.getSyncEmail() {
            emailAddressSyncTextField.placeholder = String(format: NSLocalizedString("currentSyncEmail", comment: "Currently synced with <-email->"), syncEmail)
        }
        
        card.addRow(columns: [
            // Title
            Column(cardSet: Style.label(withText: NSLocalizedString("howToSync", comment: "How to sync with other devices"),
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Bold.of(size: .large))
                    .toCardSet(),
                        xsColWidth: .Twelve),
            
            // Your Sync Id
            Column(cardSet: Style.label(
                withText: NSLocalizedString("yourSyncId", comment: "- Your Sync Id -"),
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet(),
                   xsColWidth: .Twelve),
            
            // Show the device Id
            Column(cardSet:
                Style.label(
                    withText: String(shortDeviceId),
                    superview: nil,
                    color: UIColor.black.dark(.black),
                    textAlignment: .center)
                        .font(CustomFontBook.Regular.of(size: .medium))
                        .backgroundColor(.white)
                        .radius(radius: 10)
                        .toCardSet()
                            .withHeight(60),
                xsColWidth: .Twelve),
            
            Column(cardSet: Style.label(withText: NSLocalizedString("syncAcrossDevices", comment: "To sync your cards across devices..."), superview: nil, color: UIColor.black.dark(.white) ).font(CustomFontBook.Bold.of(size: .medium)).toCardSet(), xsColWidth: .Twelve),
            
            // The sync instruction card
            // How to get syc with other devices instructions
            Column(cardSet: Style.label(
                withText: syncInstructions,
                superview: nil,
                color: UIColor.black.dark(.white))
                .font(CustomFontBook.Regular.of(size: .medium))
                    .toCardSet()
                    .margin.bottom(40),
                   xsColWidth: .Twelve),
            
            // The sync Id input field
            Column(cardSet:
                syncIdTextField
                        .backgroundColor(UIColor.Style.lightGray)
                        .radius(radius: 5)
                        .toCardSet(),
                   xsColWidth: .Twelve)
            ])
        
        card.addRow(columns: [

            // THE SYNC BUTTON

            Column(cardSet: syncButton
                .radius(radius: 5)
                .toCardSet().withHeight(50), xsColWidth: .Twelve).forSize(.md, .Six),
            
            // EMAIL SYNCING
            
            Column(cardSet: Style.label(withText: NSLocalizedString("syncEbooks", comment: "To sync your cards and your eBooks using your email..."), superview: nil, color: UIColor.black.dark(.white) )
                .font(CustomFontBook.Bold.of(size: .medium))
                .toCardSet().margin.top(40),
                   xsColWidth: .Twelve),
            
            // EMAIL INSTRUCTIONS LABEL
            
            Column(cardSet: emailInstructionsLabel.toCardSet(), xsColWidth: .Twelve),
            
            // EMAIL TEXT FIELD
            
            Column(cardSet: emailAddressSyncTextField.backgroundColor(UIColor.Style.lightGray).radius(radius: 5)
                .toCardSet().margin.top(40), xsColWidth: .Twelve)
        ])
        
        card.addRow(columns: [
            Column(cardSet: saveEmailButton.radius(radius: 5).toCardSet().withHeight(50), xsColWidth: .Twelve).forSize(.md, .Six)
        ], anchorToBottom: true)
        
        card.addToSuperview(superview: syncView.containerView, viewAbove: nil, anchorToBottom: true)
        syncView.updateScrollViewContentSize()
        
        self.syncButton = syncButton
        self.syncIdTextField = syncIdTextField
        self.syncEmailButton = saveEmailButton
        self.saveEmailTextField = emailAddressSyncTextField
        
    }
    
}
