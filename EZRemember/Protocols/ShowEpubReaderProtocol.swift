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
    var bookName:String { get set }
}

extension ShowEpubReaderProtocol {
    
    func test () {
        let config = FolioReaderConfig()
        let bookPath = Bundle.main.path(forResource: "Dune", ofType: "epub")
        let folioReader = FolioReader()
        folioReader.presentReader(parentViewController: self, withEpubPath: bookPath!, andConfig: config)
    }
    
    @discardableResult func showBookReader (url: URL?) -> FolioReader? {
        
        guard let url = url else { return nil }
                
        let config = FolioReaderConfig()
        config.displayTitle = true
        let folioReader = FolioReader()
        
        let ebookHandler = BookHandler()
                        
        if url.pathExtension.lowercased() == "pdf" {
            let title = url.lastPathComponent
            let readBookViewVC = GRReadBookViewController(pdfUrl: url.path, bookName: title)
            self.navigationController?.pushViewController(readBookViewVC, animated: true)
            return nil
        }
        
        let title = ebookHandler.getTitleFromBookPath(url.path)
        let reader = ebookHandler.getReader(url: url, folioReader: folioReader, parentVC: self)
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
