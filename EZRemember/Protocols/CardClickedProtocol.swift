//
//  CardClickedProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/13/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

/// When a user clicks on a Notification card we show them that notification card
protocol CardClickedProtocol: UIViewController {
    
    var disposeBag:DisposeBag { get }
    
    var notifications:[GRNotification] { get set }
    
    var allNotifications:[GRNotification] { get set }
    
    var mainView:GRViewWithCollectionView? { get set }
        
}

extension CardClickedProtocol {
    
    private func showCard (notification: GRNotification) {
        let createCardVC = GRNotificationViewController(notification: notification, isEditingCard: true)                
        createCardVC.publishNotification.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let notification = event.element else { return }
            self.updateNotificationInNotificationsArray(notification: notification)
        }.disposed(by: self.disposeBag)
        self.present(createCardVC, animated: true, completion: nil)
    }
    
    internal  func setupTapCollectionView (collectionView: UICollectionView?) {
        guard let collectionView = collectionView else { return }
        collectionView.rx.itemSelected.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let indexPath = event.element else { return }
            let notification = self.notifications[indexPath.row]
            self.showCard(notification: notification)
        }.disposed(by: self.disposeBag)
    }
    
    func incrementNotificationRememberedCount (notificationId: String) {
        var notification = self.notifications.first(where: { $0.id == notificationId })
        let rememberedCount = notification?.rememberedCount
        notification?.rememberedCount = (rememberedCount ?? 0) + 1
        self.updateNotificationInNotificationsArray(notification: notification)
    }

    internal func updateNotificationInNotificationsArray (notification:GRNotification?) {
        guard let notification = notification else { return }
        if let row = self.notifications.firstIndex(where: { $0.id == notification.id }) {
            self.notifications[row] = notification
            self.mainView?.collectionView?.reloadItems(at: [IndexPath(row: row, section: 1)])
        }
        
        if let row = self.allNotifications.firstIndex(where: { $0.id == notification.id }) {
            self.allNotifications[row] = notification
        }
    }
    
}
