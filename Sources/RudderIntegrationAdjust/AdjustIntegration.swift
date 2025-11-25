//
//  AdjustIntegration.swift
//  integration-swift-adjust
//
//  Created by Satheesh Kannan on 24/11/25.
//

import Foundation
import AdjustSdk
import RudderStackAnalytics

// MARK: - AdjustIntegration
/**
 Adjust Integration for RudderStack Analytics.
 */
public class AdjustIntegration: NSObject, IntegrationPlugin, StandardIntegration, AdjustDelegate {
    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "adjust"
    private var eventMap: [String: String] = [:]

    let adjustSDKAdapter: AdjustSDKAdapter
    
    // MARK: - Initializers
    init(adjustSDKAdapter: AdjustSDKAdapter) {
        self.adjustSDKAdapter = adjustSDKAdapter
        super.init()
    }
    
    // Convenience initializer using DefaultAdjustSDKAdapter
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
        self.eventMap = [:]
        if let customMappings = destinationConfig["customMappings"] as? [[String: Any]] {
            customMappings.compactMap { mapping -> (String, String)? in
                guard let from = mapping["from"] as? String,
                      let to = mapping["to"] as? String else { return nil }
                return (from, to)
            }
            .forEach { eventMap[$0] = $1 }
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
            LoggerAnalytics.debug("AdjustIntegration: Dropping track event \(eventName) - no event token mapping found.")
            return
        }

        // Set partner params
        self.adjustSDKAdapter.setPartnerParams(payload: payload)

        // Create Adjust event
        guard let event = ADJEvent(eventToken: adjEventToken) else {
            LoggerAnalytics.error("AdjustIntegration: Failed to create ADJEvent for token \(adjEventToken).")
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
        LoggerAnalytics.debug("AdjustIntegration: Tracked event \(eventName) with token \(adjEventToken).")
    }
    
    public func identify(payload: IdentifyEvent) {
        self.adjustSDKAdapter.setPartnerParams(payload: payload)
    }
}

// MARK: - AdjustDelegate
/**
 Attribution callback from Adjust SDK
 */
extension AdjustIntegration {
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }

        let campaign: [String: Any] = [
            "source": attribution.network,
            "name": attribution.campaign,
            "content": attribution.clickLabel,
            "adCreative": attribution.creative,
            "adGroup": attribution.adgroup
        ].compactMapValues { $0 }

        let properties: [String: Any] = [
            "provider": "Adjust",
            "trackerToken": attribution.trackerToken,
            "trackerName": attribution.trackerName,
            "campaign": campaign.isEmpty ? nil : campaign
        ].compactMapValues { $0 }

        LoggerAnalytics.debug("Install Attributed event properties: \(properties).")

        self.analytics?.track(name: "Install Attributed", properties: properties)

        self.adjustSDKAdapter.onAttributionChanged?(attribution)
    }
}
