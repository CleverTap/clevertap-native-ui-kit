//
//  NativeDisplayHostingView.swift
//  NativeDisplayUiKit
//
//  UIKit bridge for CleverTap NativeDisplay SwiftUI views
//

import UIKit
import SwiftUI
import CleverTapNativeDisplay

/// UIKit wrapper that hosts SwiftUI NativeDisplayView
/// This allows UIKit view controllers to integrate server-driven UI
class NativeDisplayHostingView: UIView {
    
    // MARK: - Properties
    
    private var hostingController: UIHostingController<AnyView>?
    private weak var parentViewController: UIViewController?
    
    // MARK: - Initialization
    
    /// Initialize with JSON configuration
    /// - Parameters:
    ///   - json: JSON string containing the display configuration
    ///   - parentViewController: The parent view controller that will host this view
    init(json: String, parentViewController: UIViewController) {
        self.parentViewController = parentViewController
        super.init(frame: .zero)
        setupView(with: json)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView(with json: String) {
        do {
            // Parse JSON to ResolvedConfig
            guard let jsonData = json.data(using: .utf8) else {
                throw NSError(
                    domain: "NativeDisplayHostingView",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string encoding"]
                )
            }
            
            let decoder = JSONDecoder()
            let config = try decoder.decode(ResolvedConfig.self, from: jsonData)
            
            // Create SwiftUI view
            let displayView = NativeDisplayView(config: config)
            let anyView = AnyView(displayView)
            
            // Create hosting controller
            let hosting = UIHostingController(rootView: anyView)
            hosting.view.backgroundColor = .clear
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            
            // Add to parent view controller hierarchy
            if let parent = parentViewController {
                parent.addChild(hosting)
                addSubview(hosting.view)
                
                NSLayoutConstraint.activate([
                    hosting.view.topAnchor.constraint(equalTo: topAnchor),
                    hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                    hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                    hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
                
                hosting.didMove(toParent: parent)
            }
            
            self.hostingController = hosting
            
        } catch let decodingError as DecodingError {
            showError(parseDecodingError(decodingError))
        } catch {
            showError(error)
        }
    }
    
    // MARK: - Error Handling
    
    private func parseDecodingError(_ error: DecodingError) -> Error {
        switch error {
        case .keyNotFound(let key, let context):
            return NSError(
                domain: "NativeDisplayHostingView",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Missing key '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]
            )
        case .typeMismatch(let type, let context):
            return NSError(
                domain: "NativeDisplayHostingView",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]
            )
        case .valueNotFound(let type, let context):
            return NSError(
                domain: "NativeDisplayHostingView",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Value not found: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]
            )
        case .dataCorrupted(let context):
            return NSError(
                domain: "NativeDisplayHostingView",
                code: -5,
                userInfo: [NSLocalizedDescriptionKey: "Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"]
            )
        @unknown default:
            return error
        }
    }
    
    private func showError(_ error: Error) {
        let errorView = createErrorView(message: error.localizedDescription)
        addSubview(errorView)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }
    
    private func createErrorView(message: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemRed.cgColor
        
        let iconLabel = UILabel()
        iconLabel.text = "⚠️"
        iconLabel.font = .systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = "Error Loading View"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemRed
        titleLabel.textAlignment = .center
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [iconLabel, titleLabel, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
        
        return containerView
    }
    
    // MARK: - Update
    
    /// Update the view with new JSON configuration
    /// - Parameter json: New JSON string to display
    func updateJSON(_ json: String) {
        // Remove old hosting controller
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        
        // Remove error views if any
        subviews.forEach { $0.removeFromSuperview() }
        
        // Setup with new JSON
        setupView(with: json)
    }
    
    // MARK: - Cleanup
    
    deinit {
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
    }
}
