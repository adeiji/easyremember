//
//  ShowEpubReaderProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/10/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import FolioReaderKit

protocol ShowEpubReaderProtocol: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
}

extension ShowEpubReaderProtocol {
    func showBookReader (url: URL?) {
        
        guard let url = url else { return }
        
        
        let config = FolioReaderConfig()
        config.displayTitle = true
        let folioReader = FolioReader()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Push the Read Book View Controller which will show the book on the left hand side
            let title = try? FolioReader.getTitle(url.path)
            let reader = folioReader.getReader(parentViewController: self, withEpubPath: url.path, andConfig: config, shouldRemoveEpub: false)
            let readBookViewVC = GRReadBookViewController(reader: reader, bookName: title ?? "No Name")
            folioReader.readerCenter?.pageDelegate = readBookViewVC
            folioReader.readerCenter?.delegate = readBookViewVC
            self.navigationController?.pushViewController(readBookViewVC, animated: true)
        } else {
            folioReader.presentReader(parentViewController: self, withEpubPath: url.path, andConfig: config)
//            folioReader.readerCenter?.pageDelegate = self
//            folioReader.readerCenter?.delegate = self
        }
        
    }
}
