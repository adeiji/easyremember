//
//  DEShowTranslationsViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift

class DEShowTranslationsViewController: UIViewController {
    
    var mainView:GRViewWithTableView?
    let translations:Translations
    let originalWord:String
    let disposeBag = DisposeBag()
    var notificationsToSave = [GRNotification]()
    
    init(translations:Translations, originalWord:String) {
        self.translations = translations
        self.originalWord = originalWord
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "Translations", rightNavBarButtonTitle: "Done")
        self.mainView?.tableView.register(GRNotificationCard.self, forCellReuseIdentifier: GRNotificationCard.reuseIdentifier)
        self.mainView?.navBar.rightButton?.setTitleColor(.black, for: .normal)
        self.mainView?.navBar.leftButton?.isHidden = true
        
        let notificationsManager = NotificationsManager()
        
        self.mainView?.navBar.rightButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            
            let loading = self.mainView?.navBar.rightButton?.showLoadingNVActivityIndicatorView()
            
            notificationsManager.saveNotifications(self.notificationsToSave) { [weak self] (success) in
                guard let self = self else { return }
                self.mainView?.navBar.rightButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.dismiss(animated: true, completion: nil)
            }
        })
        
        self.showTranslations()
    }
    
    func showTranslations () {
        guard let tableView = self.mainView?.tableView else { return }
        let translationsObserverable = Observable.of(self.translations.translated)
        
        translationsObserverable
            .bind(to:
                tableView
                    .rx
                    .items(cellIdentifier: GRNotificationCard.reuseIdentifier, cellType: GRNotificationCard.self)) { [weak self] (row, translation, cell) in
                        guard let self = self else { return }
                        
                        var originalWord = self.originalWord
                        
                        if self.originalWord.isIncludeChinese() {
                            originalWord = "\(self.originalWord) \(originalWord.transformToPinyin())"
                        }
                        
                        let notification = GRNotification(id: UUID().uuidString,
                                                          caption: originalWord,
                                                          description: translation.value,
                                                          deviceId: UtilityFunctions.deviceId(),
                                                          expiration: Date().timeIntervalSince1970.advanced(by: 86400 * 7),
                                                          creationDate: Date().timeIntervalSince1970,
                                                          active: false)
                        
                        // If the table view is showing a background view because it was empty, then reset it to it's normal state
                        self.mainView?.tableView.reset()
                        cell.isTranslation = true
                        cell.notification = notification
                        
                        cell.deleteButton?.setImage(nil, for: .normal)
                        cell.deleteButton?.setTitle(translation.key, for: .normal)
                        cell.deleteButton?.isUserInteractionEnabled = false
                        
                        cell.toggleActivateButton?.addTargetClosure(closure: { [weak self] (_) in
                            guard let self = self else { return }
                            guard var notification = cell.notification else { return }
                            
                            notification.active = !notification.active
                            cell.notification = notification
                            if (notification.active == false) {
                                self.notificationsToSave = self.notificationsToSave.filter({ $0.id == notification.id })
                            } else {
                                self.notificationsToSave.append(notification)
                            }
                        })
                        
        }.disposed(by: self.disposeBag)
    }
    
}
