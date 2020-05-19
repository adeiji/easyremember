//
//  GRPurchasingViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/12/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import DephynedPurchasing
import RxSwift

class GRPurchasingViewController: UIViewController, PurchaseProtocol, AddCancelButtonProtocol {
    
    var mainView:GRViewWithScrollView?
    
    /// The items that we want to display for the user to purchase
    let purchaseableItems:[PurchaseableItem]
            
    let disposeBag = DisposeBag()
    
    init(purchaseableItems:[PurchaseableItem]) {
        self.purchaseableItems = purchaseableItems
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        let mainView = GRViewWithScrollView().setup(superview: self.view, navBarHeaderText: "What would you like to purchase?")
        mainView.navBar.header?.textColor = UIColor.black.dark(.white)
        mainView.backgroundColor = .clear
        self.addCancelButton(view: mainView)
        self.mainView = mainView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let mainView = self.mainView else { return }
        let purchaseCard = GRPurchasingCard(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: true, superview: self.view, purchaseableItems: self.purchaseableItems)
        
        // THE USER HAS SELECTED TO PURCHASE SOMETHING
        
        purchaseCard.subjectPurchaseItem.subscribe { [weak self] (event) in
            guard let self = self else { return }
            guard let purchaseItem = event.element else { return }
            let loadingView = purchaseCard.actionButton?.showLoadingNVActivityIndicatorView(color: UIColor.black.dark(.white))
            
            // PURCHASE THE PRODUCT
            
            self.purchaseProductWithId(id: purchaseItem.id) { (success) in
                purchaseCard.actionButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loadingView)
                if success {
                    
                    // PURCHASE WAS SUCCESSFUL
                    
                    let messageCard = GRMessageCard()
                    messageCard.draw(message: "Thanks so much for purchasing the \(purchaseItem.title) package! Get ready to do some serious learning!",  title: "Purchase Complete!", buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: self.view)
                } else {
                    
                    // PURCHASE FAILED
                    
                    let messageCard = GRMessageCard()
                    messageCard.draw(message: "There was a problem while purchasing the \(purchaseItem.title) package.  Please try again.  If the problem continues, contact us at info@dephyned.com.", title: "Purchase Complete!", buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: self.view, isError: true)
                }
                
            }
            
        }.disposed(by: self.disposeBag)
        
        purchaseCard.addToSuperview(superview: mainView.containerView, viewAbove: nil, anchorToBottom: true)
        mainView.updateScrollViewContentSize()
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed), name: .DEPurchaseFailed, object: nil)
    }
    
    @objc func purchaseFailed () {
        let messageCard = GRMessageCard()
        messageCard.draw(message: "There was a problem while purchasing the package.  Please try again.  If the problem continues, contact us at info@dephyned.com.", title: "Purchase Failed!", buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: self.view, isError: true)
    }
}
