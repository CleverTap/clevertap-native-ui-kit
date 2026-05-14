package com.nativedisplay.sample.xml

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.nativedisplay.sample.xml.data.DummyJsonApi
import com.nativedisplay.sample.xml.data.Product
import com.nativedisplay.sample.xml.databinding.ActivityMainBinding
import com.nativedisplay.sample.xml.ui.NativeProduct
import com.nativedisplay.sample.xml.ui.ProductAdapter
import com.nativedisplay.sample.xml.ui.SDUIProduct
import com.nativedisplay.sample.xml.ui.SDUIGallery
import kotlinx.coroutines.launch
import com.clevertap.android.nativedisplay.models.*

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var adapter: ProductAdapter
    private val api = DummyJsonApi.create()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupRecyclerView()
        loadProducts()
    }

    private fun setupRecyclerView() {
        adapter = ProductAdapter { productId ->
            Toast.makeText(
                this,
                "Product $productId clicked!",
                Toast.LENGTH_SHORT
            ).show()
        }

        binding.recyclerView.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = this@MainActivity.adapter
        }
    }

    private fun loadProducts() {
        binding.progressBar.visibility = View.VISIBLE

        lifecycleScope.launch {
            try {
                val response = api.getProducts()
                val products: List<Product> = response.products.take(30)

                val feedItems = mutableListOf<com.nativedisplay.sample.xml.ui.FeedItem>()

                products.forEachIndexed { index, product ->
                    // Add gallery every 7 items
                    if (index > 0 && index % 7 == 0) {
                        // Get next 5 products for gallery
                        val galleryProducts = products.drop(index).take(5)
                        if (galleryProducts.isNotEmpty()) {
                            feedItems.add(
                                SDUIGallery(
                                    id = "gallery_$index",
                                    config = createGalleryConfig(galleryProducts)
                                )
                            )
                        }
                    }

                    // Add individual product
                    if (index % 3 == 0) {
                        feedItems.add(
                            SDUIProduct(
                                id = "sdui_${product.id}",
                                config = createProductConfig(product)
                            )
                        )
                    } else {
                        feedItems.add(
                            NativeProduct(
                                id = "native_${product.id}",
                                product = product
                            )
                        )
                    }
                }

                adapter.submitList(feedItems)
                binding.progressBar.visibility = View.GONE

            } catch (e: Exception) {
                e.printStackTrace()
                binding.progressBar.visibility = View.GONE
                Toast.makeText(
                    this@MainActivity,
                    "Error loading products: ${e.message}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }

    private fun createGalleryConfig(products: List<Product>): ResolvedConfig {
        // Theme for gallery
        val theme = Theme(
            id = "gallery_theme",
            defaultStyle = Style(
                textColor = "#333333",
                fontSize = TextDimension(14f),
                fontWeight = FontWeight.NORMAL
            ),
            colors = mapOf(
                "primary" to "#FF3B30",
                "accent" to "#FFA500",
                "background" to "#F5F5F5"
            )
        )

        // Style classes for gallery items
        val styleClasses = listOf(
            StyleClass(
                name = "gallery_header",
                style = Style(
                    fontSize = TextDimension(20f),
                    fontWeight = FontWeight.BOLD,
                    textColor = "#000000"
                )
            ),
            StyleClass(
                name = "gallery_item_card",
                style = Style(
                    backgroundColor = "#FFFFFF",
                    borderRadius = Dimension.dp(12f),
                    shadowColor = "#000000",
                    shadowRadius = 3f,
                    shadowOffsetY = 2f
                )
            ),
            StyleClass(
                name = "gallery_title",
                style = Style(
                    fontSize = TextDimension(14f),
                    fontWeight = FontWeight.MEDIUM,
                    textColor = "#000000"
                )
            ),
            StyleClass(
                name = "gallery_price",
                style = Style(
                    fontSize = TextDimension(16f),
                    fontWeight = FontWeight.BOLD,
                    textColor = "#FF3B30"
                )
            )
        )

        // Create gallery items
        val galleryItems = products.map { product ->
            NativeDisplayContainer(
                id = "gallery_item_${product.id}",
                containerType = ContainerType.VERTICAL,
                styleClass = "gallery_item_card",
                layout = Layout(
                    width = Dimension.dp(160f),
                    padding = Spacing.all(12f)
                ),
                children = listOf(
                    // Product Image
                    NativeDisplayElement(
                        id = "gallery_image_${product.id}",
                        elementType = ElementType.IMAGE,
                        bindings = mapOf("url" to product.thumbnail),
                        layout = Layout(
                            width = Dimension.MATCH_PARENT,
                            height = Dimension.dp(140f)
                        ),
                        style = Style(
                            borderRadius = Dimension.dp(8f)
                        )
                    ),

                    // Spacer
                    NativeDisplayElement(
                        id = "gallery_spacer1_${product.id}",
                        elementType = ElementType.SPACER,
                        layout = Layout(
                            height = Dimension.dp(8f)
                        )
                    ),

                    // Product Title
                    NativeDisplayElement(
                        id = "gallery_title_${product.id}",
                        elementType = ElementType.TEXT,
                        bindings = mapOf("text" to product.title.take(40) + "..."),
                        styleClass = "gallery_title"
                    ),

                    // Spacer
                    NativeDisplayElement(
                        id = "gallery_spacer2_${product.id}",
                        elementType = ElementType.SPACER,
                        layout = Layout(
                            height = Dimension.dp(4f)
                        )
                    ),

                    // Price with Rating
                    NativeDisplayContainer(
                        id = "gallery_footer_${product.id}",
                        containerType = ContainerType.HORIZONTAL,
                        layout = Layout(
                            arrangement = ChildArrangement.spaceBetween()
                        ),
                        children = listOf(
                            NativeDisplayElement(
                                id = "gallery_price_${product.id}",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "$${product.price}"),
                                styleClass = "gallery_price"
                            ),
                            NativeDisplayElement(
                                id = "gallery_rating_${product.id}",
                                elementType = ElementType.TEXT,
                                bindings = mapOf("text" to "⭐ ${product.rating}"),
                                style = Style(
                                    fontSize = TextDimension(12f),
                                    textColor = "#666666"
                                )
                            )
                        )
                    )
                ),
                actions = mapOf(
                    "onClick" to Action.TrackEvent(
                        eventName = "gallery_product_click"
                    )
                )
            )
        }

        // Root container with header and gallery
        val root = NativeDisplayContainer(
            id = "product_gallery_root",
            containerType = ContainerType.VERTICAL,
            layout = Layout(
                padding = Spacing.vertical(16f)
            ),
            children = listOf(
                // Gallery Header
                NativeDisplayElement(
                    id = "gallery_header",
                    elementType = ElementType.TEXT,
                    bindings = mapOf("text" to "🔥 Trending Products"),
                    styleClass = "gallery_header",
                    layout = Layout(
                        padding = Spacing.horizontal(16f)
                    )
                ),

                // Spacer
                NativeDisplayElement(
                    id = "gallery_header_spacer",
                    elementType = ElementType.SPACER,
                    layout = Layout(
                        height = Dimension.dp(12f)
                    )
                ),

                // Gallery Container
                NativeDisplayContainer(
                    id = "product_gallery",
                    containerType = ContainerType.GALLERY,
                    galleryConfig = GalleryConfig(
                        mode = GalleryMode.FREE_FLOW_GRID,
                        orientation = Orientation.HORIZONTAL,
                        itemsPerView = 2.2f, // Show 2.2 items for peek effect
                        spacing = 12f,
                        showIndicators = false
                    ),
                    layout = Layout(
                        height = Dimension.dp(280f)
                    ),
                    children = galleryItems
                )
            )
        )

        return ResolvedConfig(
            theme = theme,
            styleClasses = styleClasses,
            variables = emptyMap(),
            root = root
        )
    }

    private fun createProductConfig(product: Product): ResolvedConfig {
        // No variables - using inline content directly in bindings

        // Create theme
        val theme = Theme(
            id = "product_card_theme",
            defaultStyle = Style(
                textColor = "#333333",
                fontSize = TextDimension(14f),
                fontWeight = FontWeight.NORMAL
            ),
            colors = mapOf(
                "primary" to "#FF3B30",
                "secondary" to "#666666",
                "background" to "#FFFFFF"
            )
        )

        // Create style classes
        val styleClasses = listOf(
            StyleClass(
                name = "card",
                style = Style(
                    backgroundColor = "#FFFFFF",
                    borderRadius = Dimension.dp(12f),
                    shadowColor = "#000000",
                    shadowRadius = 4f,
                    shadowOffsetY = 2f
                )
            ),
            StyleClass(
                name = "title",
                style = Style(
                    fontSize = TextDimension(18f),
                    fontWeight = FontWeight.BOLD,
                    textColor = "#000000"
                )
            ),
            StyleClass(
                name = "description",
                style = Style(
                    fontSize = TextDimension(14f),
                    textColor = "#666666",
                    lineHeight = TextDimension(20f)
                )
            ),
            StyleClass(
                name = "button",
                style = Style(
                    backgroundColor = "#FF3B30",
                    textColor = "#FFFFFF",
                    fontSize = TextDimension(16f),
                    fontWeight = FontWeight.MEDIUM,
                    borderRadius = Dimension.dp(8f)
                )
            )
        )

        // Create UI tree with inline content (no template variables)
        val root = NativeDisplayContainer(
            id = "product_card",
            containerType = ContainerType.VERTICAL,
            styleClass = "card",
            layout = Layout(
                padding = Spacing.all(16f)
            ),
            children = listOf(
                // Product Image - inline content
                NativeDisplayElement(
                    id = "product_image",
                    elementType = ElementType.IMAGE,
                    bindings = mapOf("url" to product.thumbnail), // Direct value, no {{}}
                    layout = Layout(
                        width = Dimension.MATCH_PARENT,
                        height = Dimension.dp(200f)
                    ),
                    style = Style(
                        borderRadius = Dimension.dp(8f)
                    )
                ),

                // Spacer
                NativeDisplayElement(
                    id = "spacer1",
                    elementType = ElementType.SPACER,
                    layout = Layout(
                        height = Dimension.dp(12f)
                    )
                ),

                // Product Title - inline content
                NativeDisplayElement(
                    id = "product_title",
                    elementType = ElementType.TEXT,
                    bindings = mapOf("text" to product.title), // Direct value
                    styleClass = "title"
                ),

                // Spacer
                NativeDisplayElement(
                    id = "spacer2",
                    elementType = ElementType.SPACER,
                    layout = Layout(
                        height = Dimension.dp(8f)
                    )
                ),

                // Product Description - inline content
                NativeDisplayElement(
                    id = "product_description",
                    elementType = ElementType.TEXT,
                    bindings = mapOf("text" to product.description), // Direct value
                    styleClass = "description"
                ),

                // Spacer
                NativeDisplayElement(
                    id = "spacer3",
                    elementType = ElementType.SPACER,
                    layout = Layout(
                        height = Dimension.dp(12f)
                    )
                ),

                // Price and Rating Row
                NativeDisplayContainer(
                    id = "info_row",
                    containerType = ContainerType.HORIZONTAL,
                    layout = Layout(
                        arrangement = ChildArrangement.spaceBetween()
                    ),
                    children = listOf(
                        // Price - inline content
                        NativeDisplayElement(
                            id = "price",
                            elementType = ElementType.TEXT,
                            bindings = mapOf("text" to "$${product.price}"), // Direct value
                            style = Style(
                                fontSize = TextDimension(20f),
                                fontWeight = FontWeight.BOLD,
                                textColor = "#FF3B30"
                            )
                        ),
                        // Rating - inline content
                        NativeDisplayElement(
                            id = "rating",
                            elementType = ElementType.TEXT,
                            bindings = mapOf("text" to "⭐ ${product.rating}"), // Direct value
                            style = Style(
                                fontSize = TextDimension(14f),
                                textColor = "#666666"
                            )
                        )
                    )
                ),

                // Spacer
                NativeDisplayElement(
                    id = "spacer4",
                    elementType = ElementType.SPACER,
                    layout = Layout(
                        height = Dimension.dp(16f)
                    )
                ),

                // Buy Now Button - inline content
                NativeDisplayElement(
                    id = "buy_button",
                    elementType = ElementType.BUTTON,
                    bindings = mapOf("text" to "Buy Now"), // Direct value
                    styleClass = "button",
                    layout = Layout(
                        width = Dimension.MATCH_PARENT,
                        padding = Spacing.vertical(12f)
                    ),
                    actions = mapOf(
                        "onClick" to Action.TrackEvent(
                            eventName = "buy_product"
                        )
                    )
                )
            )
        )

        return ResolvedConfig(
            theme = theme,
            styleClasses = styleClasses,
            variables = emptyMap(), // No variables - all content is inline
            root = root
        )
    }
}
