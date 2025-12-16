//
//  AdjustSDKAdapter.swift
//  RudderIntegrationAdjust
//
//  Created by Satheesh Kannan on 25/11/25.
//

import Foundation
import AdjustSdk
import RudderStackAnalytics

/**
 Protocol to abstract Adjust SDK interactions for easier testing
*/
protocol AdjustSDKAdapter {
    var adjustInstance: Any? { get set }
    func initSDK(adjustConfig: ADJConfig?)
    func track(event: ADJEvent)
    func setPartnerParams(payload: Event)
    func removeGlobalPartnerParameters()
    var onAttributionChanged: ((ADJAttribution) -> Void)? { get set }
}

/**
 Default implementation of AdjustSDKAdapter using the actual Adjust SDK
*/
class DefaultAdjustSDKAdapter: AdjustSDKAdapter {
    
    var adjustInstance: Any?
    
    var onAttributionChanged: ((ADJAttribution) -> Void)?
    
    func initSDK(adjustConfig: ADJConfig?) {
        guard adjustInstance == nil else { return }
        Adjust.initSdk(adjustConfig)
        
        self.adjustInstance = Adjust.getInstance()
    }
    
    func track(event: ADJEvent) {
        guard adjustInstance != nil else {
            LoggerAnalytics.error("DefaultAdjustSDKAdapter: Adjust SDK not initialized. Cannot track event.")
            return
        }
        Adjust.trackEvent(event)
    }
    
    func setPartnerParams(payload: Event) {
        guard adjustInstance != nil else {
            LoggerAnalytics.error("DefaultAdjustSDKAdapter: Adjust SDK not initialized. Cannot set partner parameters.")
            return
        }
        
        if let anonymousId = payload.anonymousId {
            Adjust.addGlobalPartnerParameter(anonymousId, forKey: "anonymousId")
        }
        if let userId = payload.userId, !userId.isEmpty {
            Adjust.addGlobalPartnerParameter(userId, forKey: "userId")
        }
    }
    
    func removeGlobalPartnerParameters() {
        guard adjustInstance != nil else {
            LoggerAnalytics.error("DefaultAdjustSDKAdapter: Adjust SDK not initialized. Cannot remove partner parameters.")
            return
        }
        Adjust.removeGlobalPartnerParameters()
    }
}
