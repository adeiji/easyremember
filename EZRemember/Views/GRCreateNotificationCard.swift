//
//  GRCreateNotificationCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift

import UITextView_Placeholder;

class GRCreateNotificationCard: GRBootstrapElement, UITextViewDelegate {
    
    /// The done button for this card
    weak var addButton:UIButton?
    
    weak var firstTextView:UITextView?
    
    weak var descriptionTextView:UITextView?
    
    weak var cancelButton:UIButton?
    
    func textViewDidChange(_ textView: UITextView) {
        if (self.firstTextView?.text.trimmingCharacters(in: .whitespaces) == ""
            || self.descriptionTextView?.text.trimmingCharacters(in: .whitespaces) == "") {
            self.addButton?.isEnabled = false
            self.addButton?.alpha = 0.2
        } else {
            self.addButton?.isEnabled = true
            self.addButton?.alpha = 1.0
        }
    }
    
    init(superview: UIView) {
        super.init(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: true)
        self.setupUI(superview: superview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelButton (card:GRBootstrapElement, superview: UIView) -> UIButton {
        let cancelButton = Style.largeButton(with: "Cancel", backgroundColor: .red, fontColor: .white)
        cancelButton.titleLabel?.font = FontBook.allBold.of(size: .medium)
        cancelButton.showsTouchWhenHighlighted = true
        
        return cancelButton
    }
    
    func getTextView (placeholder: String) -> UITextView {
        let textView = UITextView()
        textView.placeholder = placeholder
        textView.placeholderColor = Dark.coolGrey900.dark(.lightGray)
        textView.textColor = Dark.coolGrey900.dark(.white)
        textView.backgroundColor = .clear
        textView.font = CustomFontBook.Regular.of(size: .small)
        textView.isScrollEnabled = false
        
        return textView
    }
    
    private func setupUI (superview: UIView) {
        self.layer.zPosition = 5
        let addButton = Style.largeButton(with: "Create", backgroundColor: .black, fontColor: .white)
        addButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        addButton.showsTouchWhenHighlighted = true
        addButton.backgroundColor = UIColor.EZRemember.mainBlue
        addButton.isEnabled = false
        addButton.alpha = 0.2
        
        self.addButton = addButton
        
        // The cancel button
        let cancelButton = self.cancelButton(card: self, superview: superview)
//        let veryLightGrayColor = UIColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1.0)
        cancelButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        cancelButton.setTitleColor(UIColor.EZRemember.lightRedButtonText, for: .normal)
        cancelButton.backgroundColor = UIColor.EZRemember.lightRed
        
        // Enter headword
        let titleTextView = self.getTextView(placeholder: "What would you like to learn? A word? A phrase? Anything else?")

        // Enter description or content
        let descriptionTextView = self.getTextView(placeholder: "Enter notes, a definition, a translation, etc...")
                                    
        self
            .addRow(columns: [
                Column(cardSet:
                    Style.label(
                        withText: "Create a Notification",
                        superview: nil,
                        color: UIColor.black.dark(.white))
                        .font(CustomFontBook.Medium.of(size: .large))
                            .toCardSet()
                            .margin.left(30)
                            .margin.right(30)
                            .margin.top(30),
                                xsColWidth: .Twelve),
                
                // TITLE
                Column(cardSet: titleTextView
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30),
                       xsColWidth: .Twelve),
                
                // DESCRIPTION
                Column(cardSet: descriptionTextView
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30),
                       xsColWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: addButton
                    .radius(radius: 25)
                    .addShadow()
                    .toCardSet()
                    .margin.top(50)
                    .margin.left(30)
                    .margin.right(30)
                    .withHeight(50.0), xsColWidth: .Twelve).forSize(.md, .Six).forSize(.xl, .Three),
                Column(cardSet: cancelButton
                .addShadow()
                .radius(radius: 25)
                .toCardSet()
                .margin.left(30)
                .margin.right(30)
                .margin.bottom(30)
                .withHeight(50.0), xsColWidth: .Twelve).forSize(.md, .Six).forSize(.xl, .Three)
            ], anchorToBottom: true)
                
        self.firstTextView = titleTextView
        self.descriptionTextView = descriptionTextView
        self.firstTextView?.delegate = self
        self.descriptionTextView?.delegate = self
        self.cancelButton = cancelButton
    }
}

public class GRCreateNotificationViewController: UIViewController {
    
    weak var mainView:GRViewWithScrollView?
    
    let disposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "")
        self.mainView?.navBar.isHidden = true
        self.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.mainView?.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.draw()
    }
    
    func draw () {
        guard let mainView = self.mainView else { return }
        let createNotifCard = GRCreateNotificationCard(superview: mainView.containerView)
        createNotifCard.addToSuperview(superview: mainView.containerView, viewAbove: nil, anchorToBottom: true)
        mainView.updateScrollViewContentSize()
        
        createNotifCard.cancelButton?.addTargetClosure { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        createNotifCard.addButton?.addTargetClosure(closure: { [weak self] (_) in
                                            
            guard
                let self = self,
                let title = createNotifCard.firstTextView?.text,
                let description = createNotifCard.descriptionTextView?.text
                else { return }
            
            
            // Get this device's unique identifier
            let deviceId = UtilityFunctions.deviceId()
            // Show that the notificatino is saving
            let activityIndicatorView = createNotifCard.addButton?.showLoadingNVActivityIndicatorView()
            
            let notifManager = NotificationsManager()
            notifManager.saveNotification(
                title: title,
                description: description,
                // there's no way that the device Id will be null since if it's not set initially we give it a value
                deviceId: deviceId).subscribe { (event) in
                    
                    createNotifCard.addButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: activityIndicatorView)
                    
                    if let notification = event.element, let unwrappedNotification = notification {
//                        self.notifications.append(unwrappedNotification)
//                        self.notificationsRelay.accept(self.notifications)
//                        createNotifCard.slideUpAndRemove(superview: view)
                    }
                    
                    if let _ = event.error {
                        // Handle error
                    }
            }.disposed(by: self.disposeBag)
        })
    }
    
    
    
}

