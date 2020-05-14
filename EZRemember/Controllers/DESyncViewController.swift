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

class DESyncViewController: UIViewController {
        
    weak var syncButton: UIButton?
    
    weak var syncIdTextField:UITextField?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let syncView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "")
        syncView.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        syncView.navBar.isHidden = true
        syncView.containerView.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.drawScreen(syncView: syncView)
        self.syncButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            guard let syncId = self.syncIdTextField?.text else { return }
                        
            NotificationsManager.sync(syncId)
        })
    }
    
    private func drawScreen (syncView: GRViewWithScrollView) {
        
        let syncInstructions =
"""
To sync your items across devices...

•  Copy "Your Sync Id" above
•  Open the app on the other device
•  Click on the Sync with other devices button
•  Enter the "Sync Id" into the input box below
•  Click Sync

You only have to input this one time to sync between the different devices, but each time you want to add a new device you must go through the process again.
"""
        
        let card = GRBootstrapElement(
            color: .clear,
            anchorWidthToScreenWidth: true,
            margin: BootstrapMargin(left: .Four, top: .Four, right: .Four, bottom: .Four),
            superview: syncView.containerView)
        
        let syncIdTextField = Style.wideTextField(withPlaceholder: "Enter your sync Id", superview: nil, color: UIColor.black)
        let syncButton = Style.largeButton(with: "Sync", backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan))
        
        card.addRow(columns: [
            // Title
            Column(cardSet: Style.label(
                withText: "How to sync with other devices",
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Bold.of(size: .large))
                    .toCardSet(),
                        xsColWidth: .Twelve),
            
            // Your Sync Id
            Column(cardSet: Style.label(
                withText: "- Your Sync Id -",
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet(),
                   xsColWidth: .Twelve),
            
            // Show the device Id
            Column(cardSet:
                Style.label(
                    withText: UtilityFunctions.deviceId(),
                    superview: nil,
                    color: UIColor.black.dark(.black),
                    textAlignment: .center)
                        .font(CustomFontBook.Regular.of(size: .medium))
                        .backgroundColor(.white)
                        .radius(radius: 10)
                        .toCardSet()
                            .withHeight(60),
                xsColWidth: .Twelve),
            
            // The sync instruction card
            // How to get syc with other devices instructions
            Column(cardSet: Style.label(
                withText: syncInstructions,
                superview: nil,
                color: UIColor.black.dark(.white))
                .font(CustomFontBook.Regular.of(size: .medium))
                    .toCardSet()
                    .margin.top(40)
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
            // The sync button
            Column(cardSet: syncButton
                .radius(radius: 5)
                .toCardSet().withHeight(50), xsColWidth: .Twelve).forSize(.md, .Six)
        ], anchorToBottom: true)
        
        card.addToSuperview(superview: syncView.containerView, viewAbove: nil, anchorToBottom: true)
        syncView.updateScrollViewContentSize()
        
        self.syncButton = syncButton
        self.syncIdTextField = syncIdTextField
        
    }
    
}