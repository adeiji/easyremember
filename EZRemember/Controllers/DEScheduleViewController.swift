//
//  DEScheduleViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift
import DephynedFire
import DephynedPurchasing

extension NSNotification.Name {
    
    static let UserUpdatedMaxNumberOfCards = NSNotification.Name("UserUpdatedMaxNumberOfCards")
}

class DEScheduleViewController: GRBootstrapViewController, RulesProtocol, AddHelpButtonProtocol, InternetConnectedVCProtocol {
    
    var internetNotConnectedDialogShown: Bool = false
    
    var explanation = Explanation(sections: [
        ExplanationSection(content: NSLocalizedString("reminderExplanation", comment: "The first sections explanation for why there is a number of cards section"), title: NSLocalizedString("reminderExplanationTitle", comment: "The title for this section"), image: ImageHelper.image(imageName: "bell-white", bundle: "EZRemember")),
        ExplanationSection(content: NSLocalizedString("scheduleExplanation", comment: "The second section's explanation for why we have a schedule"),
        title: NSLocalizedString("scheduleExplanationTitle", comment: "The title for the scheduling sectino"),
        image: ImageHelper.image(imageName: "clock-white", bundle: "EZRemember")),
        ExplanationSection(content: NSLocalizedString("learnLanguageExplanation", comment: "The third section's explanation for how the language feature works"),
        title: NSLocalizedString("learnLanguageExplanationTitle", comment: "The title for the language explanation of scheduling"),
        image: ImageHelper.image(imageName: "translator", bundle: "EZRemember"))
    ])
            
    private weak var mainView:GRViewWithScrollView?
    internal let disposeBag = DisposeBag()
    private weak var scheduleView:DEScheduleView?
    private weak var maxNumberOfCardsCard:DENumberCard?
    private weak var languagesCard:DELanguagesCard?
    
    var purchaseType:String?
    
    private var selectedLanguages:[String] = ["en"]
    
    private var cardSendFrequency = 60
    
    // The margins for bootstrap elements on this view
    private let margins:BootstrapMargin = BootstrapMargin(
        left: .Five,
        top: .Zero,
        right: .Five,
        bottom: .Zero)
    
    /// The times that the user wants the notifications sent
    private var timeSlots = [Int]()
    
    /// The maximum number of cards that the user has being sent to them at any given time
    private var maxNumOfCards:Int = 3
    
    /// Whether this schedules notifications are paused
    private var pausedNotifications = false
    
    /// Whether this schedules notifications should include writing practice
    private var writeNotifications = true
    
    public var timeSlotsSubject:PublishSubject<[Int]> = PublishSubject<[Int]>()
    
    public var defaultTimeSlots = [11, 12, 13, 14, 15]
    
    private var notificationStyle:String = Schedule.NotificationsType.kShowEverything
    
    private func setupNavBar () {
        
        self.mainView?.navBar?.rightButton?.setTitle("Save", for: .normal)
        self.mainView?.navBar?.rightButton?.setTitleColor(UIColor.black.dark(.white), for: .normal)
        self.mainView?.navBar?.rightButton?.isUserInteractionEnabled = true
        
        self.mainView?.navBar?.backgroundColor = .clear
        self.mainView?.navBar?.header?.textColor = .white
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.displayIfDeviceNotConnectedToInternet()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                                        
        let mainView = GRViewWithScrollView().setup(superview: self.view, showNavBar: true, navBarHeaderText: "EZ Remember")
        self.mainView = mainView
        self.mainView?.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.setupNavBar()
        self.addHelpButton(self.mainView?.navBar?.rightButton, superview: mainView)
                
        self.loadSchedule()
        self.savePressed()
    }
    
    /// Get the schedule for this device
    private func loadSchedule () {
                        
        guard let mainView = self.mainView else { return }
        
        // We add the schedule view as a subclass of the main view container view so that we can use the main view's scroll view
        // that way the schedule view can expand to whatever size necessary
        let scheduleView = DEScheduleView(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins)
        
        let loading = self.mainView?.showLoadingNVActivityIndicatorView()
        
        ScheduleManager.shared.getScheduleFromServer().subscribe { [weak self] (event) in
            guard let self = self else { return }
                        
            // Show finished loading
            mainView.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
            if event.isCompleted {
                return
            }
            
            if let unwrappedSchedule = event.element, var schedule = unwrappedSchedule {
                schedule.convertTimeSlotsUTC(to: false)
                self.cardSendFrequency = schedule.frequency
                self.notificationStyle = schedule.style ?? Schedule.NotificationsType.kShowEverything
                self.pausedNotifications = schedule.paused ?? false
                self.writeNotifications = schedule.writingPractice ?? true
                self.drawSchedule(schedule: schedule, scheduleView: scheduleView)
                mainView.updateScrollViewContentSize()
            } else {
                let schedule = Schedule(deviceId: UtilityFunctions.deviceId(), timeSlots: self.defaultTimeSlots, maxNumOfCards: 5, languages: ["en"], frequency: 60)
                self.drawSchedule(schedule: schedule, scheduleView: scheduleView)
                mainView.updateScrollViewContentSize()
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func syncButtonPressed (button: UIButton?) {
        button?.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            let syncVC = DESyncViewController()
            self.present(syncVC, animated: true, completion: nil)
        }
    }
    
    private func purchaseButtonPressed (button: UIButton?) {
        button?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
                        
            let purchasingVC = GRPurchasingViewController(purchaseableItems: Purchasing.purchaseItems)
            self.present(purchasingVC, animated: true, completion: nil)
        })
    }
    
    fileprivate func getToggledItemsCard(_ mainView: GRViewWithScrollView) -> GRBootstrapElement {
        let writingPracticeText = "Would you like to receive notifications to practice writing? (When learning a language this helps a lot!)"
        let pauseText = "Would you like to pause receiving notifications for now?"
        
        let toggledItems = DEToggledItems(
            items: [
                writingPracticeText: self.writeNotifications,
                pauseText: self.pausedNotifications],
            title: "Notification Settings", margin: self.margins)
        
        toggledItems.itemToggled.bind { [weak self] (toggleItem) in
            guard let self = self else { return }
            
            switch toggleItem.item {
            case writingPracticeText:
                self.writeNotifications = toggleItem.active
                break;
            case pauseText:
                self.pausedNotifications = toggleItem.active
                break;
            default:
                break;
            }
        }.disposed(by: self.disposeBag)
        
        return toggledItems
    }
    
    private func drawSchedule (schedule: Schedule, scheduleView: DEScheduleView) {
        
        guard let mainView = mainView else { return }
                        
        var viewAbove:UIView?
        
        // PURCHASE CARD
        
//        if self.purchasedOnline() == false {
            let goPremiumLocalized = NSLocalizedString("goPremium", comment: "On the schedule view controller its the header for purchasing a package")
            let startTrialLocalized = self.userHasSubscription() ? "Upgrade Package" : NSLocalizedString("startTrial", comment: "On the schedule view controller its the start free 7 day trial button text")
            
            let purchaseCard = GRTitleAndButtonCard(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins, superview: nil)
            purchaseCard.draw(title: goPremiumLocalized, buttonTitle: startTrialLocalized)
            purchaseCard.addToSuperview(superview: mainView.containerView, anchorToBottom: false)
            self.purchaseButtonPressed(button: purchaseCard.actionButton)
            viewAbove = purchaseCard
//        }
                        
        // RESTORE PURCHASE CARD
        
        let restorePurchasesLocalized = NSLocalizedString("restorePurchases", comment: "The header for the restore purchases section")
        let restorePurchasesButtonLocalized = NSLocalizedString("restorePurchasesButton", comment: "The text for the restore purchases button")
        
        let restorePurchaseCard = GRTitleAndButtonCard(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins, superview: nil)
        restorePurchaseCard.draw(title: restorePurchasesLocalized, buttonTitle: restorePurchasesButtonLocalized)
        restorePurchaseCard.addToSuperview(superview: mainView.containerView, viewAbove: viewAbove, anchorToBottom: false)
        
        self.setupPurchaseCardPurchaseButton(restorePurchaseCard)
                
        // SYNC CARD
                
        let syncHeaderLocalized = NSLocalizedString("promptToSync", comment: "The header for the sync section asking if the user wants to sync or not")
        let syncLocalized = NSLocalizedString("sync", comment: "generic sync text")
        
        let syncCard = GRTitleAndButtonCard(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins, superview: nil)
        syncCard.draw(title: syncHeaderLocalized, buttonTitle: syncLocalized)
        syncCard.addToSuperview(superview: mainView.containerView, viewAbove: restorePurchaseCard, anchorToBottom: false)
        self.syncButtonPressed(button: syncCard.actionButton)
                
        // NUMBER CARD
        
        let numberCard = DENumberCard(selectedNumber: schedule.maxNumOfCards, bootstrapMargin: self.margins)
        numberCard.addToSuperview(superview: mainView.containerView, viewAbove: syncCard, anchorToBottom: false)
        self.maxNumberOfCardsCard = numberCard
        
        let languagesCard = DELanguagesCard(bootstrapMargin: self.margins, selectedLanguages: schedule.languages)
        languagesCard.addToSuperview(superview: mainView.containerView, viewAbove: numberCard, anchorToBottom: false)
        
        // Show the schedule view with the either the default time slots or this user's time slots choices already selected
        scheduleView.setupUI(
            superview: mainView,
            timeSlots: schedule.timeSlots,
            selecteMaxNumber: schedule.maxNumOfCards)
                .addToSuperview(superview: mainView.containerView, viewAbove: languagesCard, anchorToBottom: false)
        
        
        // FREQUENCY CARD
        
        let frequencyCard = DEFrequencyCard(margin: self.margins, selectedFrequency: schedule.frequency)
        frequencyCard.addToSuperview(superview: mainView.containerView, viewAbove: scheduleView, anchorToBottom: false)
        frequencyCard.frequencyCardSelected.subscribe { [weak self] (event) in
            guard let self = self else { return }
                        
            if let selectedFrequency = event.element {
                self.cardSendFrequency = selectedFrequency
            }            
                        
        }.disposed(by: self.disposeBag)
        
        let notificationTypeCard = DEMultiSelectCard(listOfItems: [
            Schedule.NotificationsType.kFlashcardCaptionVisible,
            Schedule.NotificationsType.kFlashcardContentVisible,
            Schedule.NotificationsType.kShowEverything
        ],  margin: self.margins, selectedItem: self.notificationStyle)
        
        notificationTypeCard.selectedItem.bind { [weak self] (notificationStyle) in
            guard let self = self else { return }
            guard let notificationStyle = notificationStyle else { return }
            self.notificationStyle = notificationStyle
        }.disposed(by: self.disposeBag)
                        
        notificationTypeCard.addToSuperview(superview: mainView.containerView, viewAbove: frequencyCard, anchorToBottom: false)
        
        let toggledItemsCard = self.getToggledItemsCard(mainView)
        toggledItemsCard.addToSuperview(superview: mainView.containerView, viewAbove: notificationTypeCard, anchorToBottom: true)
        
        self.timeSlotsSubject.onNext(schedule.timeSlots)
        self.scheduleView = scheduleView
        self.maxNumOfCards = schedule.maxNumOfCards
        self.languagesCard = languagesCard
        self.timeSlots = schedule.timeSlots
        self.handleTimeSlotUpdate()
    }
    
    /// Respond to when a user selects a timeSlot
    func handleTimeSlotUpdate () {
        guard let scheduleView = self.scheduleView else { return }
        // Detect every time the user selects a time
        scheduleView.timeSlotSubject.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let element = event.element {
                let timeSlot = element.timeSlot
                let cell = element.cell
                
                // If the user has already selected this time slot than we need to remove it because they've pressed this
                // time slot twice
                if (self.timeSlots.contains(timeSlot)) {
                    cell.selected = !cell.selected
                    self.timeSlots.removeAll(where: { $0 == timeSlot })
                } else {
                    if self.validatePassRuleOrShowFailure(Purchasing.Rules.kMaxTimes, numberToValidate: self.timeSlots.count + 1, testing: false) {
                        cell.selected = !cell.selected
                        self.timeSlots.append(timeSlot)
                    }
                }
                
                self.timeSlotsSubject.onNext(self.timeSlots)
            }
            
        }.disposed(by: self.disposeBag)
    }
    
    /**
     Setup the right button of the nav bar which is the save button.
     */
    private func savePressed () {
        self.mainView?.navBar?.rightButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            guard let selectedLanguages = self.languagesCard?.selectedLanguages else { return }
            let selectedNumber = self.maxNumberOfCardsCard?.selectedButton?.titleLabel?.text ?? "5"
            guard let maxNumOfCards = Int(selectedNumber) else { return }
            self.selectedLanguages = selectedLanguages
            
            if maxNumOfCards < self.maxNumOfCards {
                self.showMaxNumberLessThanPreviousCard(maxNumOfCards: maxNumOfCards)
            } else {
                self.maxNumOfCards = maxNumOfCards
                self.saveSchedule()
            }
        })
    }
    
    func showMaxNumberLessThanPreviousCard (maxNumOfCards:Int) {
        let messageCard = GRMessageCard()
        let maxNumberMessage = String(format: NSLocalizedString("maxNumberLowWarning", comment: "The max number is less than the previous max number warning"), self.maxNumOfCards)
        let maxNumberMessageTitle = NSLocalizedString("maxNumberLowTitle", comment: "The card to display to the user that the max number is less than the previous title")
        messageCard.draw(message: maxNumberMessage, title: maxNumberMessageTitle, buttonBackgroundColor: UIColor.EZRemember.mainBlue, superview: self.view, cancelButtonText: "Cancel")
        
        messageCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            self.maxNumOfCards = maxNumOfCards
            messageCard.close()
            self.saveSchedule()            
        })
        
        messageCard.secondButton?.addTargetClosure(closure: { (_) in
            messageCard.close()
        })
    }
    
    func saveSchedule() {
        let loading = self.mainView?.navBar?.rightButton?.showLoadingNVActivityIndicatorView()
        
        var schedule = Schedule(deviceId: UtilityFunctions.deviceId(), timeSlots: self.timeSlots, maxNumOfCards: self.maxNumOfCards, languages: self.selectedLanguages, frequency: self.cardSendFrequency, purchasedPackage: self.purchaseType, style: self.notificationStyle)
        
        // These are two settings that currently are not updated within the app
        schedule.purchasedPackage = ScheduleManager.shared.getSchedule()?.purchasedPackage
        schedule.sentence = ScheduleManager.shared.getSchedule()?.sentence
        schedule.writingPractice = self.writeNotifications
        schedule.paused = self.pausedNotifications
                
        ScheduleManager.shared.saveSchedule(schedule).subscribe { (event) in
            // Show that saving has finished
            self.mainView?.navBar?.rightButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
            if let _ = event.element {
                // Let the app know that the user has just updated the max number of cards
                NotificationCenter.default.post(name: .UserUpdatedMaxNumberOfCards, object: nil, userInfo: [ "maxNumOfCards": self.maxNumOfCards ])
                NotificationCenter.default.post(name: .LanguagesUpdated, object: nil, userInfo: [Schedule.Keys.kLanguages: self.selectedLanguages])
            }
            
            if let _ = event.error {
                
            }
        }.disposed(by: self.disposeBag)
    }
}
