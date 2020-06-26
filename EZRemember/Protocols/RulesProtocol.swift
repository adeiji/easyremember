//
//  RulesProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/12/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import DephynedPurchasing
import SwiftyBootstrap


/** Protocol for handling the rules of an application that have to do with purchasing.  So for example, based off of specific tiers, a user
 is able to do or not do certain things.  This protocol is for the handling of these various rules */
protocol RulesProtocol {
    
    typealias RuleKey = String
    
    /**
     Checks to see if given a value and rule, if the rule has been passed
     
     - parameters:
     - ruleName: The name of the rule
     - rule: What the rule is, max number of the specific rule that can be set.  Look at documentation for rules property for more information
     */
    func validatePassRuleOrShowFailure (_ ruleName: RuleKey, numberToValidate:Int, testing:Bool) -> Bool
    
}

extension RulesProtocol {
    
    private func validate (numberToValidate:Int, value:Int, ruleName:RuleKey) -> Bool {
        if value == 0 {
            return true
        }
        
        if numberToValidate > value {
            self.displayUpgradeMessage(ruleName: ruleName, rule: value)
        }
                        
        return numberToValidate <= value
    }
    
    func validatePassRuleOrShowFailure (_ ruleName: RuleKey, numberToValidate:Int, testing:Bool = false) -> Bool {
        
        #if DEBUG
//            return true
        #endif
        
        if testing {
            guard let value = Purchasing.Rules.Free.rules[ruleName] else {
                assertionFailure("Baaka, this rule does not exists, why?  Make sure you add the rule to the Purchasing.Rules.Free.rules array")
                return false
            }
            
            return self.validate(numberToValidate: numberToValidate, value: value, ruleName: ruleName)
        }
        
        let schedule = ScheduleManager.shared.getSchedule()
        
        if PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Premium.rawValue) ||
        schedule?.purchasedPackage == Schedule.PurchaseTypes.kPremium {
            guard let value = Purchasing.Rules.Premium.rules[ruleName] else {
                assertionFailure("Baaka, this rule does not exists, why? Make sure you add the rule to the Purchasing.Rules.Premium.rules array")
                return false
            }
            
            return self.validate(numberToValidate: numberToValidate, value: value, ruleName: ruleName)
        }
            
        else if PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Standard.rawValue) ||
        schedule?.purchasedPackage == Schedule.PurchaseTypes.kStandard {
            guard let value = Purchasing.Rules.Standard.rules[ruleName] else {
                assertionFailure("Baaka, this rule does not exists, why? Make sure you add the rule to the Purchasing.Rules.Standard.rules array")
                return false
            }

            return self.validate(numberToValidate: numberToValidate, value: value, ruleName: ruleName)
        }
            
        else if PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Basic.rawValue) ||
        schedule?.purchasedPackage == Schedule.PurchaseTypes.kBasic {
            guard let value = Purchasing.Rules.Basic.rules[ruleName] else {
                assertionFailure("Baaka, this rule does not exists, why? Make sure you add the rule to the Purchasing.Rules.Basic.rules array")
                return false
            }
            
            return self.validate(numberToValidate: numberToValidate, value: value, ruleName: ruleName)
        }
            
        else {
            guard let value = Purchasing.Rules.Free.rules[ruleName] else {
                assertionFailure("Baaka, this rule does not exists, why?  Make sure you add the rule to the Purchasing.Rules.Free.rules array")
                return false
            }
            
            return self.validate(numberToValidate: numberToValidate, value: value, ruleName: ruleName)
        }
    }
    
    /**
     Display to the user that they need to upgrade to perform the current task and offer them the opportunity to upgrade
     
     - parameters:
        - ruleName: The name of the rule.  This can be accessed in Purchasing.Rules.  There's a list of keys there that you can choose from
        - rule: What is the rule? Basically, what is the number of this item in which they can't go past.  ie, if they can use 3 languages, then you the ruleName would be something like 'languages' and the rule would be 3.
     */
    private func displayUpgradeMessage (ruleName: RuleKey, rule:Int? = nil) {
        guard let topController = GRCurrentDevice.shared.getTopController() else { return }
        
        let message = Purchasing.Rules.getMessage(ruleName: ruleName, rule: rule)
        let messageCard = GRMessageCard()
        messageCard.draw(message: message, title: "Action not allowed", buttonBackgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), superview: topController.view, buttonText: "Upgrade", cancelButtonText: "Cancel", isError: false)
        
        messageCard.firstButton?.addTargetClosure(closure: { (_) in
            let purchasingVC = GRPurchasingViewController(purchaseableItems: Purchasing.purchaseItems)
            topController.present(purchasingVC, animated: true, completion: nil)
            messageCard.close()
        })                
    }
    
    public func purchasedOnline () -> Bool {
        return ScheduleManager.shared.getSchedule()?.purchasedPackage != nil
    }
    
    public func userHasSubscription (ruleName: RuleKey? = nil) -> Bool {
        
        #if DEBUG
            return true
        #endif
        
        guard let schedule = ScheduleManager.shared.getSchedule() else { return false }
        
        let hasSubscription =
            PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Basic.rawValue) ||
            PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Standard.rawValue) ||
            PKIAPHandler.shared.purchaseIsValid(purchaseId: Purchasing.ProductIds.Premium.rawValue) ||
            schedule.purchasedPackage != nil
        
        if let ruleName = ruleName {
            if hasSubscription == false {
                self.displayUpgradeMessage(ruleName: ruleName)
            }
        }
        
        return hasSubscription
    }
    
}
