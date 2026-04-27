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
 * Sample configurations for testing the renderer.
 * Using direct JPG URLs from picsum
 */
object SampleConfigs {
    
    /**
     * Simple greeting card with text styling.
     */
    fun simpleGreetingCard(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = mapOf(
                "userName" to JsonPrimitive("John Doe")
            ),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(20f)
                ),
                style = Style(
                    backgroundColor = "#FFFFFF",
                    borderRadius = 16f,
                    shadowRadius = 8f,
                    shadowColor = "#00000040"
                ),
                children = listOf(
                    NativeDisplayElement(
                        id = "greeting",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Hello {{userName}}!"),
                        style = Style(
                            fontSize = 24f,
                            fontWeight = FontWeight.BOLD,
                            textColor = "#000000"
                        )
                    ),
                    NativeDisplayElement(
                        id = "subtitle",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Welcome to Native Display Kit"),
                        style = Style(
                            fontSize = 16f,
                            textColor = "#666666"
                        )
                    )
                )
            )
        )
    }
    
    /**
     * Product card with direct image URL
     */
    fun productCard(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme(
                id = "default",
                defaultStyle = Style(
                    textColor = "#000000",
                    fontSize = 14f
                ),
                colors = mapOf(
                    "primary" to "#007AFF",
                    "danger" to "#FF3B30",
                    "success" to "#34C759"
                )
            ),
            styleClasses = listOf(
                StyleClass(
                    name = "card",
                    style = Style(
                        backgroundColor = "#FFFFFF",
                        borderRadius = 16f,
                        shadowRadius = 12f,
                        shadowColor = "#00000020"
                    )
                ),
                StyleClass(
                    name = "price-old",
                    style = Style(
                        fontSize = 16f,
                        textColor = "#999999",
                        textDecoration = TextDecoration.STRIKETHROUGH
                    )
                ),
                StyleClass(
                    name = "price-new",
                    style = Style(
                        fontSize = 24f,
                        fontWeight = FontWeight.BOLD,
                        textColor = "danger"
                    )
                )
            ),
            variables = mapOf(
                "productName" to JsonPrimitive("Wireless Headphones Pro"),
                "productImage" to JsonPrimitive("https://fastly.picsum.photos/id/29/4000/2670.jpg?hmac=rCbRAl24FzrSzwlR5tL-Aqzyu5tX_PA95VJtnUXegGU"),
                "priceOld" to JsonPrimitive("$299.99"),
                "priceNew" to JsonPrimitive("$224.99"),
                "hasDiscount" to JsonPrimitive(true),
                "stockLevel" to JsonPrimitive(5)
            ),
            root = NativeDisplayContainer(
                id = "card-container",
                containerType = ContainerType.VERTICAL,
                styleClass = "card",
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(20f)
                ),
                children = listOf(
                    // Product Image - REAL IMAGE
                    NativeDisplayElement(
                        id = "product-image",
                        elementType = ElementType.IMAGE,
                        bindings = mapOf("url" to "{{productImage}}"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(200f),
                        ),
                        style = Style(
                            backgroundColor = "#F0F0F0",
                            borderRadius = 12f
                        )
                    ),
                    
                    // Product Name
                    NativeDisplayElement(
                        id = "product-name",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "{{productName}}"),
                        style = Style(
                            fontSize = 20f,
                            fontWeight = FontWeight.BOLD
                        ),
                        layout = Layout(
                        )
                    ),
                    
                    // Discount Message
                    NativeDisplayElement(
                        id = "discount-message",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Save 25% Today!"),
                        style = Style(
                            fontSize = 16f,
                            fontWeight = FontWeight.BOLD,
                            textColor = "success"
                        ),
                        visible = "{{hasDiscount}}",
                        layout = Layout(
                        )
                    ),
                    
                    // Price Container
                    NativeDisplayContainer(
                        id = "price-container",
                        containerType = ContainerType.HORIZONTAL,
                        layout = Layout(
                        ),
                        children = listOf(
                            NativeDisplayElement(
                                id = "price-old",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "{{priceOld}}"),
                                styleClass = "price-old",
                                visible = "{{hasDiscount}}",
                                layout = Layout(
                                )
                            ),
                            NativeDisplayElement(
                                id = "price-new",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "{{priceNew}}"),
                                styleClass = "price-new"
                            )
                        )
                    ),
                    
                    // Stock Status
                    NativeDisplayElement(
                        id = "stock-status",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Only {{stockLevel}} left in stock!"),
                        style = Style(
                            fontSize = 14f,
                            fontWeight = FontWeight.MEDIUM,
                            textColor = "#FF9500"
                        ),
                        visible = "{{stockLevel > 0}}",
                        layout = Layout(
                        )
                    ),
                    
                    // Buy Button
                    NativeDisplayElement(
                        id = "buy-button",
                        elementType = ElementType.BUTTON,
                        bindings = mapOf("text" to "Buy Now"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(50f)
                        ),
                        style = Style(
                            backgroundColor = "primary",
                            textColor = "#FFFFFF",
                            fontSize = 18f,
                            fontWeight = FontWeight.BOLD,
                            borderRadius = 12f
                        )
                    )
                )
            )
        )
    }
    
    /**
     * Nested containers example with style inheritance.
     */
    fun nestedContainersDemo(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme(
                id = "default",
                defaultStyle = Style(
                    textColor = "#000000",
                    fontSize = 14f
                )
            ),
            styleClasses = emptyList(),
            variables = mapOf(
                "title" to JsonPrimitive("Nested Containers Demo"),
                "subtitle" to JsonPrimitive("Style inheritance in action")
            ),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f)
                ),
                style = Style(
                    backgroundColor = "#F5F5F5",
                    fontSize = 18f
                ),
                children = listOf(
                    NativeDisplayContainer(
                        id = "level-1",
                        containerType = ContainerType.VERTICAL,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            padding = Spacing.all(16f),
                        ),
                        style = Style(
                            backgroundColor = "#FFFFFF",
                            borderRadius = 12f,
                            shadowRadius = 4f
                        ),
                        children = listOf(
                            NativeDisplayElement(
                                id = "title",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "{{title}}"),
                                style = Style(
                                    fontWeight = FontWeight.BOLD
                                ),
                            ),
                            
                            NativeDisplayContainer(
                                id = "level-2",
                                containerType = ContainerType.VERTICAL,
                                layout = Layout(
                                    padding = Spacing.all(12f)
                                ),
                                style = Style(
                                    backgroundColor = "#E8F4FD",
                                    borderRadius = 8f
                                ),
                                children = listOf(
                                    NativeDisplayElement(
                                        id = "subtitle",
                                        elementType = ElementType.TEXT,
                                        bindings = mapOf("text" to "{{subtitle}}"),
                                        style = Style(
                                            textColor = "#007AFF"
                                        )
                                    ),
                                    
                                    NativeDisplayContainer(
                                        id = "level-3",
                                        containerType = ContainerType.HORIZONTAL,
                                        layout = Layout(
                                            padding = Spacing.all(8f)
                                        ),
                                        style = Style(
                                            backgroundColor = "#D0E8FA",
                                            borderRadius = 6f
                                        ),
                                        children = listOf(
                                            NativeDisplayElement(
                                                id = "deep-text-1",
                                                elementType = ElementType.TEXT,
                                                bindings = mapOf("text" to "Level 3"),
                                                style = Style(
                                                    fontSize = 12f
                                                )
                                            ),
                                            Spacer(layout = Layout(width = Dimension.dp(8f))),
                                            NativeDisplayElement(
                                                id = "deep-text-2",
                                                elementType = ElementType.TEXT,
                                                bindings = mapOf("text" to "Deep Nesting!"),
                                                style = Style(
                                                    fontSize = 12f,
                                                    fontWeight = FontWeight.BOLD
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    }
    
    /**
     * All element types with direct image URL
     */
    fun allElementsDemo(): ResolvedConfig {
        return ResolvedConfig(
            theme = Theme.DEFAULT,
            styleClasses = emptyList(),
            variables = mapOf(
                "userName" to JsonPrimitive("Test User"),
                "imageUrl" to JsonPrimitive("https://fastly.picsum.photos/id/29/4000/2670.jpg?hmac=rCbRAl24FzrSzwlR5tL-Aqzyu5tX_PA95VJtnUXegGU")
            ),
            root = NativeDisplayContainer(
                id = "root",
                containerType = ContainerType.VERTICAL,
                layout = Layout(
                    width = Dimension.MATCH_PARENT,
                    height = Dimension.WRAP_CONTENT,
                    padding = Spacing.all(16f)
                ),
                children = listOf(
                    // TEXT
                    NativeDisplayElement(
                        id = "text-demo",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to "Text Element: {{userName}}"),
                        style = Style(fontSize = 20f, fontWeight = FontWeight.BOLD),
                    ),
                    
                    // IMAGE - REAL IMAGE
                    NativeDisplayElement(
                        id = "image-demo",
                        elementType = ElementType.IMAGE,
                        bindings = mapOf("url" to "{{imageUrl}}"),
                        layout = Layout(
                            width = Dimension.dp(150f),
                            height = Dimension.dp(150f),
                        ),
                        style = Style(
                            borderRadius = 75f,
                            backgroundColor = "#F0F0F0"
                        )
                    ),
                    
                    // BUTTON
                    NativeDisplayElement(
                        id = "button-demo",
                        elementType = ElementType.BUTTON,
                        bindings = mapOf("text" to "Button Element"),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                        ),
                        style = Style(
                            backgroundColor = "#34C759",
                            textColor = "#FFFFFF"
                        )
                    ),
                    
                    // SPACER
                    NativeDisplayElement(
                        id = "spacer-demo",
                        elementType = ElementType.SPACER,
                        layout = Layout(height = Dimension.dp(32f))
                    ),
                    
                    // VIDEO (placeholder)
                    NativeDisplayElement(
                        id = "video-demo",
                        elementType = ElementType.VIDEO,
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(200f)
                        ),
                        style = Style(
                            borderRadius = 12f
                        )
                    )
                )
            )
        )
    }
    
    private fun Spacer(layout: Layout? = null): NativeDisplayElement {
        return NativeDisplayElement(
            id = "spacer-${System.currentTimeMillis()}",
            elementType = ElementType.SPACER,
            layout = layout
        )
    }
}

@Composable
fun SimpleGreetingCardSample() {
    NativeDisplayView(
        config = SampleConfigs.simpleGreetingCard(),
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    )
}

@Composable
fun ProductCardSample() {
    NativeDisplayView(
        config = SampleConfigs.productCard(),
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    )
}

@Composable
fun NestedContainersSample() {
    NativeDisplayView(
        config = SampleConfigs.nestedContainersDemo(),
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    )
}

@Composable
fun AllElementsSample() {
    NativeDisplayView(
        config = SampleConfigs.allElementsDemo(),
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    )
}
