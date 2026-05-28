//
//  ExampleViewController.swift
//  NativeDisplayUiKit
//
//  Base view controller for all examples
//

import UIKit

class ExampleViewController: UIViewController {
    
    var exampleType: ExampleType?
    
    // MARK: - UI Components
    
    private var displayView: NativeDisplayHostingView?
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = .systemBackground
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let jsonButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View JSON", for: .normal)
        button.setImage(UIImage(systemName: "doc.text"), for: .normal)
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadExample()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(jsonButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            jsonButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            jsonButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            jsonButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        jsonButton.addTarget(self, action: #selector(showJSON), for: .touchUpInside)
    }
    
    // MARK: - Load Example
    
    func loadExample() {
        // Override in subclass
    }
    
    func displayJSON(_ json: String, description: String) {
        descriptionLabel.text = description
        
        // Remove old display view
        displayView?.removeFromSuperview()
        
        // Create new display view
        displayView = NativeDisplayHostingView(json: json, parentViewController: self)
        displayView?.translatesAutoresizingMaskIntoConstraints = false
        displayView?.backgroundColor = .systemGray6
        displayView?.layer.cornerRadius = 12
        
        if let displayView = displayView {
            contentView.addSubview(displayView)
            
            NSLayoutConstraint.activate([
                displayView.topAnchor.constraint(equalTo: jsonButton.bottomAnchor, constant: 16),
                displayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                displayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                displayView.heightAnchor.constraint(equalToConstant: 400),
                displayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
            ])
        }
    }
    
    // MARK: - Actions
    
    @objc private func showJSON() {
        // Override in subclass to show actual JSON
        let alert = UIAlertController(
            title: "JSON Configuration",
            message: "JSON preview coming soon...",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
