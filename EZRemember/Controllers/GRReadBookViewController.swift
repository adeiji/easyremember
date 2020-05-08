//
//  GRReadBookViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/8/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwiftyBootstrap
import FolioReaderKit

class GRReadBookViewController: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
    let bookName = "Dune"
    
    let navBarHeight:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 75 : 50
    
    weak var readerView:UIView?
    
    weak var translationView:UIView?
    
    let reader:FolioReaderContainer
    
    open weak var translateWord:UIButton?
    
    public var wordToTranslate:String?
    
    private var disposeBag = DisposeBag()
    
    init(reader: FolioReaderContainer) {
        self.reader = reader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        let readerView:UIView = UIView()
        let translationView:UIView = UIView()
        translationView.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0)
        let backButton = GRButton(type: .Back)
        let mainViewCard = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: true, margin: BootstrapMargin(
            left: 0,
            top: 40,
            right: 0,
            bottom: 0))
        .addRow(columns: [
            Column(cardSet: backButton.toCardSet().withHeight(self.navBarHeight), colWidth: .One),
            Column(cardSet: Style.label(withText: self.bookName, superview: nil, color: .black, textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet().withHeight(self.navBarHeight)
                , colWidth: .Ten),
            Column(cardSet: UIView().toCardSet().withHeight(self.navBarHeight), colWidth: .One),
            ]).addRow(columns: [
                Column(cardSet: readerView.toCardSet(), colWidth: .Eight, anchorToBottom: true),
                Column(cardSet: translationView.toCardSet(), colWidth: .Four)
            ], anchorToBottom: true)
                        
        mainViewCard.addToSuperview(superview: self.view, anchorToBottom: true)
        
        self.readerView = readerView
        self.translationView = translationView
        
        self.view.layoutIfNeeded()
        
        backButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(createMenuCalled), name: .CreateMenuCalled, object: nil)
                
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addChildViewControllerWithView(self.reader, toView: self.readerView)
    }
    
    // MARK: Create Menu Called
    
    @objc public func createMenuCalled (_ notification: Notification) {
        
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        
        self.wordToTranslate = word
        
        if self.translateWord != nil {
            return
        }
        
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 20.0)
        
        self.readerView?.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.readerView ?? self.view).offset(-10)
            make.centerX.equalTo(self.readerView ?? self.view)
            make.height.equalTo(60)
            make.width.equalTo(170)
        }
        
        translateButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let wordToTranslate = self.wordToTranslate else { return }
            let loading = translateButton.showLoadingNVActivityIndicatorView()
            
            TranslateManager.translateText(wordToTranslate).subscribe { [weak self] (event) in
                guard let self = self else { return }
                translateButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.translateWord?.removeFromSuperview()
                self.translateWord = nil
                if let translations = event.element {
                    let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordToTranslate)
                    self.addChildViewControllerWithView(showTranslationsViewController, toView: self.translationView)
                }
            }.disposed(by: self.disposeBag)
        }
        
        self.translateWord = translateButton
    }
    
    // MARK: Ebook Reader
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWord?.removeFromSuperview()
        self.translateWord = nil
    }
    
}
