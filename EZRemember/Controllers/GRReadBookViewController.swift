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
    
    let bookName:String
    
    let navBarHeight:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 75 : 50
    
    weak var readerView:UIView?
    
    weak var translationView:UIView?
    
    let reader:FolioReaderContainer
    
    private var currentPage:FolioReaderPage?
    
    private var folioReader:FolioReader
    
    open weak var translateWord:UIButton?
    
    private var disposeBag = DisposeBag()
    
    public var languages:[String] = ["en"]
    
    init(reader: FolioReaderContainer , folioReader: FolioReader, bookName: String) {
        self.reader = reader
        self.bookName = bookName
        self.folioReader = folioReader
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
            left: .Zero,
            top: .Five,
            right: .Zero,
            bottom: .Five))
        .addRow(columns: [
            Column(cardSet: backButton.toCardSet().withHeight(self.navBarHeight), xsColWidth: .One),
            Column(cardSet: Style.label(withText: self.bookName, superview: nil, color: .black, textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet().withHeight(self.navBarHeight)
                , xsColWidth: .Ten),
            Column(cardSet: UIView().toCardSet().withHeight(self.navBarHeight), xsColWidth: .One),
            ]).addRow(columns: [
                Column(cardSet: readerView.toCardSet(), xsColWidth: .Eight, anchorToBottom: true),
                Column(cardSet: translationView.toCardSet(), xsColWidth: .Four)
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
        self.folioReader.readerCenter?.pageDelegate = self
        self.folioReader.readerCenter?.delegate = self
    }
    
    // MARK: Create Menu Called
    
    @objc public func createMenuCalled (_ notification: Notification) {
        
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        
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
            let loading = translateButton.showLoadingNVActivityIndicatorView()
            guard let wordsToTranslate = self.currentPage?.webView?.js("getSelectedText()") else { return }
            TranslateManager.translateText(wordsToTranslate).subscribe { [weak self] (event) in
                guard let self = self else { return }
                translateButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.translateWord?.removeFromSuperview()
                self.translateWord = nil
                if let translations = event.element {
                    let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordsToTranslate, languages: self.languages)
                    self.translationView?.subviews.forEach({ [weak self] (subview) in
//                        subview.removeFromSuperview()
                    })
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
    
    func pageDidAppear(_ page: FolioReaderPage) {
        self.currentPage = page
    }
    
}
