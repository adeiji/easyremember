//
//  TranslationProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/29/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwiftyBootstrap

protocol TranslationProtocol: AnyObject {
    var disposeBag:DisposeBag { get }
}

extension TranslationProtocol {
    
    func translateButtonPressed (_ translateButton: UIButton?, wordsToTranslate: String, completion: @escaping (Translations) -> Void) {
        
        let loading = translateButton?.showLoadingNVActivityIndicatorView()
        
        TranslateManager.translateText(wordsToTranslate).subscribe { [weak self] (event) in
            guard let _ = self else { return }
            translateButton?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
            translateButton?.isHidden = true
            
            if let translations = event.element {
                completion(translations)
            }
        }.disposed(by: self.disposeBag)
    }
        
}
