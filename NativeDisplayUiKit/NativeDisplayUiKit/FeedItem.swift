//
//  FeedItem.swift
//  NativeDisplayUiKit
//
//  Feed item types for mixed native/SDUI content
//

import Foundation
import CleverTapNativeDisplay

enum FeedItem {
    case nativeProduct(id: String, product: Product)
    case sduiProduct(id: String, config: ResolvedConfig)
    case sduiGallery(id: String, config: ResolvedConfig)
    
    var id: String {
        switch self {
        case .nativeProduct(let id, _): return id
        case .sduiProduct(let id, _): return id
        case .sduiGallery(let id, _): return id
        }
    }
}
