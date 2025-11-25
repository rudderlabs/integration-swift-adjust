//  AdjustIntegrationTests.swift
//  integration-swift-adjust
//
//  Created by Satheesh Kannan on 24/11/25.
//

import Testing
import AdjustSdk
import RudderStackAnalytics
@testable import RudderIntegrationAdjust

// MARK: - AdjustIntegration Tests

@Suite("AdjustIntegration Tests", .serialized)
class AdjustIntegrationTests {
    
    var mockAdaptor: MockAdjustSDKAdapter
    var integration: AdjustIntegration
    let testAppToken = "AppToken_123"
    
    init() {
        mockAdaptor = MockAdjustSDKAdapter()
        integration = AdjustIntegration(adjustSDKAdapter: mockAdaptor)
    }

    // MARK: - create()
    @Test("when create() is called, then it should initialize Adjust with correct config")
    func testCreateInitialization() throws {
        let config: [String: Any] = [
            "appToken": testAppToken,
            "logLevel": 4,  // debug → sandbox
            "enableInstallAttributionTracking": true
        ]
        
        try integration.create(destinationConfig: config)
        
        #expect(self.mockAdaptor.initCalled == true)
        #expect(self.mockAdaptor.initConfig != nil)
        #expect(self.mockAdaptor.initConfig?.environment == ADJEnvironmentSandbox)
        #expect(self.mockAdaptor.initConfig?.delegate != nil)
    }

    @Test("when create() is called with missing appToken, then it should throw an error")
    func testCreateMissingAppToken() {
        let config: [String: Any] = [:]

        #expect(throws: Error.self) {
            try integration.create(destinationConfig: config)
        }
    }

    // MARK: - event mapping
    @Test("when track() is called without event mapping, then it should drop event when mapping missing")
    func testTrackMissingMapping() throws {
        try integration.create(destinationConfig: [
            "appToken": testAppToken,
            "logLevel": 4, // for sandbox mode
            "customMappings": [] // No mapping rule
        ])

        let event = TrackEvent(event: "Purchase")

        integration.track(payload: event)

        #expect(mockAdaptor.trackCalled == false)
    }

    @Test("when track() is called with valid event mapping, then it should send event")
    func testTrackWithValidMapping() throws {
        try integration.create(destinationConfig: [
            "appToken": testAppToken,
            "logLevel": 4, // for sandbox mode
            "customMappings": [
                ["from": "Purchase", "to": "EVT123"]
            ]
        ])

        let event = TrackEvent(event: "Purchase")

        integration.track(payload: event)

        #expect(mockAdaptor.trackCalled == true)
        #expect(mockAdaptor.trackedEvent?.eventToken == "EVT123")
    }

    // MARK: - partner params handling (identify)
    @Test("when identify() is called, then it should call setPartnerParams")
    func testIdentifyCallsPartnerParams() throws {
        var identify = IdentifyEvent()
        identify.userId = "user-888"
        identify.anonymousId = "anonymous-888"
        
        integration.identify(payload: identify)

        #expect(mockAdaptor.setPartnerParamsCalled == true)
        #expect(mockAdaptor.partnerPayload?.anonymousId == "anonymous-888")
        #expect(mockAdaptor.partnerPayload?.userId == "user-888")
    }

    // MARK: - partner params handling (track)
    @Test("when track() is called with valid event mapping, then it should call setPartnerParams before tracking")
    func testTrackCallsPartnerParams() throws {
        try integration.create(destinationConfig: [
            "appToken": testAppToken,
            "logLevel": 4, // for sandbox mode
            "customMappings": [["from": "Login", "to": "LOGIN123"]]
        ])

        let event = TrackEvent(event: "Login")

        integration.track(payload: event)

        #expect(mockAdaptor.setPartnerParamsCalled == true)
    }

    // MARK: - reset
    @Test("when reset() is called, then it should remove global partner parameters")
    func testReset() {
        integration.reset()

        #expect(mockAdaptor.removeGlobalPartnerParametersCalled == true)
    }

    // MARK: - callback params
    @Test("when track() is called with valid event mapping, then it should forward properties as callback params")
    func testTrackCallbackParams() throws {
        try integration.create(destinationConfig: [
            "appToken": testAppToken,
            "logLevel": 4, // for sandbox mode
            "customMappings": [["from": "Checkout", "to": "CHK987"]]
        ])

        let properties: [String : Any] = ["item": "Shoes", "revenue": 199.99, "currency": "USD"]
        let event = TrackEvent(event: "Checkout", properties: properties)

        integration.track(payload: event)

        #expect(mockAdaptor.trackCalled == true)

        guard let tracked = mockAdaptor.trackedEvent else {
            Issue.record("No event tracked")
            return
        }

        #expect(tracked.callbackParameters["item"] as? String == "Shoes")
        #expect(tracked.revenue == 199.99)
        #expect(tracked.currency == "USD")
    }

    // MARK: - attribution callback
    @Test("when adjustAttributionChanged() is called, then it should forward attribution changes")
    func testAttributionChangedCallback() throws {
        let spy = AttributionCallbackSpy()

        mockAdaptor.onAttributionChanged = { attribution in
            spy.invoked = true
            spy.received = attribution
        }

        let config: [String: Any] = [
            "appToken": testAppToken,
            "logLevel": 4 // for sandbox mode
        ]
        
        try integration.create(destinationConfig: config)

        // Fake attribution from Adjust SDK
        let attribution = ADJAttribution()
        attribution.trackerName = "fb-install"
        attribution.network = "facebook"

        // Simulate Adjust calling back into integration
        integration.adjustAttributionChanged(attribution)

        #expect(spy.invoked == true)
        #expect(spy.received?.trackerName == "fb-install")
        #expect(spy.received?.network == "facebook")
    }
}
