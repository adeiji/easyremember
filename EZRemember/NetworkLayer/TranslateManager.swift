//
//  TranslateManager.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import RxSwift
import DephynedFire

public struct Translations: Codable {
    
    struct Keys {
        static let kCollectionName = "translations"
        static let kId = "id"
        static let kInput = "input"
        static let kTranslated = "translated"
    }
    
    
    let input:String?
    let translated:[String:String]
    
}

class TranslateManager {
    
    static func translateText (_ text: String) -> Observable<Translations> {
        
        let id = UUID().uuidString
        
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.addDocument(withCollection: Translations.Keys.kCollectionName, data: [Translations.Keys.kInput : text], withId: id) { (error, document) in
                let _ = FirebasePersistenceManager.getDocumentAndWatch(docId: id, collectionName: Translations.Keys.kCollectionName) { (error, document) in
                                                            
                    if let document = document {
                        let translations = FirebasePersistenceManager.generateObject(fromFirebaseDocument: document) as Translations?
                        
                        // If this is the translated document than return a value
                        if let translationsUnwrapped = translations {
                            observer.onNext(translationsUnwrapped)
                            observer.onCompleted()
                        }
                    }
                    
                    if let error = error {
                        observer.onError(error)
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
}

