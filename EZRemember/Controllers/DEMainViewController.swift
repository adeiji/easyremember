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

struct Notification {
    
    let caption:String
    let description:String
    
}

class DEMainViewController: UIViewController {
    
    weak var mainView:GRViewWithTableView?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "EZ Remember", rightNavBarButtonTitle: "Add")
        
        self.mainView?.navBar.backgroundColor = .black
        self.mainView?.navBar.header?.textColor = .white
        self.mainView?.navBar.rightButton?.setTitleColor(.white, for: .normal)
        self.mainView?.navBar.rightButton?.titleLabel?.font = FontBook.allBold.of(size: .medium)
        
        self.mainView?.tableView.register(GRNotificationCard.self, forCellReuseIdentifier: GRNotificationCard.reuseIdentifier)
        guard let tableView = self.mainView?.tableView else { return }
        
        let notifications = [
            Notification(caption: "Test", description: "This is only a test")
        ]
        
        let notificationsObservable = Observable.just(notifications)
        
        notificationsObservable
            .bind(to:
                tableView
                    .rx
                    .items(cellIdentifier: GRNotificationCard.reuseIdentifier, cellType: GRNotificationCard.self)) { (row, element, cell) in
                        cell.setupUI(title: element.caption, description: element.description)
        }.disposed(by: self.disposeBag)
        
        self.setupAddButton()
                                                    
    }
    
    func setupAddButton () {
        
        self.mainView?.navBar.rightButton?.addTargetClosure(closure: { [weak self] (_) in
            guard
                let self = self,
                let view = self.mainView
            else { return }
            
            let createNotifCard = GRCreateNotificationCard(superview: view)
            createNotifCard.addButton?.addTargetClosure(closure: { [weak self] (_) in
                                                
                guard
                    let self = self,
                    let delegate = UIApplication.shared.delegate as? AppDelegate,
                    let title = createNotifCard.titleTextField?.text,
                    let description = createNotifCard.descriptionTextView?.text
                    else { return }
                
                let userDefaults = UserDefaults()
                var deviceId = userDefaults.object(forKey: delegate.kDeviceId) as? String
                
                if (deviceId == nil) {
                    deviceId = UUID().uuidString
                    userDefaults.set(deviceId, forKey: delegate.kDeviceId)
                }
                
                NotificationsManager.saveNotification(
                    title: title,
                    description: description,
                    // there's no way that the device Id will be null since if it's not set initially we give it a value
                    deviceId: deviceId!).subscribe { [weak self] (event) in
                        guard let self = self else { return }
                        let success = event.element
                        
                        if (success == true) {
                            // Show success
                        }
                        
                        if let error = event.error {
                            // Handle error
                        }
                }.disposed(by: self.disposeBag)
            })
        })
    }
}
