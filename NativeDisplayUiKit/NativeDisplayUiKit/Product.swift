//
//  Product.swift
//  NativeDisplayUiKit
//
//  Product model for demo
//

import Foundation

struct Product: Codable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let rating: Double
    let thumbnail: String
}

struct ProductResponse: Codable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}
