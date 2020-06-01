//
//  AppDelegate+TabController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap
import RxSwift

@available(iOS 13.0, *)
extension SceneDelegate {
    
}

protocol TabControllerProtocol {    
    var disposeBag:DisposeBag { get }
}

extension TabControllerProtocol {
    func createTabController () -> GRTabController {
        
        let vc = DEMainViewController()
        let mainNavigationViewController = UINavigationController(rootViewController: vc as UIViewController);
        mainNavigationViewController.navigationBar.isHidden = true
        
        let scheduleVC = DEScheduleViewController()
                
        let epubReaderVC = DEEpubReaderController()
        let epubReaderNavVC = UINavigationController(rootViewController: epubReaderVC)
        epubReaderNavVC.navigationBar.isHidden = true
        let tabController = GRTabController(
            numberOfButtons:  3,
            buttonsBackgroundColor: UIColor.white.dark(Dark.mediumShadeGray),
            buttonSelectedColor: UIColor.Style.lightGray.dark(.darkGray) )
        
        tabController.addFooterButton(title: NSLocalizedString("notifications", comment: "Notifications tab bar title"), imageName: "bell", viewControllerToShow: mainNavigationViewController)
        tabController.addFooterButton(title: NSLocalizedString("schedule", comment: "Schedule tab bar title"), imageName: "clock", viewControllerToShow: scheduleVC)
        tabController.addFooterButton(title: NSLocalizedString("reader", comment: "Reader tab bar title"), imageName: "book", viewControllerToShow: epubReaderNavVC)
        
        // Have to add the view controller and it's view to the tab bar controller in order to work properly
        tabController.addChildViewControllerWithView(mainNavigationViewController, toView: tabController.mainView)
        
        ScheduleManager.shared.getScheduleFromServer().subscribe {(event) in
            if let unwrappedSchedule = event.element, let schedule = unwrappedSchedule {
                NotificationCenter.default.post(name: .LanguagesUpdated, object: nil, userInfo: [Schedule.Keys.kLanguages: schedule.languages])
            }
        }.disposed(by: self.disposeBag)
        
        return tabController
    }
}
