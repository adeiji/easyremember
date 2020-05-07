//
//  FirebasePersistanceManager+Watching.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import DephynedFire
import FirebaseFirestore

extension FirebasePersistenceManager {
    
    open class func getDocumentAndWatch (docId: String, collectionName: String, completion: @escaping FirebaseRequestClosure) -> ListenerRegistration {
        let db = Firestore.firestore()
        let subscription = db.collection(collectionName).document(docId).addSnapshotListener(includeMetadataChanges: true) { (document, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            if let document = document {
                let firebaseDocument = self.convertDocSnapshotToFirebaseDoc(document: document)
                completion(nil, firebaseDocument)
            }
        }
        
        return subscription
    }
    
}
