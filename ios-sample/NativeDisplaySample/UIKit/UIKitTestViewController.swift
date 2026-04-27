import UIKit
import CleverTapNativeDisplay
import CleverTapSDK

/// Pure UIKit view controller that mirrors the Android XML Test screen.
/// Demonstrates using NativeDisplayUIView in a traditional UIKit layout.
///
/// Layout (top → bottom):
///   [TextField + Fire Event button]   — fixed header
///   [Canvas label + ScrollView]       — flexible, takes remaining space
///   [Event Log label + Clear button]
///   [Log TextView]                    — fixed footer
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        buildLayout()
        wireActions()
        NativeDisplayBridge.shared.addListener(self)
    }

    deinit {
        NativeDisplayBridge.shared.removeListener(self)
    }

    // MARK: - Layout

    private func buildLayout() {
        // Header: text field + fire button
        let headerStack = UIStackView(arrangedSubviews: [eventNameField, fireButton])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Canvas scroll view + stack
        canvasScrollView.addSubview(canvasStack)
        canvasScrollView.addSubview(emptyCanvasLabel)

        // Log header
        logHeaderStack.addArrangedSubview(logLabel)
        logHeaderStack.addArrangedSubview(UIView()) // spacer
        logHeaderStack.addArrangedSubview(clearLogButton)

        // Add to view
        view.addSubview(headerStack)
        view.addSubview(canvasLabel)
        view.addSubview(canvasScrollView)
        view.addSubview(logHeaderStack)
        view.addSubview(logTextView)

        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Canvas label
            canvasLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            canvasLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            canvasLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Canvas scroll view — flexible height
            canvasScrollView.topAnchor.constraint(equalTo: canvasLabel.bottomAnchor, constant: 8),
            canvasScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Canvas stack inside scroll view
            canvasStack.topAnchor.constraint(equalTo: canvasScrollView.topAnchor, constant: 8),
            canvasStack.bottomAnchor.constraint(equalTo: canvasScrollView.bottomAnchor, constant: -8),
            canvasStack.leadingAnchor.constraint(equalTo: canvasScrollView.leadingAnchor, constant: 16),
            canvasStack.trailingAnchor.constraint(equalTo: canvasScrollView.trailingAnchor, constant: -16),
            canvasStack.widthAnchor.constraint(equalTo: canvasScrollView.widthAnchor, constant: -32),

            // Empty-state label centred in canvas area
            emptyCanvasLabel.centerXAnchor.constraint(equalTo: canvasScrollView.centerXAnchor),
            emptyCanvasLabel.centerYAnchor.constraint(equalTo: canvasScrollView.centerYAnchor),
            emptyCanvasLabel.leadingAnchor.constraint(greaterThanOrEqualTo: canvasScrollView.leadingAnchor, constant: 32),
            emptyCanvasLabel.trailingAnchor.constraint(lessThanOrEqualTo: canvasScrollView.trailingAnchor, constant: -32),

            // Log header
            logHeaderStack.topAnchor.constraint(equalTo: canvasScrollView.bottomAnchor, constant: 8),
            logHeaderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logHeaderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Log text view — fixed 160 pt footer
            logTextView.topAnchor.constraint(equalTo: logHeaderStack.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
            logTextView.heightAnchor.constraint(equalToConstant: 160),
        ])
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
        // Scroll to bottom
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

            // Remove existing display views
            self.canvasStack.arrangedSubviews.forEach {
                self.canvasStack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }

            // Add a NativeDisplayUIView for each unit
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
