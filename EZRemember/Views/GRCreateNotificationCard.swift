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

class Autocomplete: GRBootstrapElement {
    
    let selectedItem = PublishSubject<String>()
    
    let items:[String]
    
    init(items: [String], superview: UIView) {
        self.items = items
        super.init(color: UIColor.white.dark(Dark.coolGrey200), anchorWidthToScreenWidth: false, margin: BootstrapMargin(left: .Zero, top: .One, right: .Zero, bottom: .Zero), superview: superview)
        self.draw(superview: superview)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func draw (superview: UIView) {
        
        var columns = [Column]()
        self.items.forEach { [weak self] (item) in
            guard let _ = self else { return }
            let itemButton = Style.largeButton(with: item, backgroundColor: .clear, fontColor: UIColor.black)
            columns.append(Column(cardSet: itemButton.toCardSet(), xsColWidth: .Twelve))
            itemButton.addTargetClosure { [weak self] (itemButton) in
                guard let self = self else { return }
                self.selectedItem.onNext(itemButton.title(for: .normal) ?? "")
            }
        }
        
        self.addRow(columns: columns, anchorToBottom: true)
        self.addToSuperview(superview: superview, anchorToBottom: true)
    }
    
}

protocol AutocompleteProtocol {
    
}

class GRCreateNotificationCard: GRBootstrapElement, UITextViewDelegate, UITextFieldDelegate {
    
    /// The done button for this card
    weak var addButton:UIButton?
    
    weak var firstTextView:UITextView?
    
    weak var descriptionTextView:UITextView?
    
    weak var cancelButton:UIButton?
    
    weak var tagTextField:UITextField?
    
    var notification:GRNotification?
    
    let disposeBag = DisposeBag()
    
    weak var autocompleteView:UIView?
    
    func textViewDidChange(_ textView: UITextView) {
        if (self.firstTextView?.text.trimmingCharacters(in: .whitespaces) == ""
            && self.descriptionTextView?.text.trimmingCharacters(in: .whitespaces) == "") {
            self.addButton?.isEnabled = false
            self.addButton?.alpha = 0.2
        } else {
            self.addButton?.isEnabled = true
            self.addButton?.alpha = 1.0
        }
    }
    
    init(superview: UIView, notification: GRNotification? = nil) {
        super.init(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: true, superview: superview)
        self.notification = notification
        self.setupUI(superview: superview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelButton (card:GRBootstrapElement, superview: UIView) -> UIButton {
        let cancelButton = Style.largeButton(with: NSLocalizedString("cancel", comment: "generic cancel text"), backgroundColor: .red, fontColor: .white)
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let character = text.first, character == "\t" {
            if textView == self.firstTextView {
                self.descriptionTextView?.becomeFirstResponder()
            } else if textView == self.descriptionTextView {
                self.tagTextField?.becomeFirstResponder()
            }
            
            return false
        }
        
        return true
    }
    
    private func showAutocomplete (tags: [String]) {
        let autocompleteView = UIView()
        
        self.addSubview(autocompleteView)
        
        autocompleteView.snp.makeConstraints { (make) in
            make.left.equalTo(self.tagTextField ?? self)
            make.top.equalTo(self.tagTextField?.snp.bottom ?? self)
            make.right.equalTo(self.tagTextField ?? self)
        }
        
        let autoComplete = Autocomplete(items: tags, superview: autocompleteView)
        
        autoComplete.selectedItem.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let tag = event.element {
                self.tagTextField?.text = tag
            }
        }.disposed(by: self.disposeBag)
        autocompleteView.layer.zPosition = 5
        self.autocompleteView = autocompleteView
    }
    
    
    @objc func textFieldDidChange (_ textField: UITextField) {
        guard let text = textField.text else { return }
        self.autocompleteView?.removeFromSuperview()
        if text.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            if var tags = UtilityFunctions.getTags() {
                tags = tags.filter({ $0.contains(text) })
                if tags.count > 0 {
                    self.showAutocomplete(tags: tags)
                }
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        textField.backgroundColor = .clear
        if var tags = UtilityFunctions.getTags() {
            tags = tags.filter({ $0.contains(text) })
            if tags.count > 0 {
                self.showAutocomplete(tags: tags)
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.autocompleteView?.removeFromSuperview()
        
        if textField.text == "" {
            textField.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.coolGrey700)
        }
    }
    
    private func setupUI (superview: UIView) {
        self.layer.zPosition = 5
        let addButton = Style.largeButton(with: NSLocalizedString("save", comment: "generic save text throughout the app"), backgroundColor: .black, fontColor: .white)
        addButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        addButton.showsTouchWhenHighlighted = true
        addButton.backgroundColor = UIColor.EZRemember.mainBlue
        addButton.isEnabled = self.notification == nil ? false : true
        addButton.alpha = self.notification == nil ? 0.2 : 1.0
        
        self.addButton = addButton
        
        // CANCEL BUTTON
        
        let cancelButton = self.cancelButton(card: self, superview: superview)
        //        let veryLightGrayColor = UIColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1.0)
        cancelButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        cancelButton.setTitleColor(UIColor.EZRemember.lightRedButtonText, for: .normal)
        cancelButton.backgroundColor = UIColor.EZRemember.lightRed
        
        // Enter headword
        let titleTextView = self.getTextView(placeholder: NSLocalizedString("enterCaption", comment: "Enter caption..."), text: self.notification?.caption)
        
        // Enter description or content
        let descriptionTextView = self.getTextView(placeholder: NSLocalizedString("enterDetails", comment: "Enter details..."), text: self.notification?.description)
        
        let tagTextField = Style.wideTextField(withPlaceholder: NSLocalizedString("tag", comment: "+ Tag"), superview: nil, color: Dark.coolGrey900.dark(.white))
        
        tagTextField.text = self.notification?.tags?.first
        tagTextField.radius(radius: 25)
        tagTextField.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.coolGrey700)
        tagTextField.font = CustomFontBook.Regular.of(size: .small)
        tagTextField.delegate = self
        tagTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
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
                       xsColWidth: .Twelve),
                
            ]).addRow(columns: [
                // TAG TEXT FIELD
                Column(cardSet: tagTextField
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30), xsColWidth: .Eight)
            ])
            .addRow(columns: [
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
        self.tagTextField = tagTextField
        self.descriptionTextView?.delegate = self
        self.cancelButton = cancelButton
    }
}

public class GRNotificationViewController: UIViewController {
    
    /// The main view displaying all the information on this screen
    weak var mainView:GRViewWithScrollView?
    
    /// Used to dispose of our Rx observables
    let disposeBag = DisposeBag()
    
    /// The current notification that is being updated or created
    var notification:GRNotification?
    
    /// Emits the notification that was created on this screen
    let publishNotification = PublishSubject<GRNotification>()
    
    /**
     Emits the notification that was not finished if this screen is dismissed by a scroll down (most likely unintionally)
     */
    let unfinishedNotification = PublishSubject<GRNotification>()
    
    /**
     The card that displays the create notification information
     */
    weak var createNotifCard:GRCreateNotificationCard?
    
    /**
     If the user closes the view controller by scrolling down (probably accidentally), then we need to save the notification so that they don't accidentally lose their information.  That's why this is set to true by default.
     
     Once a notification is saved or updated tho, than we don't need to have this save protection so this variable can than be set to false.
     */
    var shouldSaveUnfinishedNotification = true
    
    /** Whether the current card is an existing card being edited or is a new card */
    private var isEditingCard = false
    
    /** If the user is creating this card from reading a book than store the book title */
    var bookName:String?
    
    /** These are the keyboard shortcuts*/
    public override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(saveButtonPressed)),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(close))
        ]
    }
    
    @objc private func close () {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     - parameters:
        - notification: The initial notification.  Set this if you're editing a notification
        - isEditingCard: Whether you're editing a card or not
     
     - TODO: We need to decide whether we should just set isEditingCard to true if a notification is sent on initialization
     */
    init(notification: GRNotification? = nil, isEditingCard:Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.notification = notification
        self.isEditingCard = isEditingCard
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.mainView != nil { return }
        
        self.mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "")
        self.mainView?.navBar?.isHidden = true
        self.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.mainView?.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        
        self.draw()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        // If upon dismissing of this screen by scrolling down, (accidentally) we need to save the unsaved notification so that the user does not lose their information if this dismissal was unintentional
        if self.shouldSaveUnfinishedNotification == true {
            var notification = GRNotification(caption: self.createNotifCard?.firstTextView?.text ?? "", description: self.createNotifCard?.descriptionTextView?.text ?? "")
            if let tag = self.createNotifCard?.tagTextField?.text {
                notification.tags = [tag]
            }
            // Emit the newly created unsaved notification
            self.unfinishedNotification.onNext(notification)
        } else {
            self.unfinishedNotification.onCompleted()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc func saveButtonPressed () {
        
        guard
            let title = self.createNotifCard?.firstTextView?.text,
            let description = self.createNotifCard?.descriptionTextView?.text
            else { return }
        
        var tags:[String]?
        
        if let text = self.createNotifCard?.tagTextField?.text, text.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            tags = [text]
            UtilityFunctions.addTags(newTags: [text])
        }
        
        self.notification?.caption = title
        self.notification?.description = description
        self.notification?.tags = tags
        self.notification?.bookTitle = self.bookName
        
        // Get this device's unique identifier
        let deviceId = UtilityFunctions.deviceId()
        
        // Show that the notification is saving
        let activityIndicatorView = self.createNotifCard?.addButton?.showLoadingNVActivityIndicatorView()
        
        let notifManager = NotificationsManager()
        
        if let _ = self.notification {
            self.updateNotification {
                // This notification is no longer considered unsaved, so we don't have to worry about the user accidentally closing this screen
                self.shouldSaveUnfinishedNotification = false
                self.createNotifCard?.addButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: activityIndicatorView)
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        
        notifManager.saveNotification(
            title: title,
            description: description,
            deviceId: deviceId,
            tags: tags).subscribe { (event) in
                self.createNotifCard?.addButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: activityIndicatorView)
                if event.isCompleted {
                    return
                }
                
                if let _ = event.error {
                    GRMessageCard().draw(message: NSLocalizedString("savingNotificationError", comment: "problem saving your notification"), title: NSLocalizedString("tryAgain", comment: "Try Again"), superview: self.view)
                    return
                }
                
                if let unwrappedNotification = event.element, let notification = unwrappedNotification {
                    self.shouldSaveUnfinishedNotification = false
                    self.dismiss(animated: true, completion: nil)
                    self.publishNotification.onNext(notification)
                }
                
        }.disposed(by: self.disposeBag)
        
    }
    
    fileprivate func userHasInputedData () -> Bool {
        return
            self.createNotifCard?.tagTextField?.text?.trimmingCharacters(in: .whitespaces) != "" ||
            self.createNotifCard?.firstTextView?.text?.trimmingCharacters(in: .whitespaces) != "" ||
            self.createNotifCard?.descriptionTextView?.text?.trimmingCharacters(in: .whitespaces) != ""
    }
    
    fileprivate func stopEditing () {
        self.createNotifCard?.tagTextField?.resignFirstResponder()
        self.createNotifCard?.firstTextView?.resignFirstResponder()
        self.createNotifCard?.descriptionTextView?.resignFirstResponder()
    }
    
    func draw () {
        guard let mainView = self.mainView else { return }
        let createNotifCard = GRCreateNotificationCard(superview: mainView.containerView, notification: self.notification)
        createNotifCard.addToSuperview(superview: mainView.containerView, viewAbove: nil, anchorToBottom: true)
        mainView.updateScrollViewContentSize()
        createNotifCard.addButton?.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        createNotifCard.firstTextView?.becomeFirstResponder()
        
        createNotifCard.cancelButton?.addTargetClosure { (_) in
            
            if self.userHasInputedData(){
                
                let cancelCard = GRMessageCard()
                
                // Resign all the responders for the text field so that the keyboard goes away
                self.stopEditing()
                
                // If this screen was shown because the user is editing a card, than we don't want to show the dialog about them losing their information, since the information will not change unless they click the save button
                if (self.isEditingCard == false) {
                    cancelCard.draw(message: NSLocalizedString("loseDataWarning", comment: "Unsaved data warning"), title: NSLocalizedString("areYouSure", comment: "Generic - Are you sure? - throughout the app"), superview: mainView, cancelButtonText: NSLocalizedString("finishWritingCard", comment: "Finish Writing Card"))
                    
                    cancelCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
                        guard let self = self else { return }
                        self.shouldSaveUnfinishedNotification = false
                        self.dismiss(animated: true, completion: nil)
                    })
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
                
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        self.createNotifCard = createNotifCard
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
                    message: NSLocalizedString("problemUpdatingCard", comment: "There was a problem updating your card"),
                    title: NSLocalizedString("areYouSure", comment: "generic Are You Sure?"), buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan),
                    superview: self.view, buttonText: "Okay", isError: true)
            } else {
                self.dismiss(animated: true, completion: nil)
                self.publishNotification.onNext(notification)
            }
        }.disposed(by: self.disposeBag)
        
        return
    }
}

