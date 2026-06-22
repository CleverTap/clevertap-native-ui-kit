import UIKit
import CleverTapNativeDisplay
import CleverTapSDK

/// Pure UIKit view controller demonstrating slot-based placement using
/// `NativeDisplaySlotTableViewCell` — the iOS parallel of the Android XML Slot
/// Demo, and a 1:1 UIKit mirror of SwiftUI's `SlotDemoView`.
///
/// The whole screen is a single `UITableView` driven by 20 rows:
///   - Row 0  — header card: title + description + "Fetch Slot Data" button.
///   - Rows 1-19 — the same 4-slot / 15-content interleave as the SwiftUI demo
///                 (slot_top, content × 3, slot_feed_1, content × 3,
///                 slot_feed_2, content × 9, slot_bottom).
///
/// Each slot row uses the SDK's `NativeDisplaySlotTableViewCell` and
/// auto-registers with `NativeDisplaySlotManager` on cell attach. The "Fetch
/// Slot Data" button fires the same hardcoded CleverTap events as the SwiftUI
/// demo so one dashboard campaign drives all three demos.
final class UIKitSlotDemoViewController: UIViewController {

    // MARK: - Feed model

    /// One row in the slot feed. Mirrors `SlotDemoItem` in `SlotDemoView.swift`,
    /// with an added `header` case for the title + button card at row 0.
    private enum SlotFeedItem {
        case header
        case slot(slotId: String)
        case appContent(AppContentSlotItem)
    }

    /// Hardcoded app-content card. Mirrors `AppContentItem` in `SlotDemoView.swift`
    /// (defined fresh here to avoid importing SwiftUI just for the model).
    fileprivate struct AppContentSlotItem {
        let id: Int
        let title: String
        let subtitle: String
        let imageUrl: String
    }

    // MARK: - Reuse identifiers

    private static let headerCellReuseId = "header"
    private static let slotCellReuseId = "slot"
    private static let appContentCellReuseId = "appContent"

    // MARK: - Feed data

    private var feedItems: [SlotFeedItem] = []

    // MARK: - UI elements

    private let feedTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 180
        tv.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tv.alwaysBounceVertical = true
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit Slot Demo"
        view.backgroundColor = .systemGroupedBackground

        // Bridge init — safe to call repeatedly; AppDelegate already does this
        // at launch, repeated for self-containment.
        NativeDisplayBridge.shared.initialize()
        if let ct = CleverTap.sharedInstance() {
            NativeDisplayBridge.shared.bind(ct)
        }

        feedItems = Self.buildFeed()
        view.addSubview(feedTableView)
        NSLayoutConstraint.activate([
            feedTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            feedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feedTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            feedTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        configureTableView()
    }

    // MARK: - Feed construction

    /// 20-row feed: header at row 0, then the same 19-row slot/content
    /// interleave as `SlotDemoView` (slot_top at 1, slot_feed_1 at 5,
    /// slot_feed_2 at 9, slot_bottom at 19).
    private static func buildFeed() -> [SlotFeedItem] {
        let appItems: [AppContentSlotItem] = [
            AppContentSlotItem(id: 1, title: "Morning Yoga Flow", subtitle: "30 min \u{00B7} Beginner friendly", imageUrl: "https://yavuzceliker.github.io/sample-images/image-1.jpg"),
            AppContentSlotItem(id: 2, title: "Mediterranean Salad", subtitle: "Quick & healthy lunch recipe", imageUrl: "https://yavuzceliker.github.io/sample-images/image-5.jpg"),
            AppContentSlotItem(id: 3, title: "Productivity Hacks", subtitle: "5 tips for focused work", imageUrl: "https://yavuzceliker.github.io/sample-images/image-10.jpg"),
            AppContentSlotItem(id: 4, title: "Trail Running Guide", subtitle: "Best routes near you", imageUrl: "https://yavuzceliker.github.io/sample-images/image-15.jpg"),
            AppContentSlotItem(id: 5, title: "Indoor Plants 101", subtitle: "Low-maintenance greenery", imageUrl: "https://yavuzceliker.github.io/sample-images/image-20.jpg"),
            AppContentSlotItem(id: 6, title: "Weekend Getaways", subtitle: "Top 10 road trip destinations", imageUrl: "https://yavuzceliker.github.io/sample-images/image-25.jpg"),
            AppContentSlotItem(id: 7, title: "Budget Meal Prep", subtitle: "Save time and money", imageUrl: "https://yavuzceliker.github.io/sample-images/image-30.jpg"),
            AppContentSlotItem(id: 8, title: "Home Workout", subtitle: "No equipment needed", imageUrl: "https://yavuzceliker.github.io/sample-images/image-35.jpg"),
            AppContentSlotItem(id: 9, title: "Coffee Brewing", subtitle: "Perfect pour-over technique", imageUrl: "https://yavuzceliker.github.io/sample-images/image-40.jpg"),
            AppContentSlotItem(id: 10, title: "Sleep Better", subtitle: "Science-backed tips", imageUrl: "https://yavuzceliker.github.io/sample-images/image-45.jpg"),
            AppContentSlotItem(id: 11, title: "Digital Detox", subtitle: "Unplug and recharge", imageUrl: "https://yavuzceliker.github.io/sample-images/image-50.jpg"),
            AppContentSlotItem(id: 12, title: "Book Club Picks", subtitle: "This month's top reads", imageUrl: "https://yavuzceliker.github.io/sample-images/image-55.jpg"),
            AppContentSlotItem(id: 13, title: "Smoothie Recipes", subtitle: "Fuel your morning", imageUrl: "https://yavuzceliker.github.io/sample-images/image-60.jpg"),
            AppContentSlotItem(id: 14, title: "Desk Stretches", subtitle: "Relieve tension in 5 min", imageUrl: "https://yavuzceliker.github.io/sample-images/image-65.jpg"),
            AppContentSlotItem(id: 15, title: "Mindful Breathing", subtitle: "Calm in 3 minutes", imageUrl: "https://yavuzceliker.github.io/sample-images/image-70.jpg"),
        ]

        var list: [SlotFeedItem] = []
        list.append(.header)                            // 0
        list.append(.slot(slotId: "slot_top"))          // 1
        list.append(.appContent(appItems[0]))           // 2
        list.append(.appContent(appItems[1]))           // 3
        list.append(.appContent(appItems[2]))           // 4
        list.append(.slot(slotId: "slot_feed_1"))       // 5
        list.append(.appContent(appItems[3]))           // 6
        list.append(.appContent(appItems[4]))           // 7
        list.append(.appContent(appItems[5]))           // 8
        list.append(.slot(slotId: "slot_feed_2"))       // 9
        list.append(.appContent(appItems[6]))           // 10
        list.append(.appContent(appItems[7]))           // 11
        list.append(.appContent(appItems[8]))           // 12
        list.append(.appContent(appItems[9]))           // 13
        list.append(.appContent(appItems[10]))          // 14
        list.append(.appContent(appItems[11]))          // 15
        list.append(.appContent(appItems[12]))          // 16
        list.append(.appContent(appItems[13]))          // 17
        list.append(.appContent(appItems[14]))          // 18
        list.append(.slot(slotId: "slot_bottom"))       // 19
        return list
    }

    private func configureTableView() {
        feedTableView.dataSource = self
        feedTableView.delegate = self
        feedTableView.register(SlotFeedHeaderTableViewCell.self, forCellReuseIdentifier: Self.headerCellReuseId)
        feedTableView.register(NativeDisplaySlotTableViewCell.self, forCellReuseIdentifier: Self.slotCellReuseId)
        feedTableView.register(AppContentTableViewCell.self, forCellReuseIdentifier: Self.appContentCellReuseId)
    }

    // MARK: - Actions

    /// Hardcoded events that target the four campaign slots on the dashboard.
    /// Mirrors the "Fetch Slot Data" button in `SlotDemoView.swift` and
    /// `SlotDemoScreen.kt` so all three demos pull the same campaigns.
    fileprivate func fetchSlotData() {
        guard let ct = CleverTap.sharedInstance() else { return }
        ct.recordEvent("Footer1")
        ct.recordEvent("Footer5")
        ct.recordEvent("Header1")
        ct.recordEvent("Header2")
        ct.recordEvent("Header4")
        ct.recordEvent("lalit")
    }
}

// MARK: - UITableViewDataSource / Delegate

extension UIKitSlotDemoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = feedItems[indexPath.row]
        switch item {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.headerCellReuseId, for: indexPath) as! SlotFeedHeaderTableViewCell
            cell.configure { [weak self] in self?.fetchSlotData() }
            return cell

        case .slot(let slotId):
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.slotCellReuseId, for: indexPath) as! NativeDisplaySlotTableViewCell
            cell.configure(slotId: slotId, actionListener: nil, componentListener: nil)
            return cell

        case .appContent(let appItem):
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.appContentCellReuseId, for: indexPath) as! AppContentTableViewCell
            cell.configure(appItem)
            return cell
        }
    }
}

// MARK: - SlotFeedHeaderTableViewCell

/// Header row of the slot feed: title + description + full-width primary button.
/// Mirrors the header `VStack` in SwiftUI's `SlotDemoView`.
private final class SlotFeedHeaderTableViewCell: UITableViewCell {

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Slot Demo"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = .label
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "This feed contains 4 NativeDisplaySlot views at fixed positions. Tap the button below to fire a CleverTap event that fetches real server data for the slots."
        lbl.font = .preferredFont(forTextStyle: .body)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let fetchButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Fetch Slot Data"
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var fetchAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(fetchButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            fetchButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            fetchButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fetchButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            fetchButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        fetchButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    fileprivate func configure(onFetch: @escaping () -> Void) {
        fetchAction = onFetch
    }

    @objc private func handleTap() {
        fetchAction?()
    }
}

// MARK: - AppContentTableViewCell

/// UITableViewCell rendering a single hardcoded app-content card.
///
/// Visual parity with SwiftUI's `AppContentCardView` in `SlotDemoView.swift`:
///   - 180pt image on top (rounded top corners via the card's `cornerRadius` + `masksToBounds`)
///   - title + subtitle below with 12pt internal padding
///   - card has rounded corners (12pt) and a subtle drop shadow
///
/// The image is loaded asynchronously via `URLSession.shared.dataTask`. We piggy-back
/// on `URLCache.shared` (pre-warmed by `ImagePreloader`) so repeated scrolls don't
/// re-hit the network.
private final class AppContentTableViewCell: UITableViewCell {

    // MARK: - Subviews

    /// Outer container that draws the drop shadow.
    private let shadowContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 4
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    /// Inner card view that clips the image to rounded corners.
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        return v
    }()

    private let cardImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "photo"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .preferredFont(forTextStyle: .headline)
        lbl.textColor = .label
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .preferredFont(forTextStyle: .subheadline)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - State

    /// Identifies the URL currently being loaded so a late-arriving response from
    /// a previous cell-content doesn't overwrite the image of a reused cell.
    private var currentImageUrl: String?
    private var imageTask: URLSessionDataTask?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(shadowContainer)
        shadowContainer.addSubview(cardView)
        cardView.addSubview(cardImageView)
        cardView.addSubview(placeholderIcon)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        // 12pt horizontal margins + 12pt bottom margin to simulate inter-row spacing.
        // contentInset.top on the table view supplies the top inset for the first row.
        NSLayoutConstraint.activate([
            shadowContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            shadowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            shadowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            cardView.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            cardImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            cardImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cardImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            cardImageView.heightAnchor.constraint(equalToConstant: 180),

            placeholderIcon.centerXAnchor.constraint(equalTo: cardImageView.centerXAnchor),
            placeholderIcon.centerYAnchor.constraint(equalTo: cardImageView.centerYAnchor),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 32),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: cardImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentImageUrl = nil
        cardImageView.image = nil
        cardImageView.backgroundColor = .systemGray5
        placeholderIcon.isHidden = true
    }

    // MARK: - Configuration

    fileprivate func configure(_ item: UIKitSlotDemoViewController.AppContentSlotItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        loadImage(from: item.imageUrl)
    }

    // MARK: - Image loading

    private func loadImage(from urlString: String) {
        currentImageUrl = urlString
        cardImageView.image = nil
        placeholderIcon.isHidden = true

        guard let url = URL(string: urlString) else {
            placeholderIcon.isHidden = false
            return
        }

        let request = URLRequest(url: url)

        // Synchronous cache hit — paint immediately and skip the network roundtrip.
        if let cached = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cached.data) {
            cardImageView.image = image
            return
        }

        imageTask?.cancel()
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self = self,
                  let data = data,
                  let response = response,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.currentImageUrl == urlString else { return }
                    self.placeholderIcon.isHidden = false
                }
                return
            }

            // Cache for subsequent scrolls.
            let cached = CachedURLResponse(response: response, data: data, storagePolicy: .allowedInMemoryOnly)
            URLCache.shared.storeCachedResponse(cached, for: request)

            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.currentImageUrl == urlString else { return }
                self.cardImageView.image = image
                self.placeholderIcon.isHidden = true
            }
        }
        imageTask = task
        task.resume()
    }
}
