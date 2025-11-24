//
//  AdjustIntegration.swift
//  integration-swift-adjust
//
//  Created by Satheesh Kannan on 24/11/25.
//

import Foundation
import AdjustSdk
import RudderStackAnalytics

// Adapter protocol for Adjust SDK
public protocol AdjustSDKAdapter {
    func initSDK(adjustConfig: ADJConfig?)
    func track(event: ADJEvent)
    func setPartnerParams(payload: Event)
    func removeGlobalPartnerParameters()
}

class DefaultAdjustSDKAdapter: AdjustSDKAdapter {
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

/// Implements IntegrationPlugin and StandardIntegration protocols
public class AdjustIntegration: NSObject, IntegrationPlugin, StandardIntegration, AdjustDelegate {
    // Required protocol properties
    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "adjust"
    private var eventMap: [String: String] = [:]

    let adjustSDKAdapter: AdjustSDKAdapter
    
    init(adjustSDKAdapter: AdjustSDKAdapter) {
        self.adjustSDKAdapter = adjustSDKAdapter
        super.init()
    }

    public convenience override init() {
        self.init(adjustSDKAdapter: DefaultAdjustSDKAdapter())
    }

    // MARK: - Required Methods
    public func getDestinationInstance() -> Any? {
        return Adjust.getInstance()
    }

    public func create(destinationConfig: [String: Any]) throws {
        // Extract appToken
        guard let appToken = destinationConfig["appToken"] as? String, !appToken.isEmpty else {
            LoggerAnalytics.error("AdjustIntegration: Missing or empty appToken in config.")
            throw NSError(domain: "AdjustIntegration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing appToken"])
        }

        // Extract customMappings and build eventMap
        eventMap = [:]
        if let customMappings = destinationConfig["customMappings"] as? [[String: Any]] {
            for mapping in customMappings {
                if let from = mapping["from"] as? String, let to = mapping["to"] as? String {
                    eventMap[from] = to
                }
            }
        }

        // Extract enableInstallAttributionTracking
        let enableInstallAttributionTracking = (destinationConfig["enableInstallAttributionTracking"] as? Bool) ?? false

        // Determine environment (sandbox/production)
        let environment: String = (destinationConfig["logLevel"] as? Int ?? 0) >= 4 ? ADJEnvironmentSandbox : ADJEnvironmentProduction

        // Create Adjust config
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)

        // Set log level if provided
        if let logLevel = destinationConfig["logLevel"] as? Int {
            switch logLevel {
            case 5: adjustConfig?.logLevel = ADJLogLevel.verbose
            case 4: adjustConfig?.logLevel = ADJLogLevel.debug
            case 3: adjustConfig?.logLevel = ADJLogLevel.info
            case 2: adjustConfig?.logLevel = ADJLogLevel.warn
            case 1: adjustConfig?.logLevel = ADJLogLevel.error
            default: adjustConfig?.logLevel = ADJLogLevel.suppress
            }
        }

        // Set delegate for install attribution tracking if enabled
        if enableInstallAttributionTracking {
            adjustConfig?.delegate = self
        }

        // Initialize Adjust SDK
        self.adjustSDKAdapter.initSDK(adjustConfig: adjustConfig)
        LoggerAnalytics.debug("AdjustIntegration: Initialized Adjust SDK with appToken: \(appToken)")
    }

    // MARK: - Optional Methods (implement only if needed)
    public func flush() {
        // No-op for Adjust
    }

    public func reset() {
        self.adjustSDKAdapter.removeGlobalPartnerParameters()
    }

    // MARK: - Event Methods
    public func track(payload: TrackEvent) {
        // Extract event name
        let eventName = payload.event
        guard !eventName.isEmpty else {
            LoggerAnalytics.warn("AdjustIntegration: Track event missing event name.")
            return
        }

        // Use stored eventMap
        guard let adjEventToken = eventMap[eventName], !adjEventToken.isEmpty else {
            LoggerAnalytics.debug("AdjustIntegration: Dropping track event \(eventName), - no event token mapping found.")
            return
        }

        // Set partner params
        self.adjustSDKAdapter.setPartnerParams(payload: payload)

        // Create Adjust event
        guard let event = ADJEvent(eventToken: adjEventToken) else {
            LoggerAnalytics.error("AdjustIntegration: Failed to create ADJEvent for token, \(adjEventToken).")
            return
        }

        // Add properties as callback parameters
        let eventProperties = payload.properties?.dictionary?.rawDictionary ?? [:]
        for (key, value) in eventProperties {
            event.addCallbackParameter(String(describing: key), value: String(describing: value))
        }

        // Set revenue and currency if available
        if let revenue = eventProperties["revenue"] as? Double,
           let currency = eventProperties["currency"] as? String {
            event.setRevenue(revenue, currency: currency)
        }

        // Track event
        self.adjustSDKAdapter.track(event: event)
        LoggerAnalytics.debug("AdjustIntegration: Tracked event \(eventName), with token \(adjEventToken).")
    }
    
    public func identify(payload: IdentifyEvent) {
        self.adjustSDKAdapter.setPartnerParams(payload: payload)
    }
}

// MARK: - AdjustDelegate
// Attribution callback from Adjust SDK
extension AdjustIntegration {
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution = attribution else { return }
        
        var properties: [String: Any] = ["provider": "Adjust"]
        properties.setIfNotNil("trackerToken", attribution.trackerToken)
        properties.setIfNotNil("trackerName", attribution.trackerName)
        
        var campaign: [String: Any] = [:]
        campaign.setIfNotNil("source", attribution.network)
        campaign.setIfNotNil("name", attribution.campaign)
        campaign.setIfNotNil("content", attribution.clickLabel)
        campaign.setIfNotNil("adCreative", attribution.creative)
        campaign.setIfNotNil("adGroup", attribution.adgroup)
        
        properties.setIfNotNil("campaign", campaign.isEmpty ? nil : campaign)
        
        LoggerAnalytics.debug("Install Attributed event properties: \(properties)")
        
        analytics?.track(name: "Install Attributed", properties: properties)
    }
}

// MARK: - Dictionary
extension Dictionary where Key == String, Value == Any {
    mutating func setIfNotNil(_ key: String, _ value: Any?) {
        if let value { self[key] = value }
    }
}
