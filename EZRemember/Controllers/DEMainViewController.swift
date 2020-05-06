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

class DEMainViewController: UIViewController {
    
    weak var mainView:GRViewWithTableView?
    
    let disposeBag = DisposeBag()
    
    let notificationsRelay = BehaviorRelay(value: [Notification]())
    
    var notifications = [Notification]()
    
    var maxNumOfCards = 5        
    
    private func handleToggleActivateCard (card: GRNotificationCard) {
        
        card.toggleActivateButton?.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let notification = card.notification else { return }
            
            // We need to check first to make sure that the user hasn't hit their max number of notifications if
            // they're trying to activate a notification right now
            if (card.notification?.active == false) {
                let activeNotifications = self.notifications.filter({ $0.active == true })
                
            } else {
                card.notification?.active = !notification.active
            }
        }
    }
    
    private func showMaxNumberOfCardsHit () {
        
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
    
    /// Add a card at the to of the screen that will serve as a header, and say "Your Notifications"
    func addYourNotificationsCard () -> UIView {
        let headerCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: true)
            .addRow(columns: [Column(
                cardSet: Style.label(withText: "Your\nNotifications", superview: nil, color: .black)
                    .font(CustomFontBook.Regular.of(size: .logo))
                        .toCardSet(), colWidth: .Twelve)
            ], anchorToBottom: true)
        
        headerCard.isUserInteractionEnabled = false
        headerCard.layer.zPosition = -5
        
        headerCard.addToSuperview(superview: self.view, viewAbove: self.mainView?.navBar, anchorToBottom: false)
        return headerCard
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getMaxNumOfCardsFromServer()
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "Notifications", rightNavBarButtonTitle: "")
                
        let yourNotificationsCard = self.addYourNotificationsCard()
        guard let mainView = self.mainView else { return }
        
        self.mainView?.tableView.snp.remakeConstraints({ (make) in
            make.left.equalTo(mainView)
            make.right.equalTo(mainView)
            make.top.equalTo(yourNotificationsCard.snp.bottom)
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
    func subscribeToNotificationsObservable (notificationsObservable: Observable<[Notification]>, loading: NVActivityIndicatorView?) {
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
                    let title = createNotifCard.titleTextField?.text,
                    let description = createNotifCard.descriptionTextView?.text
                    else { return }
                
                // Get this device's unique identifier
                let deviceId = UtilityFunctions.deviceId()
                // Show that the notificatino is saving
                let activityIndicatorView = createNotifCard.addButton?.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.saveNotification(
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
