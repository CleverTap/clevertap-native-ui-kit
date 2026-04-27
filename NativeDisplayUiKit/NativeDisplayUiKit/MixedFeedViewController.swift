//
//  MixedFeedViewController.swift
//  NativeDisplayUiKit
//
//  Demonstrates mixing native iOS cells with SDUI cells
//

import UIKit

class MixedFeedViewController: UIViewController {
    
    private var feedItems: [FeedItem] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemGroupedBackground
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Product Feed"
        view.backgroundColor = .systemGroupedBackground
        
        setupTableView()
        setupActivityIndicator()
        loadProducts()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register cells
        tableView.register(NativeProductCell.self, forCellReuseIdentifier: NativeProductCell.identifier)
        tableView.register(SDUICell.self, forCellReuseIdentifier: SDUICell.identifier)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadProducts() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        
        Task {
            do {
                let response = try await ProductAPI.shared.fetchProducts()
                let products = response.products
                
                var items: [FeedItem] = []
                
                for (index, product) in products.enumerated() {
                    // Add gallery every 7 items
                    if index > 0 && index % 7 == 0 {
                        let galleryProducts = Array(products.dropFirst(index).prefix(5))
                        if !galleryProducts.isEmpty {
                            let config = ConfigBuilder.createGalleryConfig(products: galleryProducts)
                            items.append(.sduiGallery(id: "gallery_\(index)", config: config))
                        }
                    }
                    
                    // Mix SDUI and native products
                    if index % 3 == 0 {
                        // SDUI product card
                        let config = ConfigBuilder.createProductConfig(product: product)
                        items.append(.sduiProduct(id: "sdui_\(product.id)", config: config))
                    } else {
                        // Native product cell
                        items.append(.nativeProduct(id: "native_\(product.id)", product: product))
                    }
                }
                
                await MainActor.run {
                    self.feedItems = items
                    self.tableView.reloadData()
                    self.tableView.isHidden = false
                    self.activityIndicator.stopAnimating()
                }
                
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.showError(message: "Failed to load products: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadProducts()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MixedFeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = feedItems[indexPath.row]
        
        switch item {
        case .nativeProduct(_, let product):
            let cell = tableView.dequeueReusableCell(withIdentifier: NativeProductCell.identifier, for: indexPath) as! NativeProductCell
            cell.configure(with: product) {
                print("Product \(product.id) - Add to cart tapped!")
            }
            return cell
            
        case .sduiProduct(_, let config):
            let cell = tableView.dequeueReusableCell(withIdentifier: SDUICell.identifier, for: indexPath) as! SDUICell
            cell.configure(with: config, parentVC: self)
            return cell
            
        case .sduiGallery(_, let config):
            let cell = tableView.dequeueReusableCell(withIdentifier: SDUICell.identifier, for: indexPath) as! SDUICell
            cell.configure(with: config, parentVC: self)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension MixedFeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = feedItems[indexPath.row]
        
        switch item {
        case .nativeProduct:
            return UITableView.automaticDimension
            
        case .sduiProduct:
            // Estimated height for SDUI product card
            return UITableView.automaticDimension
            
        case .sduiGallery:
            // Fixed height for gallery (header + gallery)
            return 340
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = feedItems[indexPath.row]
        
        switch item {
        case .nativeProduct:
            return 400
        case .sduiProduct:
            return 500
        case .sduiGallery:
            return 340
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = feedItems[indexPath.row]
        
        switch item {
        case .nativeProduct(_, let product):
            print("Native product tapped: \(product.title)")
        case .sduiProduct(_, _):
            print("SDUI product tapped")
        case .sduiGallery(_, _):
            print("Gallery tapped")
        }
    }
}
