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

extension NSNotification.Name {
    
    static let UserUpdatedMaxNumberOfCards = NSNotification.Name("UserUpdatedMaxNumberOfCards")
}

class DEScheduleViewController: UIViewController, RulesProtocol {
        
    private weak var mainView:GRViewWithScrollView?
    private let disposeBag = DisposeBag()
    private weak var scheduleView:DEScheduleView?
    private weak var maxNumberOfCardsCard:DENumberCard?
    private weak var languagesCard:DELanguagesCard?
    
    private let purchase = "basic"
    
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
    private var maxNumOfCards:Int = 5
    
    public var timeSlotsSubject:PublishSubject<[Int]> = PublishSubject<[Int]>()
    
    public var defaultTimeSlots = [11, 12, 13, 14, 15]
    
    private func setupNavBar () {
        
        self.mainView?.navBar.rightButton?.setTitle("Save", for: .normal)
        self.mainView?.navBar.rightButton?.setTitleColor(UIColor.black.dark(.white), for: .normal)
        self.mainView?.navBar.rightButton?.isUserInteractionEnabled = true
        
        self.mainView?.navBar.backgroundColor = .clear
        self.mainView?.navBar.header?.textColor = .white
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "EZ Remember")
        self.mainView?.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.setupNavBar()
                
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
        
        ScheduleManager.shared.getSchedule().subscribe { [weak self] (event) in
            guard let self = self else { return }
                        
            // Show finished loading
            mainView.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
            if event.isCompleted {
                return
            }
            
            if let unwrappedSchedule = event.element, let schedule = unwrappedSchedule {
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
    
    private func drawSchedule (schedule: Schedule, scheduleView: DEScheduleView) {
        
        guard let mainView = mainView else { return }
        
        // PURCHASE CARD
        
        let purchaseCard = GRTitleAndButtonCard(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins, superview: nil)
        purchaseCard.draw(title: "Go Premium?", buttonTitle: "Start Your Free 7-Day Trial")
        purchaseCard.addToSuperview(superview: mainView.containerView, anchorToBottom: false)
        self.purchaseButtonPressed(button: purchaseCard.actionButton)
                
        // SYNC CARD
                
        let syncCard = GRTitleAndButtonCard(color: .clear, anchorWidthToScreenWidth: true, margin: self.margins, superview: nil)
        syncCard.draw(title: "Would you like to sync your data with your other devices?", buttonTitle: "Sync")
        syncCard.addToSuperview(superview: mainView.containerView, viewAbove: purchaseCard, anchorToBottom: false)
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
        frequencyCard.addToSuperview(superview: mainView.containerView, viewAbove: scheduleView, anchorToBottom: true)
        frequencyCard.frequencyCardSelected.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let selectedFrequency = event.element {
                self.cardSendFrequency = selectedFrequency
            }
        }.disposed(by: self.disposeBag)
        
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
        self.mainView?.navBar.rightButton?.addTargetClosure(closure: { [weak self] (_) in
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
        messageCard.draw(message: "You're setting a max number less than your previous.  If you do this, your current active cards will all be set to inactive, and you'll have to reactive them again.  Is this okay?  If not, choose a number higher than you previous of \(self.maxNumOfCards)", title: "Max Number Less than Previous", buttonBackgroundColor: UIColor.EZRemember.mainBlue, superview: self.view, cancelButtonText: "Cancel")
        
        messageCard.okayButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            self.maxNumOfCards = maxNumOfCards
            messageCard.close()
            self.saveSchedule()
            
        })
        
        messageCard.cancelButton?.addTargetClosure(closure: { (_) in
            messageCard.close()
        })
    }
    
    func saveSchedule() {
        let loading = self.mainView?.navBar.rightButton?.showLoadingNVActivityIndicatorView()
        
        let schedule = Schedule(deviceId: UtilityFunctions.deviceId(), timeSlots: self.timeSlots, maxNumOfCards: self.maxNumOfCards, languages: self.selectedLanguages, frequency: self.cardSendFrequency)
                                
        ScheduleManager.saveSchedule(schedule).subscribe { (event) in
            // Show that saving has finished
            self.mainView?.navBar.rightButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
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
