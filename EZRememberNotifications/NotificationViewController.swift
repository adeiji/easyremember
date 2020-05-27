//
//  NotificationViewController.swift
//  EZRememberNotifications
//
//  Created by Adebayo Ijidakinro on 5/27/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var contentLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didReceive(_ notification: UNNotification) {
        self.contentLabel?.backgroundColor = UIColor(red: 48/255, green: 105/255, blue: 199/255, alpha: 1.0)
        self.contentLabel?.textColor = .white
        let hiddenData = notification.request.content.userInfo["hiddenData"] as? String
        
        if hiddenData != "" {
            self.contentLabel?.text = hiddenData
        } else {
            self.contentLabel?.text = notification.request.content.body
        }
                                        
        self.titleLabel?.text = "Did you remember it?\n\n\(notification.request.content.title)"
    }
}
