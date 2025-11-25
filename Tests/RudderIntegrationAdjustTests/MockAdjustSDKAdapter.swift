//
//  MockAdjustSDKAdapter.swift
//  RudderIntegrationAdjust
//
//  Created by Satheesh Kannan on 25/11/25.
//

import Testing
import AdjustSdk
import RudderStackAnalytics
@testable import RudderIntegrationAdjust

// MARK: - Mock Adapter
/**
 Mock implementation of AdjustSDKAdapter for testing purposes
*/
final class MockAdjustSDKAdapter: AdjustSDKAdapter {
    var initCalled = false
    var initConfig: ADJConfig?

    var trackCalled = false
    var trackedEvent: ADJEvent?

    var setPartnerParamsCalled = false
    var partnerPayload: Event?

    var removeGlobalPartnerParametersCalled = false
    var onAttributionChanged: ((ADJAttribution) -> Void)?
    
    func initSDK(adjustConfig: ADJConfig?) {
        initCalled = true
        initConfig = adjustConfig
    }

    func track(event: ADJEvent) {
        trackCalled = true
        trackedEvent = event
    }

    func setPartnerParams(payload: Event) {
        setPartnerParamsCalled = true
        partnerPayload = payload
    }

    func removeGlobalPartnerParameters() {
        removeGlobalPartnerParametersCalled = true
    }
}

// MARK: - Callback Spy (for attribution callback)
/**
 Spy class to capture attribution callback invocations for testing
*/
final class AttributionCallbackSpy {
    var invoked = false
    var received: ADJAttribution?
}
