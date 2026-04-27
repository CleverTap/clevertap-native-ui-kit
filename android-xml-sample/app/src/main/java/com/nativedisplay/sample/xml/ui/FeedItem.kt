package com.nativedisplay.sample.xml.ui

import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.nativedisplay.sample.xml.data.Product

sealed class FeedItem {
    abstract val id: String
}

data class NativeProduct(
    override val id: String,
    val product: Product
) : FeedItem()

data class SDUIProduct(
    override val id: String,
    val config: ResolvedConfig
) : FeedItem()

data class SDUIGallery(
    override val id: String,
    val config: ResolvedConfig
) : FeedItem()
