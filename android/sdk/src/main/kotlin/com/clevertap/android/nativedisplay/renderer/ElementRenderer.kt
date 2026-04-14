package com.clevertap.android.nativedisplay.renderer

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.internal.ImageLoaderProvider
import com.clevertap.android.nativedisplay.models.DividerConfig
import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.HtmlConfig
import com.clevertap.android.nativedisplay.models.ImageFit
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import com.clevertap.android.nativedisplay.models.Orientation
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.models.TextDimensionUnit
import com.clevertap.android.nativedisplay.models.TextProperties

/**
 * Render an element based on its type.
 */
@Composable
internal fun RenderElement(
    element: NativeDisplayElement,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null,
    rootHeightPx: Float = 0f,
) {
    val elementModifier = modifier.applyPadding(element.layout)

    when (element.elementType) {
        ElementType.TEXT -> {
            val text = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            val textProps: TextProperties = resolvedStyle.extractTextProperties()
            val isPercentMode = textProps.size?.unit == TextDimensionUnit.PERCENT
            val resolvedFontSize = textProps.size?.resolve(rootHeightPx) ?: 14f
            val fontFamily = resolveEffectiveFontFamily(textProps.family)
            // In percentage mode: all values are in px, convert via toSp() at use site
            // In platform mode: values are already in sp-compatible units, use .sp
            if (isPercentMode) {
                // Default lineHeight = fontSize * 1.2 matches CSS line-height:normal (~1.2×)
                val resolvedLineHeightPx = textProps.lineHeight?.resolve(rootHeightPx) ?: (resolvedFontSize * 1.2f)
                Text(
                    text = text,
                    modifier = elementModifier,
                    color = parseColor(textProps.color) ?: Color.Black,
                    fontSize = with(LocalDensity.current) { resolvedFontSize.toSp() },
                    fontWeight = resolveFontWeight(textProps.weight),
                    fontFamily = fontFamily,
                    fontStyle = resolveFontStyle(textProps.style),
                    letterSpacing = 0.sp,
                    textDecoration = resolveTextDecoration(textProps.decoration),
                    textAlign = resolveTextAlign(textProps.align),
                    lineHeight = with(LocalDensity.current) { resolvedLineHeightPx.toSp() },
                    maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                    overflow = resolveTextOverflow(textProps.overflow),
                    style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
                )
            } else {
                Text(
                    text = text,
                    modifier = elementModifier,
                    color = parseColor(textProps.color) ?: Color.Black,
                    fontSize = resolvedFontSize.sp,
                    fontWeight = resolveFontWeight(textProps.weight),
                    fontFamily = fontFamily,
                    fontStyle = resolveFontStyle(textProps.style),
                    letterSpacing = (textProps.letterSpacing ?: 0f).sp,
                    textDecoration = resolveTextDecoration(textProps.decoration),
                    textAlign = resolveTextAlign(textProps.align),
                    lineHeight = textProps.lineHeight?.resolve(rootHeightPx)?.sp ?: (resolvedFontSize * 1.5f).sp,
                    maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                    overflow = resolveTextOverflow(textProps.overflow),
                    style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
                )
            }
        }

        ElementType.IMAGE -> {
            val imageUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            if (imageUrl.isNotEmpty()) {
                val context = LocalContext.current

                // Remember the ImageLoader to avoid creating it on every recomposition
                // The ImageLoaderProvider is a singleton, but we cache the reference here
                val imageLoaderFactory = LocalImageLoader.current
                val imageLoader = remember(context, imageLoaderFactory) {
                    imageLoaderFactory?.invoke(context) ?: ImageLoaderProvider.getImageLoader(context)
                }

                // Map ImageFit to ContentScale
                val contentScale = when (element.imageConfig?.fit ?: ImageFit.CROP) {
                    ImageFit.CROP -> ContentScale.Crop        // Fill, may crop edges
                    ImageFit.CONTAIN -> ContentScale.Fit      // Fit within bounds
                    ImageFit.FILL -> ContentScale.FillBounds  // Stretch to fill
                    ImageFit.TILE -> ContentScale.Crop        // Tile not supported for single images
                }

                // Use SDK's internal ImageLoader with GIF support
                // This ensures GIF animation works without requiring host app configuration
                val imageRequest = ImageRequest.Builder(context)
                    .data(imageUrl)
                    .crossfade(true)
                    .build()

                AsyncImage(
                    model = imageRequest,
                    imageLoader = imageLoader,
                    contentDescription = element.bindings["contentDescription"]?.let {
                        evaluator.evaluateString(it)
                    },
                    modifier = elementModifier,
                    contentScale = contentScale
                )
            } else {
                Box(
                    modifier = elementModifier.background(Color.LightGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No Image", color = Color.Gray, fontSize = 12.sp)
                }
            }
        }

        ElementType.BUTTON -> {
            val buttonText = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: "Button"
            val textProps = resolvedStyle.extractTextProperties()
            val isPercentMode = textProps.size?.unit == TextDimensionUnit.PERCENT
            val resolvedFontSize = textProps.size?.resolve(rootHeightPx) ?: 16f
            val fontFamily = resolveEffectiveFontFamily(textProps.family)

            Box(
                modifier = elementModifier,
                contentAlignment = Alignment.Center
            ) {
                if (isPercentMode) {
                    val resolvedLineHeightPx = textProps.lineHeight?.resolve(rootHeightPx) ?: (resolvedFontSize * 1.2f)
                    Text(
                        text = buttonText,
                        color = parseColor(textProps.color) ?: Color.White,
                        fontSize = with(LocalDensity.current) { resolvedFontSize.toSp() },
                        fontWeight = resolveFontWeight(textProps.weight),
                        fontFamily = fontFamily,
                        fontStyle = resolveFontStyle(textProps.style),
                        letterSpacing = 0.sp,
                        textDecoration = resolveTextDecoration(textProps.decoration),
                        textAlign = resolveTextAlign(textProps.align),
                        lineHeight = with(LocalDensity.current) { resolvedLineHeightPx.toSp() },
                        maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                        overflow = resolveTextOverflow(textProps.overflow),
                        style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
                    )
                } else {
                    Text(
                        text = buttonText,
                        color = parseColor(textProps.color) ?: Color.White,
                        fontSize = resolvedFontSize.sp,
                        fontWeight = resolveFontWeight(textProps.weight),
                        fontFamily = fontFamily,
                        fontStyle = resolveFontStyle(textProps.style),
                        letterSpacing = (textProps.letterSpacing ?: 0f).sp,
                        textDecoration = resolveTextDecoration(textProps.decoration),
                        textAlign = resolveTextAlign(textProps.align),
                        lineHeight = textProps.lineHeight?.resolve(rootHeightPx)?.sp ?: (resolvedFontSize * 1.5f).sp,
                        maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                        overflow = resolveTextOverflow(textProps.overflow),
                        style = TextStyle(platformStyle = PlatformTextStyle(includeFontPadding = false))
                    )
                }
            }
        }

        ElementType.VIDEO -> {
            val videoUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            val autoPlay = element.bindings["autoPlay"]?.let {
                evaluator.evaluateBoolean(it)
            } ?: false

            val loop = element.bindings["loop"]?.let {
                evaluator.evaluateBoolean(it)
            } ?: false

            val muted = element.bindings["muted"]?.let {
                evaluator.evaluateBoolean(it)
            } ?: false

            val showControls = element.bindings["showControls"]?.let {
                evaluator.evaluateBoolean(it)
            } ?: true

            val showFullscreen = element.bindings["showFullscreen"]?.let {
                evaluator.evaluateBoolean(it)
            } ?: true

            if (videoUrl.isNotEmpty()) {
                val videoFactory = LocalVideoPlayerFactory.current
                if (videoFactory != null) {
                    videoFactory(videoUrl, autoPlay, loop, muted, showControls, showFullscreen, elementModifier)
                } else {
                    VideoPlayer(
                        videoUrl = videoUrl,
                        autoPlay = autoPlay,
                        loop = loop,
                        muted = muted,
                        showControls = showControls,
                        showFullscreen = showFullscreen,
                        modifier = elementModifier
                    )
                }
            } else {
                // Fallback for missing URL
                Box(
                    modifier = elementModifier.background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No Video URL", color = Color.Gray, fontSize = 12.sp)
                }
            }
        }

        ElementType.HTML -> {
            val html = element.bindings["html"]?.let {
                evaluator.evaluateString(it)
            }
            val url = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            }
            val config = element.htmlConfig ?: HtmlConfig()

            if (!html.isNullOrEmpty() || !url.isNullOrEmpty()) {
                val htmlFactory = LocalHtmlViewFactory.current
                if (htmlFactory != null) {
                    htmlFactory(html, url, config, elementModifier)
                } else {
                    HtmlElementView(
                        html = html,
                        url = url,
                        config = config,
                        modifier = elementModifier
                    )
                }
            } else {
                Box(
                    modifier = elementModifier.background(Color.LightGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No HTML Content", color = Color.Gray, fontSize = 12.sp)
                }
            }
        }

        ElementType.SPACER -> {
            Spacer(modifier = elementModifier)
        }

        ElementType.DIVIDER -> {
            val dividerConfig = element.dividerConfig ?: DividerConfig()
            val dividerColor = parseColor(dividerConfig.color) ?: Color.LightGray

            when (dividerConfig.orientation) {
                Orientation.HORIZONTAL -> {
                    HorizontalDivider(
                        modifier = elementModifier,
                        thickness = dividerConfig.thickness.dp,
                        color = dividerColor
                    )
                }
                Orientation.VERTICAL -> {
                    VerticalDivider(
                        modifier = elementModifier,
                        thickness = dividerConfig.thickness.dp,
                        color = dividerColor
                    )
                }
            }
        }
    }
}
