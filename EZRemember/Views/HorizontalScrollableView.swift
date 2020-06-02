//
//  HorizontalScrollableView.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 6/2/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

class HorizontalScrollableView: UIScrollView {
    
    var content:[UIView]? {
        didSet {
            if let content = content {
                self.draw(content)
            }
        }
    }
    
    private func draw (_ content: [UIView]) {
        
        self.alwaysBounceHorizontal = true
        self.isUserInteractionEnabled = true
                
        let containerView = UIView()
        containerView.isUserInteractionEnabled = true
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
            make.height.equalTo(50)
        }
        
        for index in 0...content.count - 1 {
            let view = content[index]
            containerView.addSubview(view)
            view.snp.makeConstraints { (make) in
                if view == content.first {
                    make.left.equalTo(containerView)
                } else {
                    make.left.equalTo(content[index - 1].snp.right).offset(20)
                }
                
                if view == content.last {
                    make.right.equalTo(containerView)
                }
                
                make.height.equalTo(40)
                make.centerY.equalTo(containerView)
                
                if let button = view as? UIButton {
                    make.width.equalTo(button.intrinsicContentSize.width + 30)
                }
            }
        }
        
    }
    
}
