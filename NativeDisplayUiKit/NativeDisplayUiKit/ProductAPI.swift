//
//  ProductAPI.swift
//  NativeDisplayUiKit
//
//  API service for fetching products
//

import Foundation

class ProductAPI {
    static let shared = ProductAPI()
    
    private init() {}
    
    func fetchProducts() async throws -> ProductResponse {
        let url = URL(string: "https://dummyjson.com/products?limit=30")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(ProductResponse.self, from: data)
    }
}
