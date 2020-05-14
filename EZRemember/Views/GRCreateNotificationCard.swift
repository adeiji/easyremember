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
    
    var notification:GRNotification?
    
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
    
    init(superview: UIView, notification: GRNotification? = nil) {
        super.init(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: true)
        self.notification = notification
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
    
    func getTextView (placeholder: String, text: String? = nil) -> UITextView {
        let textView = UITextView()
        textView.text = text
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
        let addButton = Style.largeButton(with: "Save", backgroundColor: .black, fontColor: .white)
        addButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        addButton.showsTouchWhenHighlighted = true
        addButton.backgroundColor = UIColor.EZRemember.mainBlue
        addButton.isEnabled = self.notification == nil ? false : true
        addButton.alpha = self.notification == nil ? 0.2 : 1.0
        
        self.addButton = addButton
        
        // The cancel button
        let cancelButton = self.cancelButton(card: self, superview: superview)
//        let veryLightGrayColor = UIColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1.0)
        cancelButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        cancelButton.setTitleColor(UIColor.EZRemember.lightRedButtonText, for: .normal)
        cancelButton.backgroundColor = UIColor.EZRemember.lightRed
        
        // Enter headword
        let titleTextView = self.getTextView(placeholder: "Enter caption...", text: self.notification?.caption)

        // Enter description or content
        let descriptionTextView = self.getTextView(placeholder: "Enter details...", text: self.notification?.description)
                                    
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
    
    var notification:GRNotification?
    
    let publishNotification = PublishSubject<GRNotification>()
    
    init(notification: GRNotification? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.notification = notification
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        let createNotifCard = GRCreateNotificationCard(superview: mainView.containerView, notification: self.notification)
        createNotifCard.addToSuperview(superview: mainView.containerView, viewAbove: nil, anchorToBottom: true)
        mainView.updateScrollViewContentSize()
        
        createNotifCard.cancelButton?.addTargetClosure { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        createNotifCard.addButton?.addTargetClosure(closure: { [weak self] (addButton) in
                                            
            guard
                let self = self,
                let title = createNotifCard.firstTextView?.text,
                let description = createNotifCard.descriptionTextView?.text
                else { return }
            
            self.notification?.caption = title
            self.notification?.description = description
            
            // Get this device's unique identifier
            let deviceId = UtilityFunctions.deviceId()
            
            // Show that the notification is saving
            let activityIndicatorView = addButton.showLoadingNVActivityIndicatorView()
                     
            let notifManager = NotificationsManager()
            
            if let _ = self.notification {
                self.updateNotification {
                    addButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: activityIndicatorView)
                }
                return
            }
            
            notifManager.saveNotification(
                title: title,
                description: description,
                
                // There's no way that the device Id will be null since if it's not set initially we give it a value
                deviceId: deviceId).subscribe { (event) in
                    addButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: activityIndicatorView)
                    if event.isCompleted {
                        return
                    }
                    
                    if let _ = event.error {
                        GRMessageCard().draw(message: "There was a problem saving your notification.  Please try again", title: "Try Again", superview: self.view)
                        return
                    }
                    
                    if let unwrappedNotification = event.element, let notification = unwrappedNotification {
                        self.dismiss(animated: true, completion: nil)
                        self.publishNotification.onNext(notification)
                    }
                                                            
            }.disposed(by: self.disposeBag)
        })
    }
    
    func updateNotification (completion: @escaping () -> Void) {
        
        let notifManager = NotificationsManager()
        
        guard let notification = self.notification else { return }
        
        notifManager.updateNotification(notification: notification).subscribe { [weak self] (event) in
            guard let self = self else { return }
            completion()
            if event.element == false {
                let messageCard = GRMessageCard()
                
                messageCard.draw(
                    message: "There was a problem updating your card.  Please try again.",
                    title: "Try Again", buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan),
                    superview: self.view, buttonText: "Okay", isError: true)
            } else {
                self.dismiss(animated: true, completion: nil)
                self.publishNotification.onNext(notification)
            }
        }.disposed(by: self.disposeBag)
        
        return
    }
}

