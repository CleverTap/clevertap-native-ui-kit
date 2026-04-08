package com.clevertap.android.nativedisplay.samples

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.models.*
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import kotlinx.serialization.json.JsonPrimitive

/**
 * Sample configurations for divider and gallery elements.
 */
object NewElementsSamples {
    
    /**
     * Divider samples - horizontal and vertical.
     */
    fun dividerDemo(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f),
                ),
                style = Style(
                    backgroundColor = "#FFFFFF"
                ),
                children = listOf(
                    // Section 1
                    NativeDisplayElement(
                        id = "text1",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Section 1"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Horizontal divider (default)
                    NativeDisplayElement(
                        id = "divider1",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(1f)
                        ),
                        dividerConfig = DividerConfig(
                            orientation = Orientation.HORIZONTAL,
                            thickness = 1f,
                            color = "#DDDDDD"
                        )
                    ),
                    
                    // Section 2
                    NativeDisplayElement(
                        id = "text2",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Section 2"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Thick colored divider
                    NativeDisplayElement(
                        id = "divider2",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(4f)
                        ),
                        dividerConfig = DividerConfig(
                            orientation = Orientation.HORIZONTAL,
                            thickness = 4f,
                            color = "#007AFF"
                        )
                    ),
                    
                    // Section 3
                    NativeDisplayElement(
                        id = "text3",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Section 3"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),

                    // Purple divider with alpha
                    NativeDisplayElement(
                        id = "divider3",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(4f)
                        ),
                        dividerConfig = DividerConfig(
                            orientation = Orientation.HORIZONTAL,
                            thickness = 4f,
                            color = "#88FFAAFF"
                        )
                    ),
                    
                    // Horizontal container with vertical dividers
                    NativeDisplayContainer(
                        id = "h-container",
                        containerType = ContainerType.HORIZONTAL,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(60f),
                            padding = Spacing.all(8f),
                        ),
                        style = Style(
                            backgroundColor = "#F5F5F5",
                            borderRadius = 8f
                        ),
                        children = listOf(
                            NativeDisplayElement(
                                id = "col1",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "Column 1"),
                                layout = Layout(
                                    width = Dimension.WRAP_CONTENT,
                                    height = Dimension.WRAP_CONTENT
                                ),
                                style = Style(fontSize = TextDimension(16f))
                            ),
                            
                            // Vertical divider
                            NativeDisplayElement(
                                id = "v-divider",
                                elementType = ElementType.DIVIDER,
                                layout = Layout(
                                    width = Dimension.dp(2f),
                                    height = Dimension.MATCH_PARENT
                                ),
                                dividerConfig = DividerConfig(
                                    orientation = Orientation.VERTICAL,
                                    thickness = 2f,
                                    color = "#999999"
                                )
                            ),
                            
                            NativeDisplayElement(
                                id = "col2",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "Column 2"),
                                layout = Layout(
                                    width = Dimension.WRAP_CONTENT,
                                    height = Dimension.WRAP_CONTENT
                                ),
                                style = Style(fontSize = TextDimension(16f))
                            )
                        )
                    )
                )
            )
        )
    }
    
    /**
     * Simple gallery with center snap.
     */
    fun simpleGallery(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f),
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Simple Gallery"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(200f)
                        ),
                        galleryConfig = GalleryConfig(
                            mode = GalleryMode.SNAPPING,
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = false,
                            peek = PeekConfig(before = 24f, after = 24f),
                            spacing = 12f
                        ),
                        children = createGalleryItems(5)
                    )
                )
            )
        )
    }
    
    /**
     * Gallery with all features enabled.
     */
    fun fullFeaturedGallery(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f),
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Full-Featured Gallery"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Auto-scroll • Infinite • Arrows • Indicators"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT,
                        ),
                        style = Style(fontSize = TextDimension(12f), textColor = "#666666")
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(250f)
                        ),
                        galleryConfig = GalleryConfig(
                            mode = GalleryMode.SNAPPING,
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = true,
                            peek = PeekConfig(before = 32f, after = 32f),
                            spacing = 12f,
                            autoScrollInterval = 3000,
                            infiniteScroll = true,
                            arrowStyle = ArrowStyle(
                                size = 32f,
                                color = "#FFFFFF",
                                backgroundColor = "#77007AFF",
                                padding = 8f
                            ),
                            indicatorStyle = IndicatorStyle(
                                size = 10f,
                                activeColor = "#007AFF",
                                inactiveColor = "#CCCCCC",
                                position = "bottom",
                                shape = "circle"
                            )
                        ),
                        children = createGalleryItems(7)
                    )
                )
            )
        )
    }
    
    /**
     * Free-flowing gallery (no snap).
     */
    fun freeFlowGallery(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f),
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Free-Flow Gallery"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(24f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "No snapping • Scroll freely"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT,
                        ),
                        style = Style(fontSize = TextDimension(12f), textColor = "#666666")
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(180f)
                        ),
                        galleryConfig = GalleryConfig(
                            mode = GalleryMode.FREE_FLOW,
                            snapBehavior = SnapBehavior.NONE,
                            showIndicators = false,
                            showArrows = false,
                            spacing = 12f
                        ),
                        children = createFreeFlowItems(10)
                    )
                )
            )
        )
    }
    
    /**
     * Combined demo showing dividers and gallery together.
     */
    fun combinedDemo(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f),
                    arrangement = ChildArrangement.spaceBetween()
                ),
                children = listOf(
                    // Title
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Featured Products"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(fontSize = TextDimension(28f), fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Subtitle
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Swipe to explore our collection"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT,
                        ),
                        style = Style(fontSize = TextDimension(14f), textColor = "#666666")
                    ),
                    
                    // Divider
                    NativeDisplayElement(
                        id = "divider1",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(2f),
                        ),
                        dividerConfig = DividerConfig(
                            orientation = Orientation.HORIZONTAL,
                            thickness = 2f,
                            color = "#E0E0E0"
                        )
                    ),
                    
                    // Gallery
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(280f)
                        ),
                        galleryConfig = GalleryConfig(
                            mode = GalleryMode.SNAPPING,
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = true,
                            peek = PeekConfig(before = 16f, after = 16f),
                            spacing = 12f,
                            indicatorStyle = IndicatorStyle(
                                size = 8f,
                                activeColor = "#FF6B6B",
                                inactiveColor = "#DDDDDD",
                                spacing = 6f,
                                position = "bottom",
                                shape = "circle"
                            ),
                            arrowStyle = ArrowStyle(
                                size = 28f,
                                color = "#FF6B6B",
                                backgroundColor = "#FFFFFF",
                                padding = 8f
                            )
                        ),
                        children = createProductCards()
                    ),
                    
                    // Divider
                    NativeDisplayElement(
                        id = "divider2",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(2f),
                        ),
                        dividerConfig = DividerConfig(
                            orientation = Orientation.HORIZONTAL,
                            thickness = 2f,
                            color = "#E0E0E0"
                        )
                    ),
                    
                    // Footer text
                    NativeDisplayElement(
                        id = "footer",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "More products coming soon!"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(
                            fontSize = TextDimension(16f),
                            textColor = "#999999",
                            textAlign = "center"
                        )
                    )
                )
            )
        )
    }
    
    // Helper functions
    
    private fun createGalleryItems(count: Int): List<NativeDisplayNode> {
        val colors = listOf("#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE")
        return (0 until count).map { index ->
            NativeDisplayContainer(
                id = "item-$index",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.MATCH_PARENT,
                    padding = Spacing.all(20f),
                ),
                style = Style(
                    backgroundColor = colors[index % colors.size],
                    borderRadius = 16f
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "item-title-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Item ${index + 1}"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(
                            fontSize = TextDimension(24f),
                            fontWeight = FontWeight.BOLD,
                            textColor = "#FFFFFF",
                            textAlign = "center"
                        )
                    ),
                    NativeDisplayElement(
                        id = "item-desc-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Swipe to see more"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(
                            fontSize = TextDimension(14f),
                            textColor = "#FFFFFF",
                            textAlign = "center"
                        )
                    )
                )
            )
        }
    }
    
    private fun createFreeFlowItems(count: Int): List<NativeDisplayNode> {
        val colors = listOf("#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE")
        val labels = listOf("New", "Popular", "Sale", "Trending", "Featured", "Hot", "Limited", "Best", "Top", "Exclusive")
        return (0 until count).map { index ->
            NativeDisplayContainer(
                id = "chip-$index",
                containerType = ContainerType.BOX,
                layout = Layout(
                    width = Dimension.WRAP_CONTENT,
                    height = Dimension.dp(40f),
                    padding = Spacing(horizontal = 16f, vertical = 8f)
                ),
                style = Style(
                    backgroundColor = colors[index % colors.size],
                    borderRadius = 20f
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "chip-text-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to labels[index % labels.size]),
                        layout = Layout(
                            width = Dimension.WRAP_CONTENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(
                            fontSize = TextDimension(14f),
                            fontWeight = FontWeight.BOLD,
                            textColor = "#FFFFFF"
                        )
                    )
                )
            )
        }
    }
    
    private fun createProductCards(): List<NativeDisplayNode> {
        val products = listOf(
            Triple("Wireless Headphones", "$129.99", "#4A90E2"),
            Triple("Smart Watch", "$249.99", "#E24A4A"),
            Triple("Laptop Stand", "$79.99", "#4AE290"),
            Triple("USB-C Cable", "$19.99", "#E2904A"),
            Triple("Phone Case", "$39.99", "#904AE2")
        )
        
        return products.mapIndexed { index, (name, price, color) ->
            NativeDisplayContainer(
                id = "product-$index",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.MATCH_PARENT,
                    padding = Spacing.all(16f),
                ),
                style = Style(
                    backgroundColor = "#FFFFFF",
                    borderRadius = 12f,
                    shadowRadius = 8f,
                    shadowColor = "#00000020"
                ),
                children = listOf(
                    // Product color box (placeholder for image)
                    NativeDisplayElement(
                        id = "product-image-$index",
                        elementType = ElementType.SPACER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(120f),
                        ),
                        style = Style(
                            backgroundColor = color,
                            borderRadius = 8f
                        )
                    ),
                    
                    // Product name
                    NativeDisplayElement(
                        id = "product-name-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to name),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT,
                        ),
                        style = Style(
                            fontSize = TextDimension(18f),
                            fontWeight = FontWeight.BOLD,
                            textColor = "#1A1A1A"
                        )
                    ),
                    
                    // Price
                    NativeDisplayElement(
                        id = "product-price-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to price),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.WRAP_CONTENT
                        ),
                        style = Style(
                            fontSize = TextDimension(20f),
                            fontWeight = FontWeight.BOLD,
                            textColor = "#007AFF"
                        )
                    )
                )
            )
        }
    }
}

// Composable wrappers for sample app

@Composable
fun DividerDemoSample() {
    NativeDisplayView(
        config = NewElementsSamples.dividerDemo(),
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    )
}

@Composable
fun SimpleGallerySample() {
    NativeDisplayView(
        config = NewElementsSamples.simpleGallery(),
        modifier = Modifier.fillMaxSize()
    )
}

@Composable
fun FullFeaturedGallerySample() {
    NativeDisplayView(
        config = NewElementsSamples.fullFeaturedGallery(),
        modifier = Modifier.fillMaxSize()
    )
}

@Composable
fun FreeFlowGallerySample() {
    NativeDisplayView(
        config = NewElementsSamples.freeFlowGallery(),
        modifier = Modifier.fillMaxSize()
    )
}

@Composable
fun CombinedDemoSample() {
    NativeDisplayView(
        config = NewElementsSamples.combinedDemo(),
        modifier = Modifier.fillMaxSize()
    )
}
