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
    public var key: String = "Adjust"
    private var eventMap = [String: String]()
    private var enableInstallAttributionTracking = false
    
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

    /**
     Creates the integration with your own Adjust instance, which the app has already initialized.

     The integration doesn't initialize Adjust, set its log level, or set the Adjust delegate. It doesn't send the
     "Install Attributed" event, even when the destination configuration turns it on.

     - Parameter adjust: The Adjust instance that the app initialized, from `Adjust.getInstance()`.
     */
    public convenience init(adjust: Adjust) {
        self.init(adjustSDKAdapter: DefaultAdjustSDKAdapter(adjustInstance: adjust))
    }
    
    // MARK: - Required Methods
    public func getDestinationInstance() -> Any? {
        return self.adjustSDKAdapter.adjustInstance
    }
    
    public func create(destinationConfig: [String: Any]) throws {
        // Extract appToken
        guard let appToken = destinationConfig["appToken"] as? String, !appToken.isEmpty else {
            LoggerAnalytics.error("AdjustIntegration: Missing or empty appToken in config.")
            throw AdjustIntegrationError.missingAppToken
        }
        
        // Extract customMappings and build eventMap
        self.eventMap = buildEventMap(from: destinationConfig)
        
        // Extract enableInstallAttributionTracking
        self.enableInstallAttributionTracking = (destinationConfig["enableInstallAttributionTracking"] as? Bool) ?? false

        // With its own instance, the app passed an Adjust instance that it initialized with its own config.
        guard self.adjustSDKAdapter.adjustInstance == nil else {
            LoggerAnalytics.debug("AdjustIntegration: Adjust SDK is already initialized.")
            return
        }

        // Determine environment (sandbox/production)
        let isProductionEnvironment = LoggerAnalytics.logLevel == .none
        let environment: String = isProductionEnvironment ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        
        // Create Adjust config
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        
        // Set log level if provided
        adjustConfig?.logLevel = mappedAdjustLogLevel
        
        // Set even when tracking is off: a later update can turn it on, and the callback checks the flag.
        adjustConfig?.delegate = self
        
        // Initialize Adjust SDK
        self.adjustSDKAdapter.initSDK(adjustConfig: adjustConfig)
        LoggerAnalytics.debug("AdjustIntegration: Initialized Adjust SDK with appToken: \(appToken)")
    }
    
    public func update(destinationConfig: [String: Any]) {
        // Update event mappings
        self.eventMap = buildEventMap(from: destinationConfig)
        
        // Update install attribution tracking flag
        self.enableInstallAttributionTracking = (destinationConfig["enableInstallAttributionTracking"] as? Bool) ?? false
        
        LoggerAnalytics.debug("AdjustIntegration: Updated configuration - enableInstallAttributionTracking: \(self.enableInstallAttributionTracking)")
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
extension AdjustIntegration {
    /**
     Attribution callback from the Adjust SDK.

     When install attribution tracking is on, the integration tracks an "Install Attributed" event with the attribution.

     - Parameter attribution: The attribution from the Adjust SDK; `nil` is ignored.
     */
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        
        self.adjustSDKAdapter.onAttributionChanged?(attribution)
        
        guard enableInstallAttributionTracking else {
            LoggerAnalytics.debug("AdjustIntegration: Install attribution tracking is disabled.")
            return
        }
        
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
    }
}

// MARK: - Helpers
extension AdjustIntegration {
    private var mappedAdjustLogLevel: ADJLogLevel {
        return switch LoggerAnalytics.logLevel {
        case .none: .suppress
        case .error: .error
        case .warn: .warn
        case .info: .info
        case .debug: .debug
        case .verbose: .verbose
        }
    }
    
    private func buildEventMap(from destinationConfig: [String: Any]) -> [String: String] {
        let customMappings = destinationConfig["customMappings"] as? [[String: Any]] ?? []

        return customMappings
            .compactMap { mapping -> (String, String)? in
                guard
                    let from = mapping["from"] as? String,
                    let token = mapping["to"] as? String
                else { return nil }
                return (from, token)
            }
            .reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}

// MARK: - AdjustIntegrationError
enum AdjustIntegrationError: LocalizedError {
    case missingAppToken

    var errorDescription: String? {
        switch self {
        case .missingAppToken:
            return "Missing appToken"
        }
    }
}
