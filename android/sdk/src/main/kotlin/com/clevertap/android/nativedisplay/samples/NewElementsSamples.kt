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
                    padding = Spacing.all(4f)
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
                        style = Style(fontSize = 30f, fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Horizontal divider (default)
                    NativeDisplayElement(
                        id = "divider1",
                        elementType = ElementType.DIVIDER,
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
                        style = Style(fontSize = 30f, fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Thick colored divider
                    NativeDisplayElement(
                        id = "divider2",
                        elementType = ElementType.DIVIDER,
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
                        style = Style(fontSize = 30f, fontWeight = FontWeight.BOLD)
                    ),

                    NativeDisplayElement(
                        id = "divider2",
                        elementType = ElementType.DIVIDER,
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
                            margin = Spacing(top = 20f),
                            padding = Spacing.all(16f)
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
                                layout = Layout(width = Dimension.dp(80f))
                            ),
                            
                            // Vertical divider
                            NativeDisplayElement(
                                id = "v-divider",
                                elementType = ElementType.DIVIDER,
                                dividerConfig = DividerConfig(
                                    orientation = Orientation.VERTICAL,
                                    thickness = 8f,
                                    color = "#999999"
                                )
                            ),
                            
                            NativeDisplayElement(
                                id = "col2",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "Column 2"),
                                layout = Layout(
                                    width = Dimension.dp(80f),
                                    padding = Spacing(all = 4f)
                                )
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
                    padding = Spacing.all(16f)
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Simple Gallery"),
                        style = Style(fontSize = 24f, fontWeight = FontWeight.BOLD),
                        layout = Layout(margin = Spacing(bottom = 16f))
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(200f)
                        ),
                        galleryConfig = GalleryConfig(
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = false,
                            peekPercentage = 15f
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
                    padding = Spacing.all(16f)
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Full-Featured Gallery"),
                        style = Style(fontSize = 24f, fontWeight = FontWeight.BOLD),
                        layout = Layout(margin = Spacing(bottom = 8f))
                    ),
                    
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Auto-scroll • Infinite • Arrows • Indicators"),
                        style = Style(fontSize = 12f, textColor = "#666666"),
                        layout = Layout(margin = Spacing(bottom = 16f))
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(250f)
                        ),
                        galleryConfig = GalleryConfig(
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = true,
                            peekPercentage = 20f,
                            autoScrollInterval = 3000,
                            infiniteScroll = true,
                            arrowStyle = ArrowStyle(
                                size = 32f,
                                color = "#77FFFFFF",
                                backgroundColor = "#77007AFF",
                                borderRadius = 20f,
                                padding = 8f,
                                position = "inside"
                            ),
                            indicatorStyle = IndicatorStyle(
                                size = 10f,
                                activeColor = "#007AFF",
                                inactiveColor = "#CCCCCC",
                                spacing = 8f,
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
                    padding = Spacing.all(16f)
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Free-Flow Gallery"),
                        style = Style(fontSize = 24f, fontWeight = FontWeight.BOLD),
                        layout = Layout(margin = Spacing(bottom = 8f))
                    ),
                    
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "No snapping • Scroll freely"),
                        style = Style(fontSize = 12f, textColor = "#666666"),
                        layout = Layout(margin = Spacing(bottom = 16f))
                    ),
                    
                    NativeDisplayContainer(
                        id = "gallery",
                        containerType = ContainerType.GALLERY,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(180f)
                        ),
                        galleryConfig = GalleryConfig(
                            snapBehavior = SnapBehavior.NONE,
                            showIndicators = false,
                            showArrows = false
                        ),
                        children = createGalleryItems(10)
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
                    padding = Spacing.all(16f)
                ),
                children = listOf(
                    // Title
                    NativeDisplayElement(
                        id = "title",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Featured Products"),
                        style = Style(fontSize = 28f, fontWeight = FontWeight.BOLD)
                    ),
                    
                    // Subtitle
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Swipe to explore our collection"),
                        style = Style(fontSize = 14f, textColor = "#666666"),
                        layout = Layout(margin = Spacing(top = 4f, bottom = 16f))
                    ),
                    
                    // Divider
                    NativeDisplayElement(
                        id = "divider1",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(margin = Spacing(bottom = 20f)),
                        dividerConfig = DividerConfig(
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
                            height = Dimension.dp(220f)
                        ),
                        galleryConfig = GalleryConfig(
                            snapBehavior = SnapBehavior.CENTER,
                            showIndicators = true,
                            showArrows = true,
                            peekPercentage = 10f,
                            indicatorStyle = IndicatorStyle(
                                size = 8f,
                                activeColor = "#FF6B6B",
                                inactiveColor = "#DDDDDD"
                            ),
                            arrowStyle = ArrowStyle(
                                size = 28f,
                                color = "#FF6B6B",
                                backgroundColor = "#FFFFFF",
                                borderRadius = 16f
                            )
                        ),
                        children = createProductCards()
                    ),
                    
                    // Divider
                    NativeDisplayElement(
                        id = "divider2",
                        elementType = ElementType.DIVIDER,
                        layout = Layout(margin = Spacing(top = 20f, bottom = 20f)),
                        dividerConfig = DividerConfig(
                            thickness = 2f,
                            color = "#E0E0E0"
                        )
                    ),
                    
                    // Footer text
                    NativeDisplayElement(
                        id = "footer",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "More products coming soon!"),
                        style = Style(
                            fontSize = 16f,
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
                    padding = Spacing.all(20f)
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
                        style = Style(
                            fontSize = 24f,
                            fontWeight = FontWeight.BOLD,
                            textColor = "#FFFFFF",
                            textAlign = "center"
                        )
                    ),
                    NativeDisplayElement(
                        id = "item-desc-$index",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Swipe to see more"),
                        style = Style(
                            fontSize = 14f,
                            textColor = "#FFFFFF",
                            textAlign = "center"
                        ),
                        layout = Layout(margin = Spacing(top = 8f))
                    )
                )
            )
        }
    }
    
    private fun createProductCards(): List<NativeDisplayNode> {
        val products = listOf(
            "Wireless Headphones" to "#4A90E2",
            "Smart Watch" to "#E24A4A",
            "Laptop Stand" to "#4AE290",
            "USB-C Cable" to "#E2904A",
            "Phone Case" to "#904AE2"
        )
        
        return products.map { (name, color) ->
            NativeDisplayContainer(
                id = "product-${name.replace(" ", "-").lowercase()}",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    padding = Spacing.all(16f)
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
                        id = "product-image",
                        elementType = ElementType.SPACER,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(120f),
                            margin = Spacing(bottom = 12f)
                        ),
                        style = Style(
                            backgroundColor = color,
                            borderRadius = 8f
                        )
                    ),
                    
                    // Product name
                    NativeDisplayElement(
                        id = "product-name",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to name),
                        style = Style(
                            fontSize = 18f,
                            fontWeight = FontWeight.BOLD
                        ),
                        layout = Layout(margin = Spacing(bottom = 4f))
                    ),
                    
                    // Price
                    NativeDisplayElement(
                        id = "product-price",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "$${(50..150).random()}.99"),
                        style = Style(
                            fontSize = 20f,
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
