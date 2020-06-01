//
//  DecksViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/29/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxCocoa
import RxSwift

class DecksViewController: UIViewController, AddCancelButtonProtocol {
    
    weak var mainView:GRViewWithTableView?
    
    let deckRelay = BehaviorRelay<[Deck]>(value: [])
    
    var decks:[Deck] = [Deck]()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getDecks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                        
        if self.mainView != nil {
            return
        }
        
        self.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        
        let mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "Premade Decks", rightNavBarButtonTitle: "Done")
        mainView.navBar.header?.textColor = UIColor.black.dark(.white)
        mainView.navBar.backgroundColor = .clear
        mainView.navBar.leftButton?.isHidden = true
        mainView.tableView.register(DeckCell.self, forCellReuseIdentifier: DeckCell.reuseIdentifier)
        mainView.tableView.rowHeight = UITableView.automaticDimension
        mainView.tableView.estimatedRowHeight = 300
        self.mainView = mainView
        
        mainView.navBar.rightButton?.addTargetClosure(closure: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        })
        
        self.displayDecks()
        
    }
    
    private func getDecks () {
        NotificationsManager.shared.getDecks { [weak self] (decks) in
            guard let self = self else { return }
            self.decks = decks
            self.deckRelay.accept(decks)
        }
    }
    
    private func displayDecks () {
        guard let tableView = self.mainView?.tableView else { return }
        let loading = tableView.showLoadingNVActivityIndicatorView()
        
        self.deckRelay.bind(to: tableView.rx.items(cellIdentifier: DeckCell.reuseIdentifier, cellType: DeckCell.self)) { (row, deck, cell) in
            tableView.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            cell.deck = deck
            
            self.setupDeleteButton(cell.removeButton, deck: deck)
            if cell.isFinishedInstalling { return }
                                    
            self.setupInstallButton(cell.installButton, deck: deck, cell: cell)
        }.disposed(by: self.disposeBag)
    }
    
    
    private func setupInstallButton (_ installButton: UIButton?, deck: Deck, cell: DeckCell) {
        installButton?.addTargetClosure(closure: { [weak self] (button) in
            guard let self = self else { return }
            
            self.askToInstall(completion: { [weak self] (shouldInstall) in
                guard let _ = self else { return }
                
                let loading = button.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.shared.saveCardsFromDeck(deck) { (notifications) in
                    NotificationCenter.default.post(name: .DeckSaved, object: nil, userInfo: [GRNotification.kSavedNotifications: notifications])
                    button.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                    cell.finishedInstalling()
                }
            })
        })
    }
    
    private func setupDeleteButton (_ removeButton: UIButton?, deck: Deck) {
        removeButton?.addTargetClosure(closure: { [weak self] (button) in
            guard let self = self else { return }
            self.askToDelete { [weak self] (shouldDelete) in
                guard let self = self else { return }
                
                let loading = removeButton?.showLoadingNVActivityIndicatorView()
                
                NotificationsManager.shared.removeCardsFromDeck(deck) { (success) in
                    removeButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                    if success {
                        self.showFinishedDeleting()
                        NotificationCenter.default.post(name: .DeckRemoved, object: nil, userInfo: [GRNotification.Keys.kDeckId: deck.id])
                    } else {
                        self.showFinishedDeleting(error: "Looks like we had a problem removing this deck.  This is typicallly due to a poor internet connection.  Please check your internet connection and then try again.")
                    }
                }
            }
        })
    }
    
    private func showFinishedDeleting (error: String? = nil) {
        let messageCard = GRMessageCard()
        messageCard.draw(message: error == nil ? "Finished removing this deck from your notifications." : "\(error!)", title: "Finished Removing", superview: self.view)
        
    }
    
    private func askToDelete (completion: @escaping (Bool) -> Void) {
        
        let messageCard = GRMessageCard()
        messageCard.draw(
            message: "Are you sure you want to remove all the cards from this deck from your notification cards?",
            title: "Are you sure?",
            superview: self.view,
            buttonText: "Remove Cards",
            cancelButtonText: "Don't Remove Cards")
        
        messageCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let _ = self else { return }
            messageCard.close()
            completion(true)
        })
        
    }
    
    private func askToInstall (completion: @escaping (Bool) -> Void) {
        let messageCard = GRMessageCard()
        messageCard.draw(
            message: "If you've added this deck previously, than these cards will be added again, and you will have duplicate cards.  Do you still want to add these cards?",
            title: "Have you added this deck before?",
            superview: self.view,
            buttonText: "Add Cards",
            cancelButtonText: "Don't Add Cards")
        
        messageCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let _ = self else { return }
            messageCard.close()
            completion(true)
        })
    }
}
