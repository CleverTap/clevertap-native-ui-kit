//
//  ConfigBuilder.swift
//  NativeDisplayUiKit
//
//  Helper to build ResolvedConfig from Product data
//

import Foundation
import CleverTapNativeDisplay

class ConfigBuilder {
    
    // MARK: - Product Card Config
    
    static func createProductConfig(product: Product) -> ResolvedConfig {
        let theme = Theme(
            id: "product_card_theme",
            defaultStyle: Style(
                textColor: "#333333",
                fontSize: 14,
                fontWeight: .normal
            ),
            colors: [
                "primary": "#FF3B30",
                "secondary": "#666666",
                "background": "#FFFFFF"
            ]
        )
        
        let styleClasses = [
            StyleClass(
                name: "card",
                style: Style(
                    backgroundColor: "#FFFFFF",
                    borderRadius: 12,
                    shadowColor: "#000000",
                    shadowRadius: 4,
                    shadowOffsetY: 2
                )
            ),
            StyleClass(
                name: "title",
                style: Style(
                    textColor: "#000000",
                    fontSize: 18,
                    fontWeight: .bold
                )
            ),
            StyleClass(
                name: "description",
                style: Style(
                    textColor: "#666666",
                    fontSize: 14,
                    lineHeight: 20
                )
            ),
            StyleClass(
                name: "button",
                style: Style(
                    textColor: "#FFFFFF",
                    fontSize: 16,
                    fontWeight: .medium,
                    backgroundColor: "#FF3B30",
                    borderRadius: 8
                )
            )
        ]
        
        let root = NativeDisplayNode.container(
            NativeDisplayContainer(
                id: "product_card",
                containerType: .vertical,
                children: [
                    // Product Image
                    .element(
                        NativeDisplayElement(
                            id: "product_image",
                            elementType: .image,
                            bindings: ["src": product.thumbnail],
                            layout: Layout(
                                width: .matchParent,
                                height: .dp(200)
                            ),
                            style: Style(borderRadius: 8)
                        )
                    ),
                    
                    // Spacer
                    .element(
                        NativeDisplayElement(
                            id: "spacer1",
                            elementType: .spacer,
                            layout: Layout(height: .dp(12))
                        )
                    ),
                    
                    // Title
                    .element(
                        NativeDisplayElement(
                            id: "product_title",
                            elementType: .text,
                            bindings: ["text": product.title],
                            styleClass: "title"
                        )
                    ),
                    
                    // Spacer
                    .element(
                        NativeDisplayElement(
                            id: "spacer2",
                            elementType: .spacer,
                            layout: Layout(height: .dp(8))
                        )
                    ),
                    
                    // Description
                    .element(
                        NativeDisplayElement(
                            id: "product_description",
                            elementType: .text,
                            bindings: ["text": product.description],
                            styleClass: "description"
                        )
                    ),
                    
                    // Spacer
                    .element(
                        NativeDisplayElement(
                            id: "spacer3",
                            elementType: .spacer,
                            layout: Layout(height: .dp(12))
                        )
                    ),
                    
                    // Price and Rating Row
                    .container(
                        NativeDisplayContainer(
                            id: "info_row",
                            containerType: .horizontal,
                            children: [
                                .element(
                                    NativeDisplayElement(
                                        id: "price",
                                        elementType: .text,
                                        bindings: ["text": "$\(product.price)"],
                                        style: Style(
                                            textColor: "#FF3B30",
                                            fontSize: 20,
                                            fontWeight: .bold
                                        )
                                    )
                                ),
                                .element(
                                    NativeDisplayElement(
                                        id: "spacer_price",
                                        elementType: .spacer,
                                        layout: Layout(width: .matchParent)
                                    )
                                ),
                                .element(
                                    NativeDisplayElement(
                                        id: "rating",
                                        elementType: .text,
                                        bindings: ["text": "⭐ \(product.rating)"],
                                        style: Style(
                                            textColor: "#666666",
                                            fontSize: 14
                                        )
                                    )
                                )
                            ],
                            layout: Layout(
                                arrangement: ChildArrangement.spaceBetween()
                            )
                        )
                    ),
                    
                    // Spacer
                    .element(
                        NativeDisplayElement(
                            id: "spacer4",
                            elementType: .spacer,
                            layout: Layout(height: .dp(16))
                        )
                    ),
                    
                    // Buy Button
                    .element(
                        NativeDisplayElement(
                            id: "buy_button",
                            elementType: .button,
                            bindings: ["text": "Buy Now"],
                            layout: Layout(
                                width: .matchParent,
                                padding: .vertical(12)
                            ),
                            styleClass: "button"
                        )
                    )
                ],
                layout: Layout(padding: .all(16)),
                styleClass: "card"
            )
        )
        
        return ResolvedConfig(
            theme: theme,
            styleClasses: styleClasses,
            variables: [:],
            root: root
        )
    }
    
    // MARK: - Gallery Config
    
    static func createGalleryConfig(products: [Product]) -> ResolvedConfig {
        let theme = Theme(
            id: "gallery_theme",
            defaultStyle: Style(
                textColor: "#333333",
                fontSize: 14,
                fontWeight: .normal
            ),
            colors: [
                "primary": "#FF3B30",
                "accent": "#FFA500",
                "background": "#F5F5F5"
            ]
        )
        
        let styleClasses = [
            StyleClass(
                name: "gallery_header",
                style: Style(
                    textColor: "#000000",
                    fontSize: 20,
                    fontWeight: .bold
                )
            ),
            StyleClass(
                name: "gallery_item_card",
                style: Style(
                    backgroundColor: "#FFFFFF",
                    borderRadius: 12,
                    shadowColor: "#000000",
                    shadowRadius: 3,
                    shadowOffsetY: 2
                )
            ),
            StyleClass(
                name: "gallery_title",
                style: Style(
                    textColor: "#000000",
                    fontSize: 14,
                    fontWeight: .medium
                )
            ),
            StyleClass(
                name: "gallery_price",
                style: Style(
                    textColor: "#FF3B30",
                    fontSize: 16,
                    fontWeight: .bold
                )
            )
        ]
        
        // Create gallery items
        let galleryItems: [NativeDisplayNode] = products.map { product in
            .container(
                NativeDisplayContainer(
                    id: "gallery_item_\(product.id)",
                    containerType: .vertical,
                    children: [
                        // Product Image
                        .element(
                            NativeDisplayElement(
                                id: "gallery_image_\(product.id)",
                                elementType: .image,
                                bindings: ["src": product.thumbnail],
                                layout: Layout(
                                    width: .matchParent,
                                    height: .dp(140)
                                ),
                                style: Style(borderRadius: 8)
                            )
                        ),
                        
                        // Spacer
                        .element(
                            NativeDisplayElement(
                                id: "gallery_spacer1_\(product.id)",
                                elementType: .spacer,
                                layout: Layout(height: .dp(8))
                            )
                        ),
                        
                        // Title
                        .element(
                            NativeDisplayElement(
                                id: "gallery_title_\(product.id)",
                                elementType: .text,
                                bindings: ["text": String(product.title.prefix(40)) + "..."],
                                styleClass: "gallery_title"
                            )
                        ),
                        
                        // Spacer
                        .element(
                            NativeDisplayElement(
                                id: "gallery_spacer2_\(product.id)",
                                elementType: .spacer,
                                layout: Layout(height: .dp(4))
                            )
                        ),
                        
                        // Price and Rating
                        .container(
                            NativeDisplayContainer(
                                id: "gallery_footer_\(product.id)",
                                containerType: .horizontal,
                                children: [
                                    .element(
                                        NativeDisplayElement(
                                            id: "gallery_price_\(product.id)",
                                            elementType: .text,
                                            bindings: ["text": "$\(product.price)"],
                                            styleClass: "gallery_price"
                                        )
                                    ),
                                    .element(
                                        NativeDisplayElement(
                                            id: "gallery_spacer_\(product.id)",
                                            elementType: .spacer,
                                            layout: Layout(width: .matchParent)
                                        )
                                    ),
                                    .element(
                                        NativeDisplayElement(
                                            id: "gallery_rating_\(product.id)",
                                            elementType: .text,
                                            bindings: ["text": "⭐ \(product.rating)"],
                                            style: Style(
                                                textColor: "#666666",
                                                fontSize: 12
                                            )
                                        )
                                    )
                                ],
                                layout: Layout(
                                    arrangement: ChildArrangement.spaceBetween()
                                )
                            )
                        )
                    ],
                    layout: Layout(
                        width: .dp(160),
                        padding: .all(12)
                    ),
                    styleClass: "gallery_item_card"
                )
            )
        }
        
        // Root with header and gallery
        let root = NativeDisplayNode.container(
            NativeDisplayContainer(
                id: "product_gallery_root",
                containerType: .vertical,
                children: [
                    // Header
                    .element(
                        NativeDisplayElement(
                            id: "gallery_header",
                            elementType: .text,
                            bindings: ["text": "🔥 Trending Products"],
                            layout: Layout(padding: .horizontal(16)),
                            styleClass: "gallery_header"
                        )
                    ),
                    
                    // Spacer
                    .element(
                        NativeDisplayElement(
                            id: "gallery_header_spacer",
                            elementType: .spacer,
                            layout: Layout(height: .dp(12))
                        )
                    ),
                    
                    // Gallery
                    .container(
                        NativeDisplayContainer(
                            id: "product_gallery",
                            containerType: .gallery,
                            children: galleryItems,
                            layout: Layout(height: .dp(280)),
                            galleryConfig: GalleryConfig(
                                mode: .freeFlowGrid,
                                orientation: .horizontal,
                                snapBehavior: .none,
                                itemsPerView: 2.2,
                                spacing: 12,
                                showIndicators: false
                            )
                        )
                    )
                ],
                layout: Layout(padding: .vertical(16))
            )
        )
        
        return ResolvedConfig(
            theme: theme,
            styleClasses: styleClasses,
            variables: [:],
            root: root
        )
    }
}
