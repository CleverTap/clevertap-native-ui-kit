import UIKit
import CleverTapNativeDisplay
import CleverTapSDK

/// Pure UIKit view controller that mirrors the Android XML Test screen.
/// Demonstrates using NativeDisplayUIView in a traditional UIKit layout.
///
/// Portrait layout (top → bottom):
///   [TextField + Fire Event button]   — fixed header
///   [Canvas label + ScrollView]       — flexible, takes remaining space
///   [Event Log label + Clear button]
///   [Log TextView]                    — fixed 160pt footer
///
/// Landscape layout (left → right):
///   Left panel 40%: [TextField + button] + [Event Log label + TextView]
///   Right panel 60%: [Canvas ScrollView] full height
final class UIKitTestViewController: UIViewController {

    // MARK: - UI elements

    private let eventNameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter event name"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .send
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let fireButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Fire Event"
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        return btn
    }()

    private let canvasLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Native Display Canvas"
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let canvasScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let canvasStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let emptyCanvasLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Fire an event to receive display units"
        lbl.textColor = .tertiaryLabel
        lbl.font = .systemFont(ofSize: 14)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let logHeaderStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let logLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Event Log"
        lbl.font = .systemFont(ofSize: 13, weight: .semibold)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let clearLogButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Clear"
        config.baseForegroundColor = .systemBlue
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let logTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.textColor = .green
        tv.backgroundColor = UIColor(white: 0.1, alpha: 1)
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.text = ""
        return tv
    }()

    /// Hairline vertical separator shown only in landscape to divide left/right panels.
    private let panelSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    /// Invisible anchor view whose width = 33% of the root view.
    /// Pins panelSeparator.leading to its trailing edge, avoiding the
    /// NSLayoutConstraint "invalid pairing" crash (.leading ↔ .width is forbidden).
    private let leftPanelAnchor: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // headerStack is a stored property so applyLayout() can reference it for landscape constraints.
    private var headerStack: UIStackView!

    // Constraint sets swapped on orientation change.
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        buildLayout()
        applyLayout(for: view.bounds.size)
        wireActions()
        NativeDisplayBridge.shared.addListener(self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.applyLayout(for: size)
        })
    }

    deinit {
        NativeDisplayBridge.shared.removeListener(self)
    }

    // MARK: - Layout

    private func buildLayout() {
        headerStack = UIStackView(arrangedSubviews: [eventNameField, fireButton])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        canvasScrollView.addSubview(canvasStack)
        canvasScrollView.addSubview(emptyCanvasLabel)

        logHeaderStack.addArrangedSubview(logLabel)
        logHeaderStack.addArrangedSubview(UIView()) // flexible spacer
        logHeaderStack.addArrangedSubview(clearLogButton)

        view.addSubview(headerStack)
        view.addSubview(canvasLabel)
        view.addSubview(canvasScrollView)
        view.addSubview(logHeaderStack)
        view.addSubview(logTextView)
        view.addSubview(panelSeparator)
        view.addSubview(leftPanelAnchor)

        let guide = view.safeAreaLayoutGuide

        // Always-active: canvas stack pinned inside its scroll view.
        NSLayoutConstraint.activate([
            canvasStack.topAnchor.constraint(equalTo: canvasScrollView.topAnchor, constant: 8),
            canvasStack.bottomAnchor.constraint(equalTo: canvasScrollView.bottomAnchor, constant: -8),
            canvasStack.leadingAnchor.constraint(equalTo: canvasScrollView.leadingAnchor),
            canvasStack.trailingAnchor.constraint(equalTo: canvasScrollView.trailingAnchor),
            canvasStack.widthAnchor.constraint(equalTo: canvasScrollView.widthAnchor),

            emptyCanvasLabel.centerXAnchor.constraint(equalTo: canvasScrollView.centerXAnchor),
            emptyCanvasLabel.centerYAnchor.constraint(equalTo: canvasScrollView.centerYAnchor),
            emptyCanvasLabel.leadingAnchor.constraint(greaterThanOrEqualTo: canvasScrollView.leadingAnchor, constant: 32),
            emptyCanvasLabel.trailingAnchor.constraint(lessThanOrEqualTo: canvasScrollView.trailingAnchor, constant: -32),
        ])

        // Portrait: stacked vertically, log TextView fixed at 160pt.
        portraitConstraints = [
            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            canvasLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            canvasLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            canvasLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            canvasScrollView.topAnchor.constraint(equalTo: canvasLabel.bottomAnchor, constant: 8),
            canvasScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasScrollView.bottomAnchor.constraint(equalTo: logHeaderStack.topAnchor, constant: -8),

            logHeaderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logHeaderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            logTextView.topAnchor.constraint(equalTo: logHeaderStack.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
            logTextView.heightAnchor.constraint(equalToConstant: 160),
        ]

        // Landscape: two-column split at 33/67.
        // leftPanelAnchor is an invisible view that takes 33% of the root width.
        // panelSeparator.leading is then pinned to leftPanelAnchor.trailing —
        // a valid position↔position pairing that avoids the NSInvalidArgumentException
        // caused by pairing .leading (position) with .width (size).
        landscapeConstraints = [
            // Invisible anchor occupies the left 33%
            leftPanelAnchor.topAnchor.constraint(equalTo: view.topAnchor),
            leftPanelAnchor.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftPanelAnchor.heightAnchor.constraint(equalToConstant: 1),
            leftPanelAnchor.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.33),

            // Separator at the trailing edge of the anchor (= 33% of view width)
            panelSeparator.topAnchor.constraint(equalTo: guide.topAnchor),
            panelSeparator.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            panelSeparator.widthAnchor.constraint(equalToConstant: 0.5),
            panelSeparator.leadingAnchor.constraint(equalTo: leftPanelAnchor.trailingAnchor),

            // Left panel — header at top
            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),

            // Left panel — log header below event header
            logHeaderStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            logHeaderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logHeaderStack.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),

            // Left panel — log TextView fills remaining height (no fixed height constraint)
            logTextView.topAnchor.constraint(equalTo: logHeaderStack.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),
            logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),

            // Right panel — canvas full height
            canvasScrollView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            canvasScrollView.leadingAnchor.constraint(equalTo: panelSeparator.trailingAnchor),
            canvasScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasScrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
        ]
    }

    private func applyLayout(for size: CGSize) {
        let isLandscape = size.width > size.height
        if isLandscape {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }
        canvasLabel.isHidden = isLandscape
        panelSeparator.isHidden = !isLandscape
        // Force the canvas scroll view and its hosted SwiftUI views to re-measure
        // after the constraint swap. Without this the NativeDisplayUIView instances
        // keep their pre-rotation frames until the next user-triggered layout pass.
        canvasScrollView.setNeedsLayout()
        canvasScrollView.layoutIfNeeded()
    }

    private func wireActions() {
        fireButton.addTarget(self, action: #selector(fireEvent), for: .touchUpInside)
        clearLogButton.addTarget(self, action: #selector(clearLog), for: .touchUpInside)
        eventNameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        eventNameField.delegate = self
    }

    // MARK: - Actions

    @objc private func fireEvent() {
        let name = eventNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else { return }
        CleverTap.sharedInstance()?.recordEvent(name)
        appendLog("▶ Event fired: \(name)")
        eventNameField.text = ""
        fireButton.isEnabled = false
        eventNameField.resignFirstResponder()
    }

    @objc private func clearLog() {
        logTextView.text = ""
    }

    @objc private func textFieldChanged() {
        let hasText = !(eventNameField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        fireButton.isEnabled = hasText
    }

    // MARK: - Helpers

    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"
        logTextView.text = (logTextView.text ?? "") + line
        let range = NSRange(location: logTextView.text.count - 1, length: 1)
        logTextView.scrollRangeToVisible(range)
    }

    private func updateEmptyState() {
        emptyCanvasLabel.isHidden = !canvasStack.arrangedSubviews.isEmpty
    }
}

// MARK: - UITextFieldDelegate

extension UIKitTestViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fireEvent()
        return true
    }
}

// MARK: - NativeDisplayBridgeListener

extension UIKitTestViewController: NativeDisplayBridgeListener {
    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.canvasStack.arrangedSubviews.forEach {
                self.canvasStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }

            for unit in units {
                let displayView = NativeDisplayUIView(
                    config: unit.config,
                    actionListener: self
                )
                displayView.translatesAutoresizingMaskIntoConstraints = false
                self.canvasStack.addArrangedSubview(displayView)
            }

            self.updateEmptyState()
            self.appendLog("📦 Received \(units.count) display unit(s)")
        }
    }
}

// MARK: - NativeDisplayActionListener

extension UIKitTestViewController: NativeDisplayActionListener {
    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        appendLog("🔗 Open URL: \(url) (browser: \(openInBrowser))")
        return false
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        appendLog("⚡ Custom action: \(key)")
    }

    func onNavigate(destination: String, params: [String: String]?) {
        appendLog("🧭 Navigate: \(destination)")
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        appendLog("📊 Track event: \(eventName)")
    }
}
