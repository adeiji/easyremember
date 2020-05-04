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
        
        let tabController = GRTabController(numberOfButtons:  2)
        tabController.addFooterButton(title: "Notifications", imageName: "notification", viewControllerToShow: mainNavigationViewController)
        tabController.addFooterButton(title: "Notifications", imageName: "notification", viewControllerToShow: mainNavigationViewController)
        // Have to add the view controller and it's view to the tab bar controller in order to work properly
        tabController.addChildViewControllerWithView(mainNavigationViewController, toView: tabController.mainView)
        
        return tabController
    }
}
