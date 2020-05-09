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

extension NSNotification.Name {
    
    static let UserUpdatedMaxNumberOfCards = NSNotification.Name("UserUpdatedMaxNumberOfCards")
}

class DEScheduleViewController: UIViewController {
        
    private weak var mainView:GRViewWithScrollView?
    private let disposeBag = DisposeBag()
    private weak var scheduleView:DEScheduleView?
    private weak var maxNumberOfCardsCard:DENumberCard?
    
    /// The times that the user wants the notifications sent
    private var timeSlots = [Int]()
    
    /// The maximum number of cards that the user has being sent to them at any given time
    private var maxNumOfCards:Int = 5
    
    public var timeSlotsSubject:PublishSubject<[Int]> = PublishSubject<[Int]>()
    
    public var defaultTimeSlots = [11, 12, 13, 14, 15]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "EZ Remember")
        self.mainView?.navBar.rightButton?.setTitle("Save", for: .normal)
        self.mainView?.navBar.rightButton?.setTitleColor(.black, for: .normal)
                
        self.loadSchedule()
        self.savePressed()
    }
    
    /// Get the schedule for this device
    private func loadSchedule () {
        
        guard let mainView = self.mainView else { return }
        
        // We add the schedule view as a subclass of the main view container view so that we can use the main view's scroll view
        // that way the schedule view can expand to whatever size necessary
        let scheduleView = DEScheduleView(anchorWidthToScreenWidth: true, margin:
            BootstrapMargin(left: 40, top: 0, right: 40, bottom: 0))
        
        ScheduleManager.getSchedule().subscribe { [weak self] (event) in
            guard let self = self else { return }
            
            let loading = self.mainView?.showLoadingNVActivityIndicatorView()
            // Show finished loading
            mainView.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            
            if event.isCompleted {
                return
            }
            
            if let unwrappedSchedule = event.element, let schedule = unwrappedSchedule {
                self.drawSchedule(schedule: schedule, scheduleView: scheduleView)
                mainView.updateScrollViewContentSize()
            } else {
                let schedule = Schedule(deviceId: UtilityFunctions.deviceId(), timeSlots: self.defaultTimeSlots, maxNumOfCards: 5, fcmToken: nil)
                self.drawSchedule(schedule: schedule, scheduleView: scheduleView)
                mainView.updateScrollViewContentSize()
            }
        }.disposed(by: self.disposeBag)
    }
    
    private func drawSchedule (schedule: Schedule, scheduleView: DEScheduleView) {
        
        guard let mainView = mainView else { return }
        
        let numberCard = DENumberCard(selectedNumber: schedule.maxNumOfCards)
        numberCard.addToSuperview(superview: mainView.containerView, anchorToBottom: false)
        
        // Show the schedule view with the either the default time slots or this user's time slots choices already selected
        scheduleView.setupUI(
            superview: mainView,
            timeSlots: schedule.timeSlots,
            selecteMaxNumber: schedule.maxNumOfCards)
                .addToSuperview(superview: mainView.containerView, viewAbove: numberCard, anchorToBottom: true)
        
        self.timeSlotsSubject.onNext(schedule.timeSlots)
        self.scheduleView = scheduleView
        self.maxNumOfCards = schedule.maxNumOfCards
        self.timeSlots = schedule.timeSlots
        self.handleTimeSlotUpdate()
    }
    
    /// Respond to when a user selects a timeSlot
    func handleTimeSlotUpdate () {
        guard let scheduleView = self.scheduleView else { return }
        // Detect every time the user selects a time
        scheduleView.timeSlotSubject.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let timeSlot = event.element {
                
                // If the user has already selected this time slot than we need to remove it because they've pressed this
                // time slot twice
                if (self.timeSlots.contains(timeSlot)) {
                    self.timeSlots.removeAll(where: { $0 == timeSlot })
                } else {
                    self.timeSlots.append(timeSlot)
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
            guard let selectedNumber = self.maxNumberOfCardsCard?.selectedNumberButton?.titleLabel?.text else { return }
            guard let maxNumOfCards = Int(selectedNumber) else { return }
            
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
        ScheduleManager.saveSchedule(timeSlots: self.timeSlots, maxNumOfCards: self.maxNumOfCards).subscribe { (event) in
            if let _ = event.element {
                // Show that saving has finished
                self.mainView?.navBar.rightButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                // Let the app know that the user has just updated the max number of cards
                NotificationCenter.default.post(name: .UserUpdatedMaxNumberOfCards, object: nil, userInfo: [ "maxNumOfCards": self.maxNumOfCards ])
            }
            
            if let _ = event.error {
                
            }
        }.disposed(by: self.disposeBag)
    }
}
