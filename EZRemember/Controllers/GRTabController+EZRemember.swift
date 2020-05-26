//
//  GRTabController+EZRemember.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/27/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

extension GRTabController {
    
    public func getNotificationsViewController () -> DEMainViewController? {
        guard let viewController = self.viewControllers["Notifications"] else { return nil }
        let notificationsNavVC = viewController as? UINavigationController
        return notificationsNavVC?.viewControllers.first as? DEMainViewController
    }
    
}
