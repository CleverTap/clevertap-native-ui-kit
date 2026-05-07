//
//  ActionHandler.swift
//  CleverTapNativeDisplay
//
//  Created by Lalitkumar Patil on 05/01/26.
//


// MARK: - Action Handler
// Core action execution engine

import Foundation
import SafariServices
import UIKit

/// Handles execution of actions triggered by Native Display components.
class ActionHandler {

    private weak var actionListener: NativeDisplayActionListener?
    private weak var componentListener: NativeDisplayComponentListener?
    private var firedSystemEvents = Set<String>()
    private let unitId: String?

    /// Whether an action listener is attached (for callers to skip unnecessary work)
    var hasActionListener: Bool { actionListener != nil }

    init(
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?,
        unitId: String? = nil
    ) {
        self.actionListener = actionListener
        self.componentListener = componentListener
        self.unitId = unitId
    }
    
    // MARK: - Public Methods
    
    /// Execute an action based on its type.
    /// - Parameters:
    ///   - action: The action to execute
    ///   - nodeId: The ID of the node that triggered this action
    ///   - interactionType: The type of interaction that triggered this action
    func handleAction(
        _ action: Action,
        nodeId: String,
        interactionType: InteractionType = .click
    ) {
        Task { @MainActor in
            do {
                print("ActionHandler: Handling action for node: \(nodeId)")
                
                // Notify component listener first (if interested in this node)
                let shouldProceed = notifyComponentListener(
                    nodeId: nodeId,
                    interactionType: interactionType,
                    hasServerAction: true
                )
                
                // If component listener consumed the interaction, stop here
                guard shouldProceed else {
                    print("ActionHandler: Component listener consumed interaction for node: \(nodeId)")
                    return
                }
                
                // Proceed with server action
                switch action {
                case .openUrl(let openUrlAction):
                    try await handleOpenUrl(openUrlAction, nodeId: nodeId)
                case .custom(let customAction):
                    handleCustomAction(customAction, nodeId: nodeId)
                case .navigate(let navigateAction):
                    handleNavigate(navigateAction, nodeId: nodeId)
                case .trackEvent(let trackEventAction):
                    handleTrackEvent(trackEventAction, nodeId: nodeId)
                case .composite(let compositeAction):
                    try await handleCompositeAction(compositeAction, nodeId: nodeId)
                }
            } catch {
                print("ActionHandler: Error handling action for node: \(nodeId), error: \(error)")
                actionListener?.onActionError(action: action, error: error)
            }
        }
    }
    
    /// Execute a lifecycle action (onAppear/onDisappear).
    /// These bypass the component listener since they are not user interactions.
    /// - Parameters:
    ///   - action: The action to execute
    ///   - nodeId: The ID of the node that triggered this action
    func handleLifecycleAction(
        _ action: Action,
        nodeId: String
    ) {
        Task { @MainActor in
            do {
                print("ActionHandler: Handling lifecycle action for node: \(nodeId)")
                switch action {
                case .openUrl(let openUrlAction):
                    try await handleOpenUrl(openUrlAction, nodeId: nodeId)
                case .custom(let customAction):
                    handleCustomAction(customAction, nodeId: nodeId)
                case .navigate(let navigateAction):
                    handleNavigate(navigateAction, nodeId: nodeId)
                case .trackEvent(let trackEventAction):
                    handleTrackEvent(trackEventAction, nodeId: nodeId)
                case .composite(let compositeAction):
                    try await handleCompositeAction(compositeAction, nodeId: nodeId)
                }
            } catch {
                print("ActionHandler: Error handling lifecycle action for node: \(nodeId) - \(error)")
                actionListener?.onActionError(action: action, error: error)
            }
        }
    }

    /// Fire a hardcoded system event through the action listener.
    /// System events are SDK-level events that always fire (not server-driven).
    /// - Parameters:
    ///   - eventName: The system event name (e.g., "Notification Viewed")
    ///   - properties: Optional event properties
    func fireSystemEvent(eventName: String, properties: [String: Any]? = nil, deduplicate: Bool = false) {
        guard hasActionListener else { return }
        if deduplicate {
            guard firedSystemEvents.insert(eventName).inserted else {
                print("ActionHandler: System event already fired, skipping: \(eventName)")
                return
            }
        }
        Task { @MainActor in
            print("ActionHandler: Firing system event: \(eventName)")
            actionListener?.onTrackEvent(eventName: eventName, properties: properties)
            if let unitId = unitId {
                switch eventName {
                case "Notification Viewed":
                    actionListener?.onDisplayUnitViewed?(unitId: unitId)
                case "Notification Clicked":
                    actionListener?.onDisplayUnitClicked?(unitId: unitId)
                default:
                    break
                }
            }
        }
    }

    /// Handle interaction for components without server actions.
    /// - Parameters:
    ///   - nodeId: The ID of the component
    ///   - interactionType: The type of interaction
    func handleInteractionWithoutAction(
        nodeId: String,
        interactionType: InteractionType
    ) {
        Task { @MainActor in
            print("ActionHandler: Handling interaction without action for node: \(nodeId)")
            _ = notifyComponentListener(
                nodeId: nodeId,
                interactionType: interactionType,
                hasServerAction: false
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Notify component listener about an interaction.
    /// - Returns: true if should proceed with server action, false if consumed by listener
    @MainActor
    private func notifyComponentListener(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Bool
    ) -> Bool {
        guard let listener = componentListener else {
            return true // No listener, proceed with server action
        }
        
        // Check if listener is interested in this node
        let interestedNodeIds = listener.getInterestedNodeIds()
        let isInterested = interestedNodeIds == nil || interestedNodeIds?.contains(nodeId) == true
        
        guard isInterested else {
            return true // Not interested, proceed with server action
        }
        
        // Call listener and check if it consumed the interaction
        let consumed = listener.onComponentInteraction(
            nodeId: nodeId,
            interactionType: interactionType,
            hasServerAction: hasServerAction
        )
        
        if consumed {
            print("ActionHandler: Component listener consumed interaction for: \(nodeId)")
        }
        
        return !consumed // Return true if NOT consumed (should proceed)
    }
    
    // MARK: - Action Handlers
    
    @MainActor
    private func handleOpenUrl(_ action: Action.OpenUrlAction, nodeId: String) async throws {
        print("ActionHandler: Opening URL: \(action.url)")
        
        // Ask listener if they want to handle it
        let handled = actionListener?.onOpenUrl(
            url: action.url,
            openInBrowser: action.openInBrowser
        ) ?? false
        
        // If listener didn't handle it, use default behavior
        guard !handled else {
            return
        }
        
        // Execute default URL opening
        try executeDefaultOpenUrl(action)
    }
    
    @MainActor
    private func executeDefaultOpenUrl(_ action: Action.OpenUrlAction) throws {
        guard let url = URL(string: action.url) else {
            throw ActionError.invalidUrl(action.url)
        }
        
        // Validate URL scheme
        guard isValidUrlScheme(url.scheme) else {
            throw ActionError.invalidUrlScheme(url.scheme ?? "none")
        }
        
        if action.openInBrowser {
            // Open in external browser
            UIApplication.shared.open(url)
        } else if action.customTabsEnabled {
            // Open in SFSafariViewController (iOS equivalent of Chrome Custom Tabs)
            openInSafariViewController(url)
        } else {
            // Fallback to external browser
            UIApplication.shared.open(url)
        }
    }
    
    @MainActor
    private func openInSafariViewController(_ url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            // Fallback to external browser if we can't get root view controller
            UIApplication.shared.open(url)
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        rootViewController.present(safariVC, animated: true)
    }
    
    private func isValidUrlScheme(_ scheme: String?) -> Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return ["http", "https", "tel", "mailto"].contains(scheme)
    }
    
    @MainActor
    private func handleCustomAction(_ action: Action.CustomAction, nodeId: String) {
        print("ActionHandler: Executing custom action: \(action.key)")
        
        let parsedValue = parseAnyCodableValue(action.value)
        
        actionListener?.onCustomAction(
            key: action.key,
            value: parsedValue,
            metadata: action.metadata
        )
    }
    
    @MainActor
    private func handleNavigate(_ action: Action.NavigateAction, nodeId: String) {
        print("ActionHandler: Navigating to: \(action.destination)")
        
        actionListener?.onNavigate(
            destination: action.destination,
            params: action.params
        )
    }
    
    @MainActor
    private func handleTrackEvent(_ action: Action.TrackEventAction, nodeId: String) {
        print("ActionHandler: Tracking event: \(action.eventName)")
        
        let parsedProperties = action.properties?.mapValues { parseAnyCodableValue($0) }
        
        actionListener?.onTrackEvent(
            eventName: action.eventName,
            properties: parsedProperties
        )
    }
    
    @MainActor
    private func handleCompositeAction(_ action: Action.CompositeAction, nodeId: String) async throws {
        print("ActionHandler: Executing composite action with \(action.actions.count) sub-actions (\(action.executionMode))")
        
        switch action.executionMode {
        case .sequential:
            // Execute one after another
            for subAction in action.actions {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    handleAction(subAction, nodeId: "\(nodeId)-composite", interactionType: .click)
                    continuation.resume()
                }
            }
            
        case .parallel:
            // Execute all at once
            await withTaskGroup(of: Void.self) { group in
                for subAction in action.actions {
                    group.addTask {
                        self.handleAction(subAction, nodeId: "\(nodeId)-composite", interactionType: .click)
                    }
                }
            }
        }
    }
    
    // MARK: - Value Parsing
    
    /// Convert AnyCodable to usable Swift types.
    private func parseAnyCodableValue(_ anyCodable: AnyCodable) -> Any? {
        let value = anyCodable.value
        
        if value is NSNull {
            return nil
        } else if let bool = value as? Bool {
            return bool
        } else if let int = value as? Int {
            return int
        } else if let double = value as? Double {
            return double
        } else if let string = value as? String {
            return string
        } else if let array = value as? [Any] {
            return array.map { item in
                if let anyCodableItem = item as? AnyCodable {
                    return parseAnyCodableValue(anyCodableItem)
                }
                return item
            }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { item in
                if let anyCodableItem = item as? AnyCodable {
                    return parseAnyCodableValue(anyCodableItem)
                }
                return item
            }
        }
        
        return value
    }
}

// MARK: - Action Errors

enum ActionError: LocalizedError {
    case invalidUrl(String)
    case invalidUrlScheme(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl(let url):
            return "Invalid URL: \(url)"
        case .invalidUrlScheme(let scheme):
            return "Invalid URL scheme: \(scheme)"
        }
    }
}
