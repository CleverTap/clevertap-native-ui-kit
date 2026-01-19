//
//  NativeProductCell.swift
//  NativeDisplayUiKit
//
//  Native UITableViewCell for product display
//

import UIKit

class NativeProductCell: UITableViewCell {
    
    static let identifier = "NativeProductCell"
    
    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Cart", for: .normal)
        button.backgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .white
        
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(buyButton)
        
        NSLayoutConstraint.activate([
            // Image
            productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            productImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: productImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Price
            priceLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Rating
            ratingLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Buy Button
            buyButton.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16),
            buyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buyButton.heightAnchor.constraint(equalToConstant: 44),
            buyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Add shadow to cell
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }
    
    func configure(with product: Product, onBuyTap: @escaping () -> Void) {
        titleLabel.text = product.title
        descriptionLabel.text = product.description
        priceLabel.text = "$\(product.price)"
        ratingLabel.text = "⭐ \(product.rating)"
        
        // Load image
        if let url = URL(string: product.thumbnail) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.productImageView.image = image
                    }
                }
            }.resume()
        }
        
        buyButton.addAction(UIAction { _ in onBuyTap() }, for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        priceLabel.text = nil
        ratingLabel.text = nil
    }
}
