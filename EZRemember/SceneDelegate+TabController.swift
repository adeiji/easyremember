//
//  AppDelegate+TabController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

extension SceneDelegate {
    
    func createTabController () -> GRTabController {
        
        let vc = DEMainViewController()
        let mainNavigationViewController = UINavigationController(rootViewController: vc as UIViewController);
        mainNavigationViewController.navigationBar.isHidden = true
        self.mainViewController = vc
        
        let scheduleVC = DEScheduleViewController()
                
        let epubReaderVC = DEEpubReaderController()
        let epubReaderNavVC = UINavigationController(rootViewController: epubReaderVC)
        epubReaderNavVC.navigationBar.isHidden = true
        let tabController = GRTabController(
            numberOfButtons:  3,
            buttonsBackgroundColor: UIColor.white.dark(Dark.mediumShadeGray),
            buttonSelectedColor: UIColor.Style.lightGray.dark(.darkGray) )
        
        tabController.addFooterButton(title: "Notifications", imageName: "bell", viewControllerToShow: mainNavigationViewController)
        tabController.addFooterButton(title: "Schedule", imageName: "clock", viewControllerToShow: scheduleVC)
        tabController.addFooterButton(title: "Reader", imageName: "book", viewControllerToShow: epubReaderNavVC)
        
        // Have to add the view controller and it's view to the tab bar controller in order to work properly
        tabController.addChildViewControllerWithView(mainNavigationViewController, toView: tabController.mainView)
        
        scheduleVC.timeSlotsSubject.subscribe { [weak self] (event) in
            guard let self = self else { return }
            self.timeSlots = event.element
        }.disposed(by: self.disposeBag)                
        
        ScheduleManager.getSchedule().subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let unwrappedSchedule = event.element, let schedule = unwrappedSchedule {
                self.timeSlots = schedule.timeSlots
                NotificationCenter.default.post(name: .LanguagesUpdated, object: nil, userInfo: [Schedule.Keys.kLanguages: schedule.languages])
            }
        }.disposed(by: self.disposeBag)
        
        return tabController
    }
}
