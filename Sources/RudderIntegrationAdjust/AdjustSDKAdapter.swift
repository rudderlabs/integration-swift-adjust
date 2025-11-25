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
public protocol AdjustSDKAdapter {
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
    var onAttributionChanged: ((ADJAttribution) -> Void)?
    
    func initSDK(adjustConfig: ADJConfig?) {
        Adjust.initSdk(adjustConfig)
    }
    
    func track(event: ADJEvent) {
        Adjust.trackEvent(event)
    }
    
    func setPartnerParams(payload: Event) {
        if let anonymousId = payload.anonymousId {
            Adjust.addGlobalPartnerParameter(anonymousId, forKey: "anonymousId")
        }
        if let userId = payload.userId, !userId.isEmpty {
            Adjust.addGlobalPartnerParameter(userId, forKey: "userId")
        }
    }
    
    func removeGlobalPartnerParameters() {
        Adjust.removeGlobalPartnerParameters()
    }
}
