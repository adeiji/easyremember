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

public class DEMainViewController: GRBootstrapViewController, ShowEpubReaderProtocol, CardClickedProtocol, AddHelpButtonProtocol, TranslationProtocol {
    
    var explanation: Explanation = Explanation(sections: [
        ExplanationSection(
            content: NSLocalizedString("repetitionExplanation", comment: "The long explanation of why repetition is important"),
            title: NSLocalizedString("repetitionExplanationTitle", comment: "The title for the explanation of why repetition is so important"),
            image: nil),
        ExplanationSection(content:
            "Notification Cards that you create will look like the one above, and they consist of 8 components.\n\n\t1. The ACTIVATE button - By default, this button will say 'Activate'. Press this button when you want to Activate or Deactivate a card. When a notification is active, we will send it to you in the form of Push Notifications.\n\t2. The REMEMBERED button - Press this button when you feel you've remembered the word or the phrase. We will no longer send you Remembered cards as push notifications. When you click the Remembered button, it will then say 'Forgot'. Click the 'Forgot' button if you feel like you've forgotten the card information, and it will start being sent as push notifications again.\n\t3. The DELETE button - Press this if you want to delete the card.\n\t4. The REMEMBERED COUNT - This is the number of times you've said you've remembered this card. (see push notifications below) Every time you select yes on the custom push notification, the Remembered count increases by one.\n\t5. Shows you when you created the card.\n\t6. The caption. It can be anything that you want when creating the card.\n\t7. The content of the card. It can be any data that you wish.\n\t8. If you saved this card from an epub in this app, this is where the title of the book you saved the card from will be. If you used the translate feature to create this card, then the language that you translated into will be one the right, where it says English."
            , title: "Notification Breakdown", image: UIImage(named: "notification-active"), largeImage: true),
        ExplanationSection(content: "Above is a basic notification sent to you based on the cards you create. You can either set the notifications to show Caption and Content, show Caption and hide Content, or Show Content and hide Caption.", title: "Simple Push Notification", image: UIImage(named: "notification-unpressed"), largeImage: false),
        ExplanationSection(content: "When on your Lock Screen, you press and hold.  When on your Home Page, you swipe down, and you'll see this view. You can then say whether you remembered this card or not. If you select 'Yes', the 'Remembered Count' will increase by 1 (see above). If you feel like you've got this card down and you don't need any more notifications, than click 'I've Mastered This Card', and it will be set as Remembered and will not be sent as a push notification anymore.", title: "Expanded Notifications", image: UIImage(named: "notification-pressed"), largeImage: true)
        ])
    
    var bookName: String
    
    var wordsToTranslate: String?
    
    var translateWordButton: UIButton?    
    
    /// The container which holds our epub reader
    var readerContainer: FolioReaderContainer?
    
    weak var mainView:GRViewWithCollectionView?
    
    let disposeBag = DisposeBag()
    
    override public var keyCommands: [UIKeyCommand]? {
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
            
            self.notificationCountLabel?.text = "\(self.notifications.count) Notifications"
        }
    }
    
    weak var collectionHeaderView:NotificationsHeaderCell? {
        didSet {
            self.handleSearch(searchBar: self.collectionHeaderView?.searchBar)
            self.handleTagPressed(tagPressed: self.collectionHeaderView?.tagPressed)
            self.notificationCountLabel = self.collectionHeaderView?.notificationCountLabel
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
    
    weak var notificationCountLabel:UILabel?
    
    var maxNumOfCards = 5
    
    var unfinishedNotification:GRNotification?
    
    @objc func assignFirstResponderToSearchBar () {
//        self.collectionHeaderView?.searchBar?.becomeFirstResponder()
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
    
    // MARK: Toggle Buttons
    
    func handleToggleRememberedCard (card: GRNotificationCard) {
        card.toggleRememberedButton?.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let active = card.notification?.active else { return }
            
            if (card.notification?.remembered == false) {
                // Once a card is remembered we want to immediately deactivate it because there's no point in going over a word that you already know, right?
                self.updateNotification(notification: card.notification, card: card, button: card.toggleRememberedButton, isActive: false, isRemembered: true)
            
            } else {
                self.updateNotification(notification: card.notification, card: card, button: card.toggleRememberedButton, isActive: active, isRemembered: false)
            }
        }
    }
    
    func handleToggleActivateCard (card: GRNotificationCard) {
        
        card.toggleActivateButton?.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let isRemembered = card.notification?.remembered else { return }
            // We need to check first to make sure that the user hasn't hit their max number of notifications if
            // they're trying to activate a notification right now
            if (card.notification?.active == false) {
                let activeNotifications = self.notifications.filter({ $0.active == true })
                if activeNotifications.count >= self.maxNumOfCards {
                    self.showMaxNumberOfCardsHit()
                } else {
                    self.updateNotification(notification: card.notification, card: card, button: card.toggleActivateButton, isActive: true, isRemembered: isRemembered)
                }
            } else {
                self.updateNotification(notification: card.notification, card: card, button: card.toggleActivateButton, isActive: false, isRemembered: isRemembered)
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
    private func updateNotification (notification: GRNotification?, card:GRNotificationCard, button:UIButton?, isActive: Bool, isRemembered: Bool) {
        
        guard let notification = notification else { return }
        // Update the active state of the notification on it's table view cell (card) and within the local
        // notifications array
        card.notification?.active = isActive
        card.notification?.remembered = isRemembered
        self.updateNotificationInNotificationsArray(notification: card.notification)
        
        // Save the new active state to the server
        NotificationsManager.toggleNotification(notificationId: notification.id, active: isActive, remembered: isRemembered).subscribe().disposed(by: self.disposeBag)
    }
    
    private func showNotificationSaveError (_ error: Error) {
        GRMessageCard().draw(
            message: NSLocalizedString("notificationSaveError", comment: "Error saving notification content"),
            title: NSLocalizedString("notificationSaveErrorTitle", comment: "Error saving notification title"), buttonBackgroundColor: .red, superview: self.view, buttonText: NSLocalizedString("okay", comment: "The generic okay text"), isError: true)
        // Log the error using google analytics
        AnalyticsManager.logError(message: error.localizedDescription)
    }
    
    private func showMaxNumberOfCardsHit () {
        
        let card = GRMessageCard(color: .white, anchorWidthToScreenWidth: true)
        let maxCardMessage = String(format: NSLocalizedString("maxActiveNotificationsContent", comment: "The content for the max active notifications card"), arguments: ["\(self.maxNumOfCards)"])
        let maxCardTitle = String(format: NSLocalizedString("maxActiveNotificationsTitle", comment: "The title for the max active notifications card"))
        
        card
        .draw(
            message: maxCardMessage,
            title: maxCardTitle,
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
                    
                    let activeNotifications = self.allNotifications.filter({ $0.active == true })
                    NotificationsManager.shared.updateNotificationsActiveState(activeNotifications, active: false, completion: nil)
                    
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
    
    // MARK: Notification Observers
    
    @objc func notificationsSavedToServer (_ notification: Notification) {
        guard let notifications = notification.userInfo?[GRNotification.kSavedNotifications] as? [GRNotification] else { return }
        self.addNotifications(notifications, atBeginning: true)
    }
    
    @objc func deckAdded (_ notification: Notification) {
        guard let notifications = notification.userInfo?[GRNotification.kSavedNotifications] as? [GRNotification] else { return }
        self.addNotifications(notifications, atBeginning: true)
        self.mainView?.collectionView?.reloadData()
    }
    
    @objc func deckRemoved (_ notification: Notification) {
        guard let deckId = notification.userInfo?[GRNotification.Keys.kDeckId] as? String else { return }
        self.notifications = self.notifications.filter({ $0.deckId != deckId })
        self.allNotifications = self.allNotifications.filter({ $0.deckId != deckId })
        
        self.mainView?.collectionView?.reloadData()
    }

    private func addObservers () {
        NotificationCenter.default.addObserver(self, selector: #selector(maxNumCardsUpdated(_:)), name: .UserUpdatedMaxNumberOfCards, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationsSavedToServer(_:)), name: .NotificationsSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deckAdded(_:)), name: .DeckSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deckRemoved(_:)), name: .DeckRemoved, object: nil)
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
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.mainView != nil { return }

    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        if self.mainView != nil { return }
                        
        let mainView = GRViewWithCollectionView(margin: BootstrapMargin.noMargins()).setup(superview: self.view, columns: 3)
        mainView.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.coolGrey900)
        mainView.addToSuperview(superview: self.view, viewAbove: nil, anchorToBottom: true)
        
        self.mainView = mainView
        self.mainView?.setNeedsLayout()
        self.mainView?.layoutIfNeeded()
        
        self.checkIfDeviceConnectedToInternet()
        
        self.initialSetupCollectionView()
        
        // If this device has a device Id set, which all should
        let deviceId = UtilityFunctions.deviceId()
        
        // Get all the notifications for this device from the server
        let notificationsObservable = NotificationsManager.getNotifications(deviceId: deviceId)
        
        // Show that there is data loading
        let loading =  self.view.showLoadingNVActivityIndicatorView()
        
        let addButton = self.addAddButton()
        self.setupAddButton(addButton: addButton)
        
        let helpButton = self.addHelpButton(addButton, superview: self.mainView ?? self.view)
        
        let translateButton = self.addButtonNextTo(helpButton, imageName: "language")
        
        let deckCard = self.addButtonNextTo(translateButton, imageName: "deck")
        
        deckCard.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            self.showDecksViewController()
        }
        
        self.setupTranslateButtonPressedClosure(translateButton)
        
        self.subscribeToNotificationsObservable(notificationsObservable: notificationsObservable, loading: loading)
        
        self.promptForAllowNotifications()
        
        // If appropriate than request the user to write a review
        UtilityFunctions.requestReviewIfAppropriate()
    }
    
    private func checkIfDeviceConnectedToInternet () {
        if InternetConnectionManager.isConnectedToNetwork() == false {
            GRMessageCard().draw(message: "You can use this app without being connected to the internet, but you may experience strange behaviours within the app.  If possible, we recommend you connect your device to the internet.", title: "Device Not Connected to Internet", superview: self.view)
        }
    }
    
    fileprivate func promptForAllowNotifications () {
        if (UtilityFunctions.isFirstTime("opening the main view controller")) {
            let messageCard = GRMessageCard()
            let enableNotificationsMessageContent = NSLocalizedString("enableNotificationsMessageContent", comment: "The message content for the card prompting the user to enable notifications")
            let enableNotificationsMessageTitle = NSLocalizedString("enableNotificationsTitleContent", comment: "The title for the card prompting the user to enable notifications")
            let enableNotificationsButton = NSLocalizedString("enableNotificationsButton", comment: "The button for the enable notifications message card to enable the notifications")
            let enableNotificationsCancelButton = NSLocalizedString("enableNotificationsCancelButton", comment: "The cancel button for the enable notifications message card to not enable notifications")
            
            messageCard.draw(message: enableNotificationsMessageContent, title: enableNotificationsMessageTitle, superview: self.view, buttonText: enableNotificationsButton, cancelButtonText: enableNotificationsCancelButton)
            
            messageCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.setupRemoteNotifications(application: UIApplication.shared)
                messageCard.close()
                self.showDecksViewController()
            })
            
            messageCard.secondButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                messageCard.close()
                self.showDecksViewController()
            })
        }
    }
    
    private func showDecksViewController () {
        let decksVC = DecksViewController()
        self.present(decksVC, animated: true, completion: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.addObservers()
        self.getMaxNumOfCardsFromServer()
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.mainView?.collectionView?.collectionViewLayout.invalidateLayout()
        
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // If the screen changes size then we have to make sure that we reload the sections in order to make sure that the card's are the proper size for the size of the screen
        if (self.mainView?.collectionView?.dataSource == nil) {
            return
        }
    }
    
    private func handleTagPressed (tagPressed: PublishSubject<String>?) {
        tagPressed?.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let tag = event.element else { return }
                                                
            switch tag {
            case NSLocalizedString("all", comment: "All button") :
                self.notifications = self.allNotifications
            case NSLocalizedString("active", comment: "active"):
                self.notifications = self.allNotifications.filter({ $0.active == true })
            case NSLocalizedString("inactive", comment: "inactive"):
                self.notifications = self.allNotifications.filter({ $0.active == false })
            case "Remembered":
                self.notifications = self.allNotifications.filter({ $0.remembered == true })
            case "Not Remembered":
                self.notifications = self.allNotifications.filter({ $0.remembered == false || $0.remembered == nil })
            default:
                self.notifications = self.allNotifications.filter({ $0.tags?.contains(tag) == true })
            }
            
            self.sortNotifications()
            
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
                    DispatchQueue.main.async {
                        self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                    }
                    
                } else {
                    self.notifications = self.allNotifications.filter({
                        $0.bookTitle?.lowercased().contains(text.lowercased()) == true ||
                            $0.caption.lowercased().contains(text.lowercased()) == true ||
                            $0.description.lowercased().contains(text.lowercased()) == true ||
                            $0.language?.lowercased().contains(text.lowercased()) == true
                    })
                    
                    var indexPathsToRemove = [IndexPath]()
                    
                    for index in self.notifications.count..<self.allNotifications.count {
                        let indexPath = IndexPath(row: index, section: 0)
                        indexPathsToRemove.append(indexPath)
                    }
                    
                    DispatchQueue.main.async {
                        self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    
    /**
     If the notifications relay contains zero elements than we need to display the no data view on the Table View
     */
    func showEmptyCollectionView () {
        let noNotificationsMessageLocalized = NSLocalizedString("noNotificationsMessage", comment: "When the user has created no notifications and we display that on the collection views background")
        let addNotificationMessageLocalized = NSLocalizedString("addNotificationMessage", comment: "The button on the collection views background that when pressed the user can add a notification")
        
        let actionButton = self.mainView?.collectionView?.setEmptyMessage(
            message: noNotificationsMessageLocalized, header: addNotificationMessageLocalized, imageName: "interface")
        self.setupAddButton(addButton: actionButton)
    }
    
    /**
        Subscribe to an observable which will return notifications from the server
     */
    func subscribeToNotificationsObservable (notificationsObservable: Observable<[GRNotification]>, loading: NVActivityIndicatorView?) {
        notificationsObservable.subscribe { [weak self] (event) in
            guard let self = self else { return }
                            
            if let error = event.error {
                print(error.localizedDescription)
                AnalyticsManager.logError(message: error.localizedDescription)
                GRMessageCard().draw(message: "There seems to be a problem with your internet connection.  Please check your internet connection.", title: "Error", superview: self.view, isError: true)
            }
            
            if event.error != nil {
                self.view.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            }
            
            if event.isCompleted {
                self.view.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
                self.sortNotifications()
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
    
    private func sortNotifications () {
        self.notifications = self.notifications.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    func addNotifications (_ notifications: [GRNotification], atBeginning:Bool = false) {
        
        if atBeginning {
            self.notifications.insert(contentsOf: notifications, at: 0)
            self.allNotifications.insert(contentsOf: notifications, at: 0)
            DispatchQueue.main.async {
                self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
            }
            
            return
        }
        
        self.notifications.append(contentsOf: notifications)
        self.allNotifications.append(contentsOf: notifications)
        
        DispatchQueue.main.async {
            self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    func removeNotification (notificationId: String) {
        self.notifications.removeAll(where: { $0.id == notificationId })
        self.allNotifications.removeAll(where: { $0.id == notificationId })
        self.reloadCollectionView()
    }
    
    func reloadCollectionView () {
        self.mainView?.collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    func setupNotificationCellDeleteButton (cell: GRNotificationCard) {
        
        // User presses the delete button
        cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            
            let deleteCard = DeleteCard(color: UIColor.white.dark(Dark.coolGrey700), anchorWidthToScreenWidth: true)
            deleteCard.draw(superview: self.view)
            deleteCard.secondButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let _ = self else { return }
                deleteCard.close()
            })
            
            deleteCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                guard let notificationId = cell.notification?.id else
                {
                    assertionFailure("Baaka, why is the notification Id not set for this cell.  That should not be possible.  Check to make sure you're setting this value to whatever the notification is for this cell.")
                    return
                }
                                                
                let loading = deleteCard.firstButton?.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.deleteNotificationWithId(notificationId)
                    .subscribe { [weak self] (event) in
                        guard let self = self else { return }
                        
                        deleteCard.firstButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                        
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
    
    func addButtonNextTo (_ nextToButton: UIButton, imageName: String) -> UIButton {
        let button = Style.largeButton(with: "", backgroundColor: UIColor.EZRemember.mainBlue)
        button.setImage(UIImage(named: imageName), for: .normal)
        self.mainView?.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.right.equalTo(nextToButton.snp.left).offset(-20)
            make.centerY.equalTo(nextToButton)
            make.width.equalTo(32)
            make.height.equalTo(32)
        }
        
        button.layer.cornerRadius = 16.0
        
        return button
    }
    
    func setupTranslateButtonPressedClosure (_ translateButton: UIButton ) {
        translateButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            let messageCard = GRMessageCard(addTextField: true, textFieldPlaceholder: "Enter words to translate...", showFromTop: true)
            messageCard.draw(message: "Enter the text you would like to translate.", title: "Translate", superview: self.mainView ?? self.view, buttonText: "Translate", cancelButtonText: "Cancel")
            messageCard.textField?.becomeFirstResponder()
            guard let okayButton = messageCard.firstButton else { return }
            
            okayButton.addTargetClosure { [weak self] (okayButton) in
                if messageCard.textField?.text == "" {
                    return
                }
                
                guard let self = self else { return }
                guard let textToTranslate = messageCard.textField?.text else { return }
                self.translateTextButtonPressed(okayButton, translationMessageCard: messageCard, text: textToTranslate)
            }
        }
    }
    
    func translateTextButtonPressed (_ button:UIButton, translationMessageCard: GRMessageCard, text: String) {
        self.translateButtonPressed(button, wordsToTranslate: text) { (translations) in
            translationMessageCard.close()
            let translationsVC = DEShowTranslationsViewController(translations: translations, originalWord: text, languages: ScheduleManager.shared.getLanguages(), bookTitle: nil)
                        
            self.present(translationsVC, animated: true) {
                translationsVC.view.backgroundColor = UIColor.EZRemember.veryLightGray.dark(.black)
            }
        }
    }

    @objc func addButtonPressed () {
        let createNotifVC = GRNotificationViewController(notification: self.unfinishedNotification)
        
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
