//
//  AdjustExampleApp.swift
//  Example
//
//  Created by Satheesh Kannan on 26/11/25.
//

import SwiftUI
import RudderStackAnalytics
import RudderIntegrationAdjust

// MARK: - AdjustExampleApp
@main
struct AdjustExampleApp: App {
    
    init() {
        self.setupAnalytics()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func setupAnalytics() {
        LoggerAnalytics.logLevel = .verbose
        
        // TODO: Replace the placeholder values below with your actual RudderStack write key and data plane URL.
        let configuration = Configuration(writeKey: "<WriteKey>", dataPlaneUrl: "<DataPlaneUrl>")
        
        // Initialize Analytics
        let analytics = Analytics(configuration: configuration)
        
        // Add Adjust Integration
        let adjustIntegration = AdjustIntegration()
        analytics.add(plugin: adjustIntegration)
        
        // Store analytics instance globally for access in ContentView
        AnalyticsManager.shared.analytics = analytics
    }
}
