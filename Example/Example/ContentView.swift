//
//  ContentView.swift
//  Example
//
//  Created by Satheesh Kannan on 26/11/25.
//

import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16.0) {
                Button("Identify Event") {
                    AnalyticsManager.shared.identifyEvent()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Track Event") {
                    AnalyticsManager.shared.trackEvent()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Adjust Example")
        }
    }
}

// MARK: - PrimaryButtonStyle
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.title3)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}
