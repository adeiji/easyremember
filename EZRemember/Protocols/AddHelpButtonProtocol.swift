//
//  AddHelpButtonProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/21/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

protocol AddHelpButtonProtocol: UIViewController {
    var explanation:Explanation { get }
}

extension AddHelpButtonProtocol {
    
    internal func addHelpButton(_ buttonToRight: UIButton?, superview: UIView) {
        let helpButton = Style.largeButton(with: "?", backgroundColor: UIColor.EZRemember.mainBlue, fontColor: .white)
        helpButton.titleLabel?.font = CustomFontBook.Medium.of(size: .medium)
        superview.addSubview(helpButton)
        helpButton.snp.makeConstraints { (make) in
            make.right.equalTo(buttonToRight?.snp.left ?? superview).offset(-10)
            make.height.equalTo(32)
            make.width.equalTo(32)
            if let buttonToRight = buttonToRight {
                make.centerY.equalTo(buttonToRight)
            } else {
                make.top.equalTo(superview).offset(10)
            }
            
        }
        
        helpButton.radius(radius: 16)
        self.setupOnTapHelpButton(helpButton)
    }
    
    internal func setupOnTapHelpButton(_ helpButton: UIButton) {
        helpButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            let explanationViewController = ExplanationViewController(explanation: self.explanation)
            self.present(explanationViewController, animated: true, completion: nil)
        }
    }
    
}
