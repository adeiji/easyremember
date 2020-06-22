//
//  ReadPDFController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 6/19/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import PDFKit
import FolioReaderKit

class ReadPDFController: UIViewController, CustomTextMenu {
    
    weak var pdfView:PDFView?
    
    let pdfUrl:URL
    
    init(pdfUrl: URL) {
        self.pdfUrl = pdfUrl
        super.init(nibName: nil, bundle: nil)
        self.createMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pdfView = PDFView()
        self.view.addSubview(pdfView)
        pdfView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        self.pdfView = pdfView
        self.pdfView?.displayMode = .singlePageContinuous
        self.pdfView?.displaysAsBook = true
        
        
        if let document = PDFDocument(url: self.pdfUrl) {
            pdfView.document = document
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: Notification.Name.PDFViewPageChanged, object: nil)
    }
    
    @objc func handlePageChange(notification: Notification) {
        self.saveCurrentPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let currentPage = self.getSavedPagedLocation() {
            self.gotoPageNumber(currentPage)
        }
    }
    
    private func getSavedPagedLocation () -> Int? {
        let userDefaults = UserDefaults.standard
        return userDefaults.object(forKey: self.pdfUrl.lastPathComponent) as? Int
    }
    
    private func gotoPageNumber (_ pageNumber: Int) {
        guard let page = self.pdfView?.document?.page(at: pageNumber - 1) else { return }
        self.pdfView?.go(to: page)
    }
    
    private func saveCurrentPage()
    {
        guard let pageNumber = self.pdfView?.currentPage?.pageRef?.pageNumber else { return }
        let userDefaults = UserDefaults.standard
        userDefaults.set(pageNumber, forKey: self.pdfUrl.lastPathComponent)
        userDefaults.synchronize()
    }
    
    @objc func define(_ sender: UIMenuController?) {
        guard let selection = self.pdfView?.currentSelection?.string else { return }
        guard let vc = self.getDefineScreenForText(selection, tintColor: UIColor.white.dark(.black)) else { return }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc internal func createCardButtonPressed (_ sender: UIMenuController?) {
        self.postCreateCardButtonPressed(sender)
    }
    
    @objc internal func translateButtonPressed (_ sender: UIMenuController?) {
        self.postTranslateButtonPressed(sender)
    }
            
    func createMenu () {
        let menuController = UIMenuController.shared
                                                                        
        let defineItem = UIMenuItem(title: "Define", action: #selector(define(_:)))
        var menuItems: [UIMenuItem] = []

        menuItems.append(defineItem)
                                
        let translateItem = UIMenuItem(title: "Translate", action: #selector(translateButtonPressed(_:)))
        menuItems.append(translateItem)
        
        let createCardItem = UIMenuItem(title: "Create Card", action: #selector(createCardButtonPressed(_:)))
        
        menuItems.append(createCardItem)
                
        menuController.menuItems = menuItems
    }
    
}
