//
//  DEMainViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import DephynedFire
import SwiftyBootstrap
import RxSwift
import RxCocoa
import NVActivityIndicatorView
import FolioReaderKit


class DEMainViewController: UIViewController, ShowEpubReaderProtocol {
    
    weak var mainView:GRViewWithTableView?
    
    let disposeBag = DisposeBag()
    
    let notificationsRelay = BehaviorRelay(value: [GRNotification]())
    
    var notifications = [GRNotification]()
    
    var maxNumOfCards = 5
        
    /// If there is an initial book url that should be displayed at the start of the app, ie. this app is opening due to a user selecting this
    /// app as the "Open In" for an ePub
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func handleToggleActivateCard (card: GRNotificationCard) {
        
        card.toggleActivateButton?.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
                        
            // We need to check first to make sure that the user hasn't hit their max number of notifications if
            // they're trying to activate a notification right now
            if (card.notification?.active == false) {
                let activeNotifications = self.notifications.filter({ $0.active == true })
                if activeNotifications.count >= self.maxNumOfCards {
                    self.showMaxNumberOfCardsHit()
                } else {
                    self.updateNotificationActive(notification: card.notification, card: card, isActive: true)
                }
            } else {
                self.updateNotificationActive(notification: card.notification, card: card, isActive: false)
            }
        }
    }
    
    /**
     Given a notification, we set it to either active or inactive, then we save it to the server and after that
     update the view to reflect the new notifications active state
     
     - parameters:
        - notification:The notification to be updated
        - card: The card which contains the notification
        - isActive: Whether or not this updated to have an active or an inactive state
     */
    private func updateNotificationActive (notification: GRNotification?, card:GRNotificationCard, isActive: Bool) {
        
        guard let notification = notification else { return }
        
        // Show that an activity is going on in the background
        let loading =  card.toggleActivateButton?.showLoadingNVActivityIndicatorView()
        // Save the new active state to the server
        NotificationsManager.toggleActiveNotification(notificationId: notification.id, active: isActive)
            .subscribe { [weak self] (event) in
                
                guard let self = self else { return }
                card.toggleActivateButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                // If there is an error saving then show it now
                if let error = event.error {
                    GRMessageCard().draw(message: "Seems like there was a problem saving your information, please try activating or deactiving this notification again", title: "Uh oh! Something is wrong...", buttonBackgroundColor: .red, superview: self.view, buttonText: "Okay", isError: true)
                    // Log the error using google analytics
                    AnalyticsManager.logError(message: error.localizedDescription)
                } else {
                    // Update the active state of the notification on it's table view cell (card) and within the local
                    // notifications array
                    card.notification?.active = isActive
                    self.updateNotificationInNotificationsArray(notification: card.notification)
                    self.notificationsRelay.accept(self.notifications)
                }
        }.disposed(by: self.disposeBag)
    }
    
    private func updateNotificationInNotificationsArray (notification:GRNotification?) {
        guard let notification = notification else { return }
        if let row = self.notifications.firstIndex(where: { $0.id == notification.id }) {
            self.notifications[row] = notification
        }
    }
    
    private func showMaxNumberOfCardsHit () {
        
        GRMessageCard(color: .white, anchorWidthToScreenWidth: true)
        .draw(
            message: "You have already reached your maximum active notifications of \(self.maxNumOfCards).  Please deactivate another card first, or increase your maximum activate notifications on the 'Schedule' page",
            title: "Maximum Active Cards Reached",
            buttonBackgroundColor: UIColor.EZRemember.mainBlue,
            superview: self.view)
        
    }
    
    /**
     If the user decides to update the max number of cards to less than then previous amount than we set all their cards to an inactive state
     */
    @objc private func maxNumCardsUpdated (_ notification: Notification) {
        
        // Get the new maximum number from the notification
        if let data = notification.userInfo {
            for (_, maxNum) in data {
                guard let maxNum = maxNum as? Int else { return }
                
                // Check to make sure that the new max number is less than the current max number
                if maxNum < self.maxNumOfCards {
                    // Set all the notifications to inactive
                    self.notifications.forEach { [weak self] (notification) in
                        guard let self = self else { return }
                        var updatedNotification = notification
                        updatedNotification.active = false
                        if notification.active == true {
                            self.updateNotificationInNotificationsArray(notification: updatedNotification)
                        }
                    }
                    
                    self.notificationsRelay.accept(self.notifications)
                }
                
                self.maxNumOfCards = maxNum
            }
        }
    }
    
    /**
     Get the max num of cards this user has selected to recieve notification cards from Firebase
     */
    private func getMaxNumOfCardsFromServer () {
        
        ScheduleManager.getMaxNumOfCards().subscribe { [weak self] (event) in
            guard let self = self else { return }
            
            if let numOfCards = event.element {
                self.maxNumOfCards = numOfCards
            }
        }.disposed(by: self.disposeBag)
        
    }
    
    /// Setup the UI for the nav bar
    func setupNavBar () {
        // Set up the navigation bar
        self.mainView?.navBar.backgroundColor = .white
        
        // Set up nav bar header
        self.mainView?.navBar.header?.textColor = .darkText
        
        // Set up nav bar right button
        self.mainView?.navBar.rightButton?.setTitleColor(UIColor.EZRemember.mainBlue, for: .normal)
        self.mainView?.navBar.rightButton?.titleLabel?.font = FontBook.allBold.of(size: .medium)
        self.mainView?.navBar.rightButton?.withImage(named: "add", bundle: "EZRemember")
    }
            
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func notificationsSavedToServer (_ notification: Notification) {
        guard let notifications = notification.userInfo?[GRNotification.kSavedNotifications] as? [GRNotification] else { return }
        self.notifications.append(contentsOf: notifications)
        self.notificationsRelay.accept(self.notifications)
    }
    
    private func addObservers () {
        NotificationCenter.default.addObserver(self, selector: #selector(maxNumCardsUpdated(_:)), name: .UserUpdatedMaxNumberOfCards, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationsSavedToServer(_:)), name: .NotificationsSaved, object: nil)
    }
    
    private func showEpubOpenedInApp (url: URL) {
        self.showBookReader(url: url)
    }
    
    func addMoreBooksButton (viewAbove: UIView) -> UIButton {
        let getMoreBooksButton = Style.largeButton(with: "Get More eBooks", superview: mainView, backgroundColor: UIColor.EZRemember.mainBlue, fontColor: .white)
        
        getMoreBooksButton.radius(radius: 10)
        
        getMoreBooksButton.snp.makeConstraints { (make) in
            make.left.equalTo(viewAbove)
            make.top.equalTo(viewAbove.snp.bottom).offset(20)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
        
        getMoreBooksButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let url = URL(string: "https://www.gutenberg.org/catalog/") else { return }
            UIApplication.shared.open(url)
        }
        
        return getMoreBooksButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
        
        self.getMaxNumOfCardsFromServer()
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "Notifications", rightNavBarButtonTitle: "")
        self.mainView?.navBar.leftButton?.isHidden = true
        guard let mainView = self.mainView else { return }
        
        let yourNotificationsCard = Style.addLargeHeaderCard(text: "Your\nNotifications", superview: self.view, viewAbove: self.mainView?.navBar)
        let getMoreBooksButton = self.addMoreBooksButton(viewAbove: yourNotificationsCard)
        
        self.mainView?.tableView.snp.remakeConstraints({ (make) in
            make.left.equalTo(mainView)
            make.right.equalTo(mainView)
            make.top.equalTo(getMoreBooksButton.snp.bottom)
            make.bottom.equalTo(mainView)
        })
                
        // Setup Navbar UI
        self.setupNavBar()
        
        self.mainView?.tableView.register(GRNotificationCard.self, forCellReuseIdentifier: GRNotificationCard.reuseIdentifier)
        guard let tableView = self.mainView?.tableView else { return }
        
        // If this device has a device Id set, which all should
        let deviceId = UtilityFunctions.deviceId()
        
        // Show that there is data loading
        let loading =  self.mainView?.showLoadingNVActivityIndicatorView()
        
        // Get all the notifications for this device from the server
        let notificationsObservable = NotificationsManager.getNotifications(deviceId: deviceId)
        
        self.handleEmptyTableViewState()
        self.bindNotificationsRelayToTableView(tableView: tableView, loading: loading)
        self.subscribeToNotificationsObservable(notificationsObservable: notificationsObservable, loading: loading)
        self.setupAddButton(addButton: self.mainView?.navBar.rightButton)

    }
    
    /**
     Bind notifications relay object to the table view
     */
    func bindNotificationsRelayToTableView (tableView: UITableView, loading: NVActivityIndicatorView?) {
        // Display the notifications on a table view
        self.notificationsRelay
            .bind(to:
                tableView
                    .rx
                    .items(cellIdentifier: GRNotificationCard.reuseIdentifier, cellType: GRNotificationCard.self)) { [weak self] (row, notification, cell) in
                        guard let self = self else { return }
                        if loading?.superview != nil {
                            // Show that the items have finished loading
                            self.mainView?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                        }
                        
                        // If the table view is showing a background view because it was empty, then reset it to it's normal state
                        self.mainView?.tableView.reset()
                        cell.viewToBaseWidthOffOf = self.mainView?.tableView
                        cell.notification = notification
                        self.setupNotificationCellDeleteButton(cell: cell)
                        self.handleToggleActivateCard(card: cell)
                        
        }.disposed(by: self.disposeBag)
    }
    
    /**
     If the notifications relay contains zero elements than we need to display the no data view on the Table View
     */
    func handleEmptyTableViewState () {
        notificationsRelay.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let notifications = event.element, notifications.count == 0 {
                let actionButton = self.mainView?.tableView.setEmptyMessage(
                    message: "Looks like you haven't added any notifications yet on this device.  Let's add a notification now", header: "Add a Notification", imageName: "interface")
                self.setupAddButton(addButton: actionButton)
            }
        }.disposed(by: self.disposeBag)
    }
    
    /**
        Subscribe to an observable which will return notifications from the server
     */
    func subscribeToNotificationsObservable (notificationsObservable: Observable<[GRNotification]>, loading: NVActivityIndicatorView?) {
        notificationsObservable.subscribe { (event) in
            if let notifications = event.element, notifications.count > 0 {
                self.notificationsRelay.accept(notifications)
                self.notifications = notifications
            } else {
                self.mainView?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func setupNotificationCellDeleteButton (cell: GRNotificationCard) {
        
        // User presses the delete button
        cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            
            let deleteCard = DeleteCard(color: .white, anchorWidthToScreenWidth: true)
            deleteCard.slideUp(superview: self.view, margin: 20)
            
            deleteCard.cancelButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                deleteCard.slideDownAndRemove(superview: self.view)
            })
            
            deleteCard.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                guard let notificationId = cell.notification?.id else
                {
                    assertionFailure("Baaka, why is the notification Id not set for this cell.  That should not be possible.  Check to make sure you're setting this value to whatever the notification is for this cell.")
                    return
                }
                                                
                let loading = deleteCard.deleteButton?.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.deleteNotificationWithId(notificationId)
                    .subscribe { [weak self] (event) in
                        guard let self = self else { return }
                        
                        deleteCard.deleteButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                        
                        // If deleted successfully
                        if event.element == true {
                            // Delete the notification from the server and remove it from the app
                            deleteCard.slideDownAndRemove(superview: self.view)
                            self.notifications.removeAll(where: { $0.id == notificationId })
                            self.notificationsRelay.accept(self.notifications)
                        }
                }.disposed(by: self.disposeBag)
            })
        })
    }
    
    /**
     This function adds all the functionality to the add button that rest in the top right corner of this screen.
     When the user presses the add button they're shown a prompt allowing them to enter a new notification and save that
     notification
     
     - parameter addButton: The button to add this functionality too.  It can be any button that you want to have that prompts the user
     to enter in a notification
     */
    func setupAddButton (addButton: UIButton?) {
        
        addButton?.addTargetClosure(closure: { [weak self] (_) in
            guard
                let self = self,
                let view = self.mainView
            else { return }
            
            let createNotifCard = GRCreateNotificationCard(superview: view)
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
                            self.notifications.append(unwrappedNotification)
                            self.notificationsRelay.accept(self.notifications)
                            createNotifCard.slideUpAndRemove(superview: view)
                        }
                        
                        if let _ = event.error {
                            // Handle error
                        }
                }.disposed(by: self.disposeBag)
            })
        })
    }
}
