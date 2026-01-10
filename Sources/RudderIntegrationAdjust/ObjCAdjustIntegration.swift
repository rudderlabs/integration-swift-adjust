//
//  ObjCAdjustIntegration.swift
//  RudderIntegrationAdjust
//
//  Created by Satheesh Kannan on 08/01/26.
//

import Foundation
import RudderStackAnalytics

// MARK: - ObjCAdjustIntegration
/**
 An Objective-C compatible wrapper for the Adjust Integration.

 This class provides an Objective-C interface to the Adjust integration,
 allowing Objective-C apps to use the Adjust device mode integration with RudderStack.

 ## Usage in Objective-C:
 ```objc
 RSSConfiguration *config = [[RSSConfiguration alloc] initWithWriteKey:@"<WriteKey>"
                                                          dataPlaneUrl:@"<DataPlaneUrl>"];
 RSSAnalytics *analytics = [[RSSAnalytics alloc] initWithConfiguration:config];

 RSSAdjustIntegration *adjustIntegration = [[RSSAdjustIntegration alloc] init];
 [analytics addPlugin:adjustIntegration];
 ```
 */
@objc(RSSAdjustIntegration)
public class ObjCAdjustIntegration: NSObject, ObjCIntegrationPlugin, ObjCStandardIntegration {

    // MARK: - ObjCPlugin Properties

    public var pluginType: PluginType {
        get { adjustIntegration.pluginType }
        set { adjustIntegration.pluginType = newValue }
    }

    // MARK: - ObjCIntegrationPlugin Properties

    public var key: String {
        get { adjustIntegration.key }
        set { adjustIntegration.key = newValue }
    }

    // MARK: - Private Properties

    private let adjustIntegration: AdjustIntegration

    // MARK: - Initializers

    /**
     Initializes a new Adjust integration instance.

     Use this initializer to create an Adjust integration that can be added to the analytics client.
     */
    @objc
    public override init() {
        self.adjustIntegration = AdjustIntegration()
        super.init()
    }

    // MARK: - ObjCIntegrationPlugin Methods

    /**
     Returns the Adjust SDK instance.

     - Returns: The Adjust SDK instance, or nil if not initialized.
     */
    @objc
    public func getDestinationInstance() -> Any? {
        return adjustIntegration.getDestinationInstance()
    }

    /**
     Creates and configures the Adjust SDK with the provided destination configuration.

     - Parameters:
        - destinationConfig: Configuration dictionary from RudderStack dashboard.
        - errorPointer: A pointer to an NSError that will be set if initialization fails.
     - Returns: `true` if initialization succeeded, `false` otherwise.
     */
    @objc
    public func createWithDestinationConfig(_ destinationConfig: [String: Any], error errorPointer: NSErrorPointer) -> Bool {
        do {
            try adjustIntegration.create(destinationConfig: destinationConfig)
            return true
        } catch let err as NSError {
            errorPointer?.pointee = err
            return false
        } catch {
            errorPointer?.pointee = NSError(
                domain: "com.rudderstack.AdjustIntegration",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
            )
            return false
        }
    }

    /**
     Flushes any pending events.

     This is a no-op for Adjust as it handles event delivery internally.
     */
    @objc
    public func flush() {
        adjustIntegration.flush()
    }

    /**
     Resets the integration state.

     This removes all global partner parameters from the Adjust SDK.
     */
    @objc
    public func reset() {
        adjustIntegration.reset()
    }

    // MARK: - ObjCEventPlugin Methods

    /**
     Processes a track event and forwards it to the underlying Adjust integration.

     - Parameter payload: The ObjC track event payload.
     */
    @objc
    public func track(_ payload: ObjCTrackEvent) {
        var trackEvent = TrackEvent(
            event: payload.eventName,
            properties: payload.properties,
            options: payload.options
        )
        trackEvent.anonymousId = payload.anonymousId
        trackEvent.userId = payload.userId

        adjustIntegration.track(payload: trackEvent)
    }

    /**
     Processes an identify event and forwards it to the underlying Adjust integration.

     - Parameter payload: The ObjC identify event payload.
     */
    @objc
    public func identify(_ payload: ObjCIdentifyEvent) {
        var identifyEvent = IdentifyEvent(options: payload.options)
        identifyEvent.anonymousId = payload.anonymousId
        identifyEvent.userId = payload.userId

        adjustIntegration.identify(payload: identifyEvent)
    }
}
