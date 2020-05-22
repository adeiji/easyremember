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


public class GRViewWithCollectionView:GRBootstrapElement {
    
    weak var collectionView:UICollectionView?    
    
    public func setup(superview:UIView, columns: CGFloat, header:String? = nil, addNavBar:Bool = false) -> GRViewWithCollectionView {
         
        // Set the flow layout of the collection view
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical        
        
        let collectionView = UICollectionView(frame: superview.frame, collectionViewLayout: flowLayout)
                        
        if let header = header {
            self.addRow(columns: [
                Column(cardSet: Style.largeCardHeader(text: header, superview: self, viewAbove: nil)
                    .toCardSet()
                    .margin.top(40),
                       xsColWidth: .Twelve)
            ])
        }
        
        self.addRow(columns: [
            Column(cardSet: collectionView
                .toCardSet()
                .margin.top(20),
                   xsColWidth: .Twelve,
                   anchorToBottom: true)
        ], anchorToBottom: true)
        collectionView.alwaysBounceVertical = true
        self.collectionView = collectionView
                    
        return self
    }
}

class DEMainViewController: UIViewController, ShowEpubReaderProtocol, CardClickedProtocol, AddHelpButtonProtocol {
    
    var explanation: Explanation = Explanation(sections: [
        ExplanationSection(content:
    """
    The key to learning anything is repetition.  Repetition is what makes a skill or knowledge become second nature.  Spaced repetition provides an increase of 30% to your retention rate.  This application uses notifications to help you learn skills permanently and naturally.  How do we do this?

    We help you to be consistent by sending you constistant reminders.  But the reminders are not reminders for you to open the app, instead, whatever you want to remember is sent as a notification.  You can then read through that notification without having to open the app.

    Once you've remembered a notification, you simply delete it.
    """
    , title: "Never forget anything",
      image: ImageHelper.image(imageName: "brain-white", bundle: "EZRemember"))
        ])
    
    var bookName: String
    
    var wordsToTranslate: String?
    
    var translateWordButton: UIButton?    
    
    /// The container which holds our epub reader
    var readerContainer: FolioReaderContainer?
    
    weak var mainView:GRViewWithCollectionView?
    
    let disposeBag = DisposeBag()
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "a", modifierFlags: .command, action: #selector(addButtonPressed)),
            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(assignFirstResponderToSearchBar))            
        ]
    }
    
    var notifications = [GRNotification]() {
        didSet {
            let userDefaults = UserDefaults.standard
            if self.notifications.count == 0 {
                userDefaults.set(true, forKey: Keys.UserDefaults.kNoNotifications)
            } else {
                userDefaults.set(false, forKey: Keys.UserDefaults.kNoNotifications)
            }
            
            userDefaults.synchronize()
        }
    }
    
    weak var collectionHeaderView:NotificationsHeaderCell? {
        didSet {
            self.handleSearch(searchBar: self.collectionHeaderView?.searchBar)
            self.handleTagPressed(tagPressed: self.collectionHeaderView?.tagPressed)
        }
    }
    
    var allNotifications = [GRNotification]() {
        didSet {
            // If there are no notifications AT ALL on this device, than don't show the collection view's header
            // because it will overlap the empty collection view background view
            if self.allNotifications.count == 0 {
                self.collectionHeaderView?.isHidden = true
                self.showEmptyCollectionView()
            } else {
                self.collectionHeaderView?.isHidden = false
                self.mainView?.collectionView?.reset()
            }
        }
    }
    
    var maxNumOfCards = 5
    
    var unfinishedNotification:GRNotification?
    
    @objc func assignFirstResponderToSearchBar () {
        self.collectionHeaderView?.searchBar?.becomeFirstResponder()
    }
        
    /// If there is an initial book url that should be displayed at the start of the app, ie. this app is opening due to a user selecting this
    /// app as the "Open In" for an ePub
    init() {
        self.bookName = ""
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleToggleActivateCard (card: GRNotificationCard) {
        
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
                }
        }.disposed(by: self.disposeBag)
    }
    
    private func showMaxNumberOfCardsHit () {
        
        let card = GRMessageCard(color: .white, anchorWidthToScreenWidth: true)

        card
        .draw(
            message: "You have already reached your maximum active notifications of \(self.maxNumOfCards).  Please deactivate another card first, or increase your maximum activate notifications on the 'Schedule' page",
            title: "Maximum Active Cards Reached",
            buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan),
            superview: self.view)
        
        card.backgroundColor = UIColor.white.dark(Dark.coolGrey700)
        
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
            
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func notificationsSavedToServer (_ notification: Notification) {
        guard let notifications = notification.userInfo?[GRNotification.kSavedNotifications] as? [GRNotification] else { return }
        self.addNotifications(notifications, atBeginning: true)
    }
    
    private func addObservers () {
        NotificationCenter.default.addObserver(self, selector: #selector(maxNumCardsUpdated(_:)), name: .UserUpdatedMaxNumberOfCards, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationsSavedToServer(_:)), name: .NotificationsSaved, object: nil)
    }
    
    private func showEpubOpenedInApp (url: URL) {
        self.showBookReader(url: url)
    }
    
    func addAddButton () -> UIButton {
        
        let button = UIButton()
        self.mainView?.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.right.equalTo(self.mainView ?? self.view).offset(-20)
            make.top.equalTo(self.mainView ?? self.view).offset(Style.isIPhoneX() ? 40 : 20)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
        
        button.setImage(UIImage(named: "add"), for: .normal)
        return button
        
    }
    
    private func initialSetupCollectionView () {
        guard let collectionView = self.mainView?.collectionView else { return }
        collectionView.register(NotificationsHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NotificationsHeaderCell.reuseIdentifier)
        collectionView.register(GRNotificationCard.self, forCellWithReuseIdentifier: GRNotificationCard.reuseIdentifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .clear
        
        self.setupTapCollectionView(collectionView: collectionView)
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        if self.mainView != nil { return }
                        
        let mainView = GRViewWithCollectionView().setup(superview: self.view, columns: 3)
        mainView.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.coolGrey900)
        mainView.addToSuperview(superview: self.view, viewAbove: nil, anchorToBottom: true)
        self.mainView = mainView
        
        self.initialSetupCollectionView()
        
        // If this device has a device Id set, which all should
        let deviceId = UtilityFunctions.deviceId()
        
        // Get all the notifications for this device from the server
        let notificationsObservable = NotificationsManager.getNotifications(deviceId: deviceId)
        
        // Show that there is data loading
        let loading =  self.view.showLoadingNVActivityIndicatorView()
        
        let addButton = self.addAddButton()
        self.setupAddButton(addButton: addButton)
        
        self.addHelpButton(addButton, superview: mainView)
        
        self.subscribeToNotificationsObservable(notificationsObservable: notificationsObservable, loading: loading)
        
        self.promptForAllowNotifications()
        
    }
    
    fileprivate func promptForAllowNotifications () {
        if (UtilityFunctions.isFirstTime("opening the main view controller")) {
            let messageCard = GRMessageCard()
            messageCard.draw(message: "Enabling notifications is very important.  They are what will really help you to remember the information on the cards that you create.  This app relies heavily on notifications.  Please enable them now, so you can fully benefit from the app.", title: "Please Enable Notifications", superview: self.view, buttonText: "Enable Notifications", cancelButtonText: "Don't Enable - Not recommended")
            
            messageCard.okayButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let _ = self else { return }
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.setupRemoteNotifications(application: UIApplication.shared)
                messageCard.close()
            })
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
        self.getMaxNumOfCardsFromServer()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.mainView?.setNeedsLayout()
        self.mainView?.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    private func handleTagPressed (tagPressed: PublishSubject<String>?) {
        tagPressed?.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let tag = event.element else { return }
                                                
            switch tag {
            case "All":
                self.notifications = self.allNotifications
            case "Active":
                self.notifications = self.allNotifications.filter({ $0.active == true })
            case "Inactive":
                self.notifications = self.allNotifications.filter({ $0.active == false })
            default:
                self.notifications = self.allNotifications.filter({ $0.tags?.contains(tag) == true })
            }
            
            self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
        }.disposed(by: self.disposeBag)
    }
    
    private func handleSearch (searchBar: UITextField?) {
        
        searchBar?.rx.text.orEmpty
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .skip(1)
            .distinctUntilChanged()
            .subscribe({ [weak self] (event) in
                guard let self = self else { return }
                guard let text = event.element else { return }
                
                if text == "" {
                    self.notifications = self.allNotifications
                    self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                } else {
                    self.notifications = self.allNotifications.filter({
                        $0.bookTitle?.contains(text) == true ||
                            $0.caption.contains(text) == true ||
                            $0.description.contains(text) == true ||
                            $0.language?.contains(text) == true
                    })
                    
                    var indexPathsToRemove = [IndexPath]()
                    
                    for index in self.notifications.count..<self.allNotifications.count {
                        let indexPath = IndexPath(row: index, section: 0)
                        indexPathsToRemove.append(indexPath)
                    }
                    
                    self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                }
            }).disposed(by: self.disposeBag)
    }
    
    /**
     If the notifications relay contains zero elements than we need to display the no data view on the Table View
     */
    func showEmptyCollectionView () {
        let actionButton = self.mainView?.collectionView?.setEmptyMessage(
            message: "Looks like you haven't added any notifications yet on this device.  Let's add a notification now", header: "Add a Notification", imageName: "interface")
        self.setupAddButton(addButton: actionButton)
    }
    
    /**
        Subscribe to an observable which will return notifications from the server
     */
    func subscribeToNotificationsObservable (notificationsObservable: Observable<[GRNotification]>, loading: NVActivityIndicatorView?) {
        notificationsObservable.subscribe { [weak self] (event) in
            guard let self = self else { return }
                                    
            if let error = event.error {
                self.view.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            }
            
            if event.isCompleted {
                self.view.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                self.notifications = self.notifications.sorted(by: { $0.creationDate > $1.creationDate })
                if self.notifications.count > 0 {
                    self.mainView?.collectionView?.reset()
                } else {
                    self.allNotifications = []
                }
            }
            
            if let notifications = event.element, notifications.count > 0 {
                self.addNotifications(notifications)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func addNotifications (_ notifications: [GRNotification], atBeginning:Bool = false) {
        
        if atBeginning {
            self.notifications.insert(contentsOf: notifications, at: 0)
            self.allNotifications.insert(contentsOf: notifications, at: 0)
            return
        }
        
        self.notifications.append(contentsOf: notifications)
        self.allNotifications.append(contentsOf: notifications)
        
        self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    func removeNotification (notificationId: String) {
        self.notifications.removeAll(where: { $0.id == notificationId })
        self.allNotifications.removeAll(where: { $0.id == notificationId })
    }
    
    func setupNotificationCellDeleteButton (cell: GRNotificationCard) {
        
        // User presses the delete button
        cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            
            let deleteCard = DeleteCard(color: UIColor.white.dark(Dark.coolGrey700), anchorWidthToScreenWidth: true)
            deleteCard.draw(superview: self.view)
            deleteCard.cancelButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let _ = self else { return }
                deleteCard.close()
            })
            
            deleteCard.okayButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                guard let notificationId = cell.notification?.id else
                {
                    assertionFailure("Baaka, why is the notification Id not set for this cell.  That should not be possible.  Check to make sure you're setting this value to whatever the notification is for this cell.")
                    return
                }
                                                
                let loading = deleteCard.okayButton?.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.deleteNotificationWithId(notificationId)
                    .subscribe { [weak self] (event) in
                        guard let self = self else { return }
                        
                        deleteCard.okayButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                        
                        // If deleted successfully
                        if event.element == true {
                            // Delete the notification from the server and remove it from the app
                            deleteCard.close()
                            self.removeNotification(notificationId: notificationId)
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
                let self = self
            else { return }
            
            self.addButtonPressed()
        })
    }
    

    @objc func addButtonPressed () {
        let createNotifVC = GRCreateNotificationViewController(notification: self.unfinishedNotification)
        createNotifVC.publishNotification.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let notification = event.element else { return }
            self.addNotifications([notification], atBeginning: true)
        }.disposed(by: self.disposeBag)
        
        createNotifVC.unfinishedNotification.subscribe { [weak self] (event) in
            guard let self = self else { return }
            self.unfinishedNotification = event.element
        }.disposed(by: self.disposeBag)
        
        self.present(createNotifVC, animated: true, completion: nil)
    }
}
