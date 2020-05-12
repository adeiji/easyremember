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

class GRPurchasingViewController: UIViewController {
    
    var mainView:GRViewWithScrollView?
    let purchaseableItems:[PurchaseableItem]
    
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
        mainView.navBar.backgroundColor = .clear
        self.mainView = mainView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let mainView = self.mainView else { return }
        let purchaseCard = GRPurchasingCard(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: true, superview: self.view, purchaseableItems: self.purchaseableItems)
        
        purchaseCard.addToSuperview(superview: mainView.containerView, viewAbove: nil, anchorToBottom: true)
        mainView.updateScrollViewContentSize()
    }
    
}
