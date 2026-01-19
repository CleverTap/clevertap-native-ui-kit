//
//  Example.swift
//  NativeDisplayUiKit
//
//  Data models for examples
//

import UIKit

struct Section {
    let title: String
    let examples: [Example]
}

struct Example {
    let title: String
    let description: String
    let viewControllerType: UIViewController.Type
    let exampleType: ExampleType
    
    var icon: String {
        switch exampleType {
        case .vertical: return "⬇️"
        case .horizontal: return "➡️"
        case .box: return "📦"
        case .stack: return "🗂️"
        case .text: return "📝"
        case .image: return "🖼️"
        case .button: return "🔘"
        case .spacer: return "📏"
        case .jsonEditor: return "📋"
        case .mixedFeed: return "📱"
        }
    }
}

enum ExampleType {
    // Containers
    case vertical
    case horizontal
    case box
    case stack
    
    // Elements
    case text
    case image
    case button
    case spacer
    
    // Tools
    case jsonEditor
    
    // Advanced
    case mixedFeed
}
