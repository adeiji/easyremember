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

protocol ShowEpubReaderProtocol: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
}

extension UIViewController: FolioReaderPageDelegate, FolioReaderCenterDelegate {
    func showBookReader (url: URL?) {
        
        guard let url = url else { return }
                
        let config = FolioReaderConfig()
        config.displayTitle = true
        let folioReader = FolioReader()
        
        if GRDevice.smallerThan(.md) == false {
            // Push the Read Book View Controller which will show the book on the left hand side
            let title = try? FolioReader.getTitle(url.path)
            let reader = folioReader.getReader(parentViewController: self, withEpubPath: url.path, andConfig: config, shouldRemoveEpub: false)
            let readBookViewVC = GRReadBookViewController(reader: reader, folioReader: folioReader, bookName: title ?? "No Name")
            self.navigationController?.pushViewController(readBookViewVC, animated: true)            
        } else {
            folioReader.presentReader(parentViewController: self, withEpubPath: url.path, andConfig: config)
            folioReader.readerCenter?.pageDelegate = self
            folioReader.readerCenter?.delegate = self
        }
        
    }
}
