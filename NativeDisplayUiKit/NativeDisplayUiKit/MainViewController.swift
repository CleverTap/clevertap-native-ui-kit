//
//  MainViewController.swift
//  NativeDisplayUiKit
//
//  Main menu for navigating examples
//

import UIKit

class MainViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ExampleCell.self, forCellReuseIdentifier: ExampleCell.identifier)
        return table
    }()
    
    // MARK: - Data
    
    private let sections: [Section] = [
        Section(title: "Containers", examples: [
            Example(title: "Vertical Container",
                   description: "Column layout with vertical stacking",
                   viewControllerType: ContainerExampleViewController.self,
                   exampleType: .vertical),
            Example(title: "Horizontal Container",
                   description: "Row layout with horizontal arrangement",
                   viewControllerType: ContainerExampleViewController.self,
                   exampleType: .horizontal),
            Example(title: "Box Container",
                   description: "Single centered child",
                   viewControllerType: ContainerExampleViewController.self,
                   exampleType: .box),
            Example(title: "Stack Container",
                   description: "Layered children with z-index",
                   viewControllerType: ContainerExampleViewController.self,
                   exampleType: .stack)
        ]),
        Section(title: "Elements", examples: [
            Example(title: "Text Element",
                   description: "Display styled text",
                   viewControllerType: ElementExampleViewController.self,
                   exampleType: .text),
            Example(title: "Image Element",
                   description: "Display images from URL",
                   viewControllerType: ElementExampleViewController.self,
                   exampleType: .image),
            Example(title: "Button Element",
                   description: "Interactive button with actions",
                   viewControllerType: ElementExampleViewController.self,
                   exampleType: .button),
            Example(title: "Spacer Element",
                   description: "Add spacing between elements",
                   viewControllerType: ElementExampleViewController.self,
                   exampleType: .spacer)
        ]),
        Section(title: "Advanced Integration", examples: [
            Example(title: "Mixed Feed (Table + Collection)",
                   description: "Native iOS cells mixed with SDUI components",
                   viewControllerType: MixedFeedViewController.self,
                   exampleType: .mixedFeed)
        ]),
        Section(title: "Testing Tools", examples: [
            Example(title: "JSON Editor",
                   description: "Live JSON editing and preview",
                   viewControllerType: JSONEditorViewController.self,
                   exampleType: .jsonEditor)
        ])
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Native Display Kit Demo"
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add info button
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showInfo)
        )
        navigationItem.rightBarButtonItem = infoButton
    }
    
    // MARK: - Actions
    
    @objc private func showInfo() {
        let alert = UIAlertController(
            title: "About Native Display Kit",
            message: "Server-driven UI framework that renders native mobile interfaces from JSON configurations.\n\nVersion 1.0.0\n\n✨ Now with Mixed Feed support!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].examples.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ExampleCell.identifier,
            for: indexPath
        ) as? ExampleCell else {
            return UITableViewCell()
        }
        
        let example = sections[indexPath.section].examples[indexPath.row]
        cell.configure(with: example)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let example = sections[indexPath.section].examples[indexPath.row]
        
        // Create appropriate view controller
        let viewController = example.viewControllerType.init()
        if let exampleVC = viewController as? ExampleViewController {
            exampleVC.exampleType = example.exampleType
            exampleVC.title = example.title
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - Custom Cell

class ExampleCell: UITableViewCell {
    
    static let identifier = "ExampleCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 0.1)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(iconView)
        iconView.addSubview(iconLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            
            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with example: Example) {
        titleLabel.text = example.title
        descriptionLabel.text = example.description
        iconLabel.text = example.icon
    }
}
