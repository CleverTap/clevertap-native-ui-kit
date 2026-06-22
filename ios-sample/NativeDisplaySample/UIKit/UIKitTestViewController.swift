import UIKit
import CleverTapNativeDisplay
import CleverTapSDK

/// Pure UIKit view controller that mirrors the Android XML Test screen.
/// Demonstrates the **non-slot** (Approach 2 — custom rendering) flow using
/// the SDK's `NativeDisplayTableViewCell`. Each bridge-delivered unit is
/// rendered in its own self-sizing table row.
///
/// Portrait layout (top → bottom):
///   [TextField + Fire Event button]   — fixed header
///   [Canvas label + UITableView]      — flexible, takes remaining space
///   [Event Log label + Clear button]
///   [Log TextView]                    — fixed 160pt footer
///
/// Landscape layout (left → right):
///   Left panel 33%: [TextField + button] + [Event Log label + TextView]
///   Right panel 67%: [Canvas UITableView] full height
final class UIKitTestViewController: UIViewController {

    // MARK: - Reuse identifier

    private static let cellReuseId = "NDCell"

    // MARK: - State

    private var units: [NativeDisplayUnit] = []

    // MARK: - UI elements

    private let eventNameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter event name"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .send
        tf.translatesAutoresizingMaskIntoConstraints = false
        // Matches the SwiftUI Events screen so XCUITest helpers can drive
        // both screens through the same identifier.
        tf.accessibilityIdentifier = "ct-event-input"
        return tf
    }()

    private let fireButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Fire Event"
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        // Matches the SwiftUI Events screen send button id.
        btn.accessibilityIdentifier = "ct-send-event-btn"
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

    /// Canvas: a self-sizing `UITableView` driven by `units`. Each row hosts
    /// a `NativeDisplayTableViewCell` — the SDK's utility cell that
    /// internally wraps `NativeDisplayUIView` and handles SwiftUI hosting,
    /// sizing, and re-measurement on content arrival.
    private lazy var canvasTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 200
        tv.alwaysBounceVertical = true
        // Horizontal margins live on the table view's leading/trailing
        // constraints so they align with the canvasLabel above (16pt). Only
        // the vertical content insets are applied here.
        tv.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tv.register(NativeDisplayTableViewCell.self, forCellReuseIdentifier: Self.cellReuseId)
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private let emptyCanvasLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Fire an event to receive display units"
        lbl.textColor = .tertiaryLabel
        lbl.font = .systemFont(ofSize: 14)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
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

    /// Eye-icon toggle that hides/shows the log text view so screenshots
    /// can be captured without the log obscuring the canvas.
    private let logToggleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "eye.slash")
        config.baseForegroundColor = .systemBlue
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.accessibilityIdentifier = "event-log-toggle"
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
        tv.accessibilityIdentifier = "event-log-content"
        return tv
    }()

    /// True when the log is showing. Default visible so humans see the
    /// log as before; tests flip it off via the toggle button.
    private var eventLogVisible = true

    /// Portrait-only height = 160 constraint, captured so we can deactivate
    /// it when collapsing (which lets the height=0 collapse constraint win).
    private var portraitLogHeightConstraint: NSLayoutConstraint!

    /// Landscape-only bottom pin to the safe-area guide, captured so we can
    /// deactivate it when collapsing (landscape has no explicit height, so
    /// the bottom pin is what stretches the log to fill the panel).
    private var landscapeLogBottomConstraint: NSLayoutConstraint!

    /// Height = 0 constraint applied when the log is collapsed. Stays
    /// deactivated by default so the log renders at its normal size.
    private lazy var collapsedLogHeightConstraint: NSLayoutConstraint = {
        let c = logTextView.heightAnchor.constraint(equalToConstant: 0)
        c.priority = .required
        return c
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
        updateEmptyState()
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

        logHeaderStack.addArrangedSubview(logLabel)
        logHeaderStack.addArrangedSubview(UIView()) // flexible spacer
        logHeaderStack.addArrangedSubview(clearLogButton)
        logHeaderStack.addArrangedSubview(logToggleButton)

        // Empty-state label is rendered behind the table view's rows; UITableView
        // hides it automatically when sections > 0 — we just have to set
        // backgroundView once.
        canvasTableView.backgroundView = emptyCanvasLabel

        view.addSubview(headerStack)
        view.addSubview(canvasLabel)
        view.addSubview(canvasTableView)
        view.addSubview(logHeaderStack)
        view.addSubview(logTextView)
        view.addSubview(panelSeparator)
        view.addSubview(leftPanelAnchor)

        let guide = view.safeAreaLayoutGuide

        // Captured so the toggle button can deactivate it when collapsing the log.
        portraitLogHeightConstraint = logTextView.heightAnchor.constraint(equalToConstant: 160)

        // Portrait: stacked vertically, log TextView fixed at 160pt.
        // All horizontal anchors pin to the safe-area guide so the layout
        // respects Dynamic Island / notch insets even if the view is ever
        // shown without a tab bar (e.g. modally presented).
        portraitConstraints = [
            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            canvasLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            canvasLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            canvasLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            canvasTableView.topAnchor.constraint(equalTo: canvasLabel.bottomAnchor, constant: 8),
            canvasTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            canvasTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            canvasTableView.bottomAnchor.constraint(equalTo: logHeaderStack.topAnchor, constant: -8),

            logHeaderStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logHeaderStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            logTextView.topAnchor.constraint(equalTo: logHeaderStack.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
            portraitLogHeightConstraint,
        ]

        // Landscape: two-column split at 33/67. See companion comment in the
        // pre-refactor file for the invisible-anchor trick that avoids the
        // .leading ↔ .width NSLayoutConstraint invalid-pairing crash.
        // Captured so the toggle button can deactivate it when collapsing
        // (landscape has no fixed log height — it stretches via this pin).
        landscapeLogBottomConstraint = logTextView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8)

        landscapeConstraints = [
            leftPanelAnchor.topAnchor.constraint(equalTo: view.topAnchor),
            leftPanelAnchor.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            leftPanelAnchor.heightAnchor.constraint(equalToConstant: 1),
            leftPanelAnchor.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.33),

            panelSeparator.topAnchor.constraint(equalTo: guide.topAnchor),
            panelSeparator.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            panelSeparator.widthAnchor.constraint(equalToConstant: 0.5),
            panelSeparator.leadingAnchor.constraint(equalTo: leftPanelAnchor.trailingAnchor),

            headerStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),

            logHeaderStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            logHeaderStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logHeaderStack.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),

            logTextView.topAnchor.constraint(equalTo: logHeaderStack.bottomAnchor, constant: 4),
            logTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: panelSeparator.leadingAnchor, constant: -8),
            landscapeLogBottomConstraint,

            canvasTableView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            canvasTableView.leadingAnchor.constraint(equalTo: panelSeparator.trailingAnchor, constant: 8),
            canvasTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            canvasTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8),
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

        // If the user collapsed the log before rotating, the orientation-swap
        // above re-activated the sizing constraint from the constraint array.
        // Re-apply the collapsed state so the log stays hidden across rotations.
        if !eventLogVisible {
            portraitLogHeightConstraint.isActive = false
            landscapeLogBottomConstraint.isActive = false
            collapsedLogHeightConstraint.isActive = true
        }
    }

    private func wireActions() {
        fireButton.addTarget(self, action: #selector(fireEvent), for: .touchUpInside)
        clearLogButton.addTarget(self, action: #selector(clearLog), for: .touchUpInside)
        logToggleButton.addTarget(self, action: #selector(toggleLogVisibility), for: .touchUpInside)
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

    /// Collapse the log down to just the header bar (eye icon toggles back).
    /// Keeps both portrait and landscape layouts honest by toggling whichever
    /// constraint is dictating the log's vertical extent.
    @objc private func toggleLogVisibility() {
        eventLogVisible.toggle()
        let icon = eventLogVisible ? "eye.slash" : "eye"
        var config = logToggleButton.configuration ?? UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        logToggleButton.configuration = config

        logTextView.isHidden = !eventLogVisible
        clearLogButton.isHidden = !eventLogVisible

        if eventLogVisible {
            collapsedLogHeightConstraint.isActive = false
            // Restore whichever sizing constraint matches the current orientation.
            if view.bounds.width > view.bounds.height {
                landscapeLogBottomConstraint.isActive = true
            } else {
                portraitLogHeightConstraint.isActive = true
            }
        } else {
            // Deactivate the orientation-specific sizer first so the
            // height=0 constraint we activate next doesn't conflict.
            portraitLogHeightConstraint.isActive = false
            landscapeLogBottomConstraint.isActive = false
            collapsedLogHeightConstraint.isActive = true
        }
        view.layoutIfNeeded()
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
        emptyCanvasLabel.isHidden = !units.isEmpty
    }
}

// MARK: - UITableViewDataSource / Delegate

extension UIKitTestViewController: UITableViewDataSource, UITableViewDelegate {

    // One section per unit so we can use `heightForFooterInSection` for 12pt
    // inter-row spacing — UITableView has no native row-spacing knob.
    func numberOfSections(in tableView: UITableView) -> Int { units.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseId, for: indexPath)
            as! NativeDisplayTableViewCell
        // Use `unit.config` until the next SDK release ships the new
        // `configure(with: NativeDisplayUnit, ...)` overload. Behaviour
        // matches the pre-refactor code path.
        cell.configure(with: units[indexPath.section].config, actionListener: self)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == units.count - 1 ? .leastNormalMagnitude : 12
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
            self.units = units
            self.canvasTableView.reloadData()
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
