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

class DEScheduleViewController: UIViewController {
        
    private weak var mainView:GRViewWithScrollView?
    private let disposeBag = DisposeBag()
    
    /// The times that the user wants the notifications sent
    private var timeSlots = [Int]()
    
    /// The maximum number of cards that the user has being sent to them at any given time
    private var maxNumOfCards:Int = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "EZ Remember")
        self.mainView?.navBar.rightButton?.setTitle("Save", for: .normal)
        self.mainView?.navBar.rightButton?.setTitleColor(.black, for: .normal)
        
        guard let mainView = self.mainView else { return }
        let scheduleView = DEScheduleView()
        
        scheduleView.setupUI(superview: mainView).addToSuperview(superview: mainView.containerView, anchorToBottom: true)
        
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
            }
            
        }.disposed(by: self.disposeBag)
        mainView.updateScrollViewContentSize()
        
        self.mainView?.navBar.rightButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            let loading = self.mainView?.navBar.rightButton?.showLoadingNVActivityIndicatorView()
            ScheduleManager.saveSchedule(timeSlots: self.timeSlots, maxNumOfCards: self.maxNumOfCards).subscribe { (event) in
                if let _ = event.element {
                    // Show that saving has finished
                    self.mainView?.navBar.rightButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                }
                
                if let _ = event.error {
                    
                }
            }.disposed(by: self.disposeBag)
        })
    }        
}
