//
//  GRBootstrapElement+Delete.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

open class DeleteCard: GRMessageCard {               
    public func draw (superview: UIView) {
        super.draw(message: "Are you sure you want to delete this?", title: "Delete", buttonBackgroundColor: UIColor.Style.htRedish, superview: superview, buttonText: "Delete", cancelButtonText: "Cancel", isError: false)
    }
}
