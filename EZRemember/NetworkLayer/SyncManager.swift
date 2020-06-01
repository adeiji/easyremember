//
//  SyncManager.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/20/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import DephynedFire
import RxSwift
import Firebase
import FirebaseFirestore

class SyncManager {
    
    static let shared = SyncManager()
    
    let disposeBag = DisposeBag()
    
    func backupEpubs (filenames: [String]) -> Completable {
        
        return Completable.create { completable in
            FirebasePersistenceManager.updateDocument(withId: UtilityFunctions.deviceId(), collection: Sync.collectionName, updateDoc: [ Sync.Keys.kBooks: FieldValue.arrayUnion(filenames) ]) { (error) in
                if let error = error {
                    completable(.error(error))
                    return
                }
                
                completable(.completed)
            }
            
            return Disposables.create()
        }        
    }
    
    fileprivate func saveSyncingInformation(_ sync: Sync) -> Completable {
        do {
            // Convert the sync object to a dictionary
            let data = try JSONEncoder().encode(sync)
            guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
                assertionFailure("Baaka, why is this Sync object not of type [String:Any]")
                return .empty()
            }
            
            return Completable.create { completable in
                // Save the sync document to the server
                FirebasePersistenceManager.addDocument(withCollection: Sync.collectionName, data: dict, withId: sync.deviceId) { (error, document) in
                    
                    let ebookHandler = EBookHandler()
                    ebookHandler.backupEbooksAtUrls()
                    
                    if let error = error {
                        completable(.error(error))
                        return
                    }
                    
                    completable(.completed)
                    return
                }
                
                return Disposables.create()
            }                        
        } catch {
            assertionFailure("Baaka, the Sync object is not Encodable, why?")
            print(error.localizedDescription)
            return .empty()
        }
    }
    
    func syncWithEmail (sync: Sync, completion: @escaping (Bool, Error?) -> Void) {
        
        let getDocuments = FirebasePersistenceManager.getDocumentsAsObservable(withCollection: Sync.collectionName, queryDocument: [Sync.Keys.kEmail: sync.email.lowercased() ])
        
        getDocuments.subscribe { [weak self] (event) in
            guard let self = self else { return }
                        
            if event.isCompleted { return }
            
            // If this email already has been used to sync data, than grab the data associated with this email now
            if let documents = event.element, documents.count > 0 {
                
                // Get the sync object from the server
                guard let sync = (FirebasePersistenceManager.getObjectsFromFirebaseDocuments(fromFirebaseDocuments: documents) as [Sync]?)?.first else { return }
    
                let ebookHandler = EBookHandler()
                ebookHandler.downloadBooks(sync: sync)
                FirebasePersistenceManager.shared.saveFcmToken(Messaging.messaging().fcmToken, forceSave: true)
                // Sync with the information attached to this user's email address
                NotificationsManager.sync(sync.deviceId)
                UtilityFunctions.addSyncEmail(sync.email)
                completion(true, nil)
            } else {
                // If this email contains no documents attached to it, meaning that it's the first time that this user is using this email to sync data with, than save the syncing information to the server
                self.saveSyncingInformation(sync).subscribe(onCompleted: {
                    completion(true, nil)
                }) { (error) in
                    completion(false, error)
                }.disposed(by: self.disposeBag)
            }
            
        }.disposed(by: self.disposeBag)
    }
    
}
