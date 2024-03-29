//
//  DEShowTranslationsViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift

class DEShowTranslationsViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, AddCancelButtonProtocol {
    
    var mainView:GRViewWithCollectionView?
    let translations:Translations
    let originalWord:String
    let disposeBag = DisposeBag()
    var notificationsToSave = [GRNotification]()
    
    let bookTitle:String?
    
    weak var saveButton:UIButton?
    
    var languages:[String] = ["en"]
    
    
    init(translations:Translations, originalWord:String, languages:[String], bookTitle:String? = nil) {
        self.translations = translations
        self.originalWord = originalWord
        self.languages = languages
        self.bookTitle = bookTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.mainView?.collectionView?.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.mainView != nil {
            return
        }
        
        let saveButton = Style.largeButton(with: "Save")
        saveButton.backgroundColor = UIColor.EZRemember.mainBlue
        saveButton.radius(radius: 5)
        saveButton.setTitleColor(.white, for: .normal)
        self.view.addSubview(saveButton)
        saveButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.view).offset(-40)
            make.top.equalTo(self.view).offset(40)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
        
        let mainView = GRViewWithCollectionView().setup(superview: self.view, columns: 1)
        mainView.collectionView?.register(GRNotificationCard.self, forCellWithReuseIdentifier: GRNotificationCard.reuseIdentifier)
        mainView.backgroundColor = .clear
        mainView.collectionView?.backgroundColor = .clear
        
        mainView.addToSuperview(superview: self.view, viewAbove: saveButton, anchorToBottom: true)
        self.mainView = mainView
        self.saveButton = saveButton        
        
        self.showTranslations()
        self.saveButtonPressed()
    }
    
    private func saveButtonPressed () {
        let notificationsManager = NotificationsManager()
        
        self.saveButton?.addTargetClosure(closure: { [weak self] (saveButton) in
            guard let self = self else { return }
            
            saveButton.showLoadingNVActivityIndicatorView()            
            notificationsManager.saveNotifications(self.notificationsToSave) { [weak self] (success) in
                guard let self = self else { return }
                if success {
                    NotificationCenter.default.post(name: .NotificationsSaved, object: nil, userInfo: [ GRNotification.kSavedNotifications: self.notificationsToSave ])
                    self.notificationsToSave = []
                }
                if self.navigationController != nil {
                    saveButton.showFinishedLoadingNVActivityIndicatorView()
                }
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }            
    
    func showTranslationForLanguage (_ language:(key: String, value: String)) -> Bool {
        
        if (ScheduleManager.shared.getLanguages().contains(language.key) == true) {
            return true
        }
        
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        return CGSize(width: width - 10, height: 350)
        
     }
    
    func showTranslations () {
        guard let collectionView = self.mainView?.collectionView else { return }
        collectionView.rx.setDelegate(self).disposed(by: self.disposeBag)
        
        let translations = self.translations.translated.filter( {self.showTranslationForLanguage($0) })
        let translationsObserverable = Observable.of(translations)
        
        translationsObserverable.subscribe { [weak self] (event) in
            guard let _ = self else { return }
            guard let translations = event.element else { return }
            if translations.count == 0 {
                collectionView.setEmptyMessage(message: "No Translations", header: "Translations", imageName: "")
            }
        }.disposed(by: self.disposeBag)
        
        translationsObserverable
            .bind(to:
                collectionView
                    .rx
                    .items(cellIdentifier: GRNotificationCard.reuseIdentifier, cellType: GRNotificationCard.self)) { [weak self] (row, translation, cell) in
                        guard let self = self else { return }
                        
                        var originalWord = self.originalWord
                        
                        if self.originalWord.isIncludeChinese() {
                            originalWord = "\(self.originalWord) \(originalWord.transformToPinyin())"
                        }
                        var notification = GRNotification(caption: originalWord, description: translation.value, language: GRNotification.kSupportedLanguages[translation.key])
                        notification.bookTitle = self.bookTitle
                        
                        // If the table view is showing a background view because it was empty, then reset it to it's normal state
                        collectionView.reset()
                        cell.isTranslation = true
                        cell.notification = notification
                        if (self.notificationsToSave.contains(where: { $0.description == translation.value })) {
                            cell.toggleActivateButton?.isHidden = true
                        }
                        cell.deleteButton?.isHidden = true
                        
                        cell.toggleActivateButton?.addTargetClosure(closure: { [weak self] (_) in
                            guard let self = self else { return }
                            guard let notification = cell.notification else { return }
                                                                                    
                            if (self.notificationsToSave.contains(where: { $0.id == notification.id })) {
                                cell.toggleActiveButtonState(false)
                                self.notificationsToSave = self.notificationsToSave.filter({ $0.id != notification.id })
                            } else {
                                cell.toggleActiveButtonState(true)
                                self.notificationsToSave.append(notification)
                            }
                        })
                        
        }.disposed(by: self.disposeBag)
                
    }
    
}
