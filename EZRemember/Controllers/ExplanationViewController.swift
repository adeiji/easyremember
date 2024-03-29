//
//  ExplanationViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/21/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class ExplanationViewController: UIViewController, AddCancelButtonProtocol {
    
    weak var mainView: GRViewWithScrollView?
    
    let explanation:Explanation
    
    init(explanation: Explanation) {
        self.explanation = explanation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addSectionImage(_ section: ExplanationSection, card:GRBootstrapElement) {
        if section.image == nil {
            return
        }
        
        let imageView = UIImageView(image: section.image)
        imageView.contentMode = .scaleAspectFit
        
        card.addRow(columns: [
            Column(cardSet: imageView.toCardSet().withHeight(section.largeImage ? 300 : 100).margin.top(50), xsColWidth: .Twelve),
        ])
    }
    
    fileprivate func addContent(_ section: ExplanationSection, card: GRBootstrapElement) {
        let contentLabel = Style.label(withText: "", superview: nil, color: .white)
            .font(CustomFontBook.Medium.of(size: .small))
        contentLabel.attributedText = section.content.addLineSpacing(amount: 15.0, centered: GRCurrentDevice.shared.size == .xs ? true : false)
        
        card.addRow(columns: [
            
            // CONTENT TITLE
            
            Column(cardSet: Style.label(withText: section.title, superview: nil, color: .white, textAlignment: GRCurrentDevice.shared.size == .xs ? .center : .left)
                .font(CustomFontBook.Medium.of(size: .large))
                .toCardSet()
                .margin.top(50), xsColWidth: .Twelve),
            
            // CONTENT
            
            Column(cardSet: contentLabel
                .toCardSet(), xsColWidth: .Twelve)
            
        ], anchorToBottom: section.id == self.explanation.sections.last?.id ? true : false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let mainView = GRViewWithScrollView().setup(superview: self.view, showNavBar: true)
        self.mainView = mainView
        self.addCancelButton(navBar: mainView.navBar, white: true)
        let margin = BootstrapMargin(left: .Five, top: .Five, right: .Five, bottom: .Five)
        
        self.mainView?.backgroundColor = UIColor.EZRemember.mainBlue.dark(Dark.coolGrey900)
        
        let card = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: true, margin: margin, superview: nil)
        
        self.explanation.sections.forEach { [weak self] (section) in
            guard let self = self else { return }
            self.addSectionImage(section, card: card)
            self.addContent(section, card: card)
        }
        
        card.addToSuperview(superview: self.mainView?.containerView ?? self.view, viewAbove: nil, anchorToBottom: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
}
