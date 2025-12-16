//
//  AnalyticsManager.swift
//  Example
//
//  Created by Satheesh Kannan on 26/11/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - AnalyticsManager
final class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    var analytics: Analytics?
    
    private init() {
        /* Default implementation (no-op) */
    }
}

// MARK: - Identify
extension AnalyticsManager {
    func identifyEvent() {
        self.analytics?.identify(userId: "Swift_UserId_127")
    }
}

// MARK: - Track
extension AnalyticsManager {
    func trackEvent() {
        let properties: [String: Any] = ["key1": "value1", "key2": 123, "key3": true, "key4": 4.56, "revenue": "4.99", "currency": "INR"]
        self.analytics?.track(name: "Track Event", properties: properties)
    }
}

// MARK: - Reset
extension AnalyticsManager {
    func reset() {
        self.analytics?.reset()
    }
}
