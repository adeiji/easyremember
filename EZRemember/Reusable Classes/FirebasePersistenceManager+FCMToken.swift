//
//  FirebasePersistenceManager+FCMToken.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/20/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import DephynedFire

extension FirebasePersistenceManager {
    
    open func saveFcmToken (_ fcmToken: String?, forceSave:Bool = false) {
        guard let fcmToken = fcmToken else { return }
        
        if self.getFCMToken() == fcmToken && forceSave == false {
            return
        }
        
        let token = FCMToken(deviceId: UtilityFunctions.deviceId(), token: fcmToken)
        
        if let currentToken = self.getFCMToken() {
            self.deleteOldTokenFromServer(token: currentToken)
        }
        
        self.saveFCMToken(fcmToken)
        guard let data = try? JSONEncoder().encode(token) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return }
        
        FirebasePersistenceManager.addDocument(withCollection: FCMToken.collectionName, data: dict) { (error, documents) in
            if let error = error {
                AnalyticsManager.logError(message: error.localizedDescription)
                print(error.localizedDescription)
            }
        }
    }
    
    private func deleteOldTokenFromServer (token:String) {
        FirebasePersistenceManager.deleteDocuments(withCollection: FCMToken.collectionName, queryDocument: ["token": token], documentId: nil, completion: nil)
    }
    
    public func getFCMToken () -> String? {
        let userDefaults = UserDefaults()
        return userDefaults.object(forKey: self.kFcmToken) as? String
    }
    
    private func saveFCMToken (_ fcmToken:String) {
        let userDefaults = UserDefaults()
        userDefaults.set(fcmToken, forKey: self.kFcmToken)
        userDefaults.synchronize()
    }
    
}
