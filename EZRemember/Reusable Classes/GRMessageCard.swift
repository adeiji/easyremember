//
//  GRMessageCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/6/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

/**
 This is a simple helper class that extends GRBootstrapElement.  It contains nothing more than a message and a button that says "Okay"
 by default
 
 By default, when the okayButton is pressed it will simply close the card, however, you can override this functionality simply
 by changing the target of the okayButton property
 */
open class GRMessageCard: GRBootstrapElement {
             
    open weak var okayButton:UIButton?
    
    open weak var cancelButton:UIButton?
    
    private var blurView: UIView?
    
    private var addTextField:Bool
    
    private var showFromTop = false
    
    private var textFieldPlaceholder = ""
    
    open weak var textField:UITextField?
    
    public override init(color: UIColor? = UIColor.white.dark(Dark.coolGrey700), anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil, superview: UIView? = nil) {
        self.addTextField = false
        super.init(color: color, anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin, superview: superview)
    }
    
    convenience init(addTextField: Bool, textFieldPlaceholder:String, showFromTop: Bool) {
        self.init()
        self.addTextField = addTextField
        self.showFromTop = showFromTop
        self.textFieldPlaceholder = textFieldPlaceholder
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Displays the message card on the screen with the given parameters.  It also blurs the view that is responsible for showing it
     
     - Note: You don't need to add this view to the superview yourself, it will do so automatically
     
     - Important: If you want a cancel button than you must set the cancelButtonText.
     
     - parameters:
        - message: The message to display
        - title: The title of the message which goes at the top in large letters
        - buttonBackgroundColor: What color you want the button to be?
        - superview: What view is responsible for showing this view?
        - buttonText: What do you want the button to say?
        - cancelButtonText: Do you want a cancel button? If so, what do you want the text to say? **If you don't set this property, there will be no cancel button**
     */
    public func draw (message: String, title:String, buttonBackgroundColor:UIColor = UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: UIView, buttonText: String = "Okay", cancelButtonText:String? = nil, isError: Bool = false) {
        let okayButton = Style.largeButton(with: buttonText, backgroundColor: buttonBackgroundColor)
        okayButton.showsTouchWhenHighlighted = true
        
        let messageLabel = Style.label(withText: "", superview: nil, color: isError ? .red : UIColor.black.dark(.white))
        messageLabel.attributedText = (message).addLineSpacing()
        
        let cancelButton = Style.largeButton(with: cancelButtonText ?? "", backgroundColor: UIColor.EZRemember.veryLightGray, fontColor: .darkGray)
        cancelButton.showsTouchWhenHighlighted = true
        cancelButton.isHidden = cancelButtonText == nil
        
        let blurView = self.addBlurView(superview: superview)
        self.blurView = blurView
        
        self
        .addRow(columns: [
            
            // TITLE
            
            Column(cardSet: Style.label(withText: title, superview: nil, color: UIColor.black.dark(.white))
                .font(CustomFontBook.Regular.of(size: .header))
                .toCardSet()
                .margin.left(30)
                .margin.right(30)
                .margin.top(30),
                   xsColWidth: .Twelve),
            
            // MESSAGE
            
            Column(cardSet: messageLabel
                .font(CustomFontBook.Regular.of(size: .small))
                .toCardSet()
                .margin.left(30)
                .margin.right(30)
                .margin.top(30),
                   xsColWidth: .Twelve)
            ])
        
        if (self.addTextField) {
            let textField = Style.wideTextField(withPlaceholder: self.textFieldPlaceholder, superview: nil, color: Dark.coolGrey900.dark(.white))
            self.addRow(columns: [
                Column(cardSet: textField.toCardSet()
                    .margin.left(25)
                    .margin.right(25),
                       xsColWidth: .Twelve)
            ])
            self.textField = textField
        }
        
        self.addRow(columns: [
                
                // OKAY BUTTON
                
                Column(cardSet: okayButton
                    .radius(radius: 5)
                    .toCardSet()
                    .margin.bottom(10)
                    .margin.left(30)
                    .margin.right(30),
                       xsColWidth: .Twelve),
                
                // CANCEL BUTTON
                
                Column(cardSet: cancelButton
                .radius(radius: 5)
                .toCardSet()
                .margin.top(0)
                .margin.left(30)
                .margin.right(30)
                .margin.bottom(30),
                   xsColWidth: .Twelve)
            ], anchorToBottom: true)
                
        if self.showFromTop {
            self.slideDown(superview: superview, margin: 20, width: GRDevice.smallerThan(.sm) ? nil : 350)
        } else {
            self.slideUp(superview: superview, margin: 20, width: GRDevice.smallerThan(.sm) ? nil : 350)
        }
        
        okayButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            self.close()
        }
        
        cancelButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            self.close()
        }
        
        self.okayButton = okayButton
        self.cancelButton = cancelButton
    }
    
    public func close () {
        if let superview = self.superview {
            if self.showFromTop {
                self.slideUpAndRemove(superview: superview)
                self.blurView?.removeFromSuperview()
            } else {
                self.slideDownAndRemove(superview: superview)
                self.blurView?.removeFromSuperview()
            }
            
        }
    }
    
    private func addBlurView (superview: UIView) -> UIView {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = superview.bounds
        blurEffectView.isUserInteractionEnabled = true
        superview.addSubview(blurEffectView)
        
        return blurEffectView
    }
}
