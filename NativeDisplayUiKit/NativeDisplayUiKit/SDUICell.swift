//
//  SDUICell.swift
//  NativeDisplayUiKit
//
//  UITableViewCell that hosts Native Display content
//

import UIKit
import CleverTapNativeDisplay

class SDUICell: UITableViewCell {
    
    static let identifier = "SDUICell"
    
    private var displayView: NativeDisplayUIView?
    private weak var parentViewController: UIViewController?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    func configure(with config: ResolvedConfig, parentVC: UIViewController?) {
        self.parentViewController = parentVC
        
        // Remove old view if exists
        displayView?.removeFromSuperview()
        
        // Create new display view
        let newDisplayView = NativeDisplayUIView(config: config)
        newDisplayView.backgroundColor = .clear
        newDisplayView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(newDisplayView)
        
        NSLayoutConstraint.activate([
            newDisplayView.topAnchor.constraint(equalTo: contentView.topAnchor),
            newDisplayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newDisplayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            newDisplayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        self.displayView = newDisplayView
        
        // Force layout to get proper cell height
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        displayView?.removeFromSuperview()
        displayView = nil
    }
}
