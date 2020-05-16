//
//  ShowEpubReaderProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/10/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import FolioReaderKit
import SwiftyBootstrap
import RxSwift

protocol ShowEpubReaderProtocol: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
    var readerContainer:FolioReaderContainer? { get set }
    
    var wordsToTranslate:String? { get set }
    
    var disposeBag:DisposeBag { get }
    
    var translateWordButton:UIButton? { get set }
    
    /// The name of the book
    var bookName:String { get }
}

extension ShowEpubReaderProtocol {
    
    @discardableResult func showBookReader (url: URL?) -> FolioReader? {
        
        guard let url = url else { return nil }
                
        let config = FolioReaderConfig()
        config.displayTitle = true
        let folioReader = FolioReader()
        
        // If the device is large enough we want to push the epub reader as opposed to presenting it, and the larger screen has
        // a different layout as well
        
        // Push the Read Book View Controller which will show the book on the left hand side
        let title = try? FolioReader.getTitle(url.path)
        let reader = folioReader.getReader(parentViewController: self, withEpubPath: url.path, andConfig: config, shouldRemoveEpub: false)
        let readBookViewVC = GRReadBookViewController(reader: reader, folioReader: folioReader, bookName: title ?? "No Name")
        self.navigationController?.pushViewController(readBookViewVC, animated: true)
        return nil
        
    }
    
    // MARK: Create Menu Called
    
    public func createMenuCalled (_ notification: Notification) {
        
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        guard let readerContainer = self.readerContainer else { return }
        self.wordsToTranslate = word
        
        if self.translateWordButton != nil {
            return
        }
        
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 20.0)
        
        readerContainer.view.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(readerContainer.view).offset(-10)
            make.centerX.equalTo(readerContainer.view)
            make.height.equalTo(60)
            make.width.equalTo(170)
        }
        
        translateButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let wordToTranslate = self.wordsToTranslate else { return }
            let loading = translateButton.showLoadingNVActivityIndicatorView()
            
            TranslateManager.translateText(wordToTranslate).subscribe { [weak self] (event) in
                guard let self = self else { return }
                translateButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.translateWordButton?.removeFromSuperview()
                self.translateWordButton = nil
                if let translations = event.element {
                    let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordToTranslate, languages: ScheduleManager.shared.getLanguages(), bookTitle: self.bookName)
                    showTranslationsViewController.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
                    readerContainer.present(showTranslationsViewController, animated: true, completion: nil)
                }
            }.disposed(by: self.disposeBag)
        }
        
        self.translateWordButton = translateButton
    }
    
}
