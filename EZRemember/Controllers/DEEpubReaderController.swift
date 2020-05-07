//
//  DEEpubReaderController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import FolioReaderKit
import SwiftyBootstrap
import RxSwift

public class DEEpubReaderController: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
    open var currentPage:FolioReaderPage?
    
    open weak var translateWord:UIButton?
    
    public var wordToTranslate:String?
    
    public var disposeBag:DisposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = FolioReaderConfig()
        config.displayTitle = true
        let bookPath = Bundle.main.path(forResource: "Dune", ofType: "epub")
        let folioReader = FolioReader()
        
        folioReader.presentReader(parentViewController: self, withEpubPath: bookPath!, andConfig: config)
        folioReader.readerCenter?.pageDelegate = self
        folioReader.readerCenter?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(createMenuCalled), name: .CreateMenuCalled, object: nil)
        
    }
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWord?.removeFromSuperview()
        self.translateWord = nil
    }
    
    @objc public func createMenuCalled (_ notification: Notification) {
        
        
        guard let presentedViewController = self.presentedViewController else { return }
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        self.wordToTranslate = word
        
        if self.translateWord != nil {
            return
        }
        
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 20.0)
        
        presentedViewController.view.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(presentedViewController.view).offset(-10)
            make.centerX.equalTo(presentedViewController.view)
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
                    presentedViewController.present(showTranslationsViewController, animated: true, completion: nil)
                }
            }.disposed(by: self.disposeBag)
        }
        
        self.translateWord = translateButton
    }
    
    
    
    public func pageDidAppear(_ page: FolioReaderPage) {
        self.currentPage = page
    }
    
    
    
    
}
