package com.clevertap.android.nativedisplay.renderer

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
import com.clevertap.android.nativedisplay.internal.NDLogger
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
            RenderTextContent(
                text = text,
                textProps = resolvedStyle.extractTextProperties(),
                rootHeightPx = rootHeightPx,
                modifier = elementModifier,
                defaultColor = Color.Black,
                defaultFontSize = 14f,
            )
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
                NDLogger.w("NDElementRenderer", "IMAGE element '${element.id}' has no url binding — skipping render")
            }
        }

        ElementType.BUTTON -> {
            val buttonText = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: "Button"
            Box(
                modifier = elementModifier,
                contentAlignment = Alignment.Center
            ) {
                RenderTextContent(
                    text = buttonText,
                    textProps = resolvedStyle.extractTextProperties(),
                    rootHeightPx = rootHeightPx,
                    defaultColor = Color.White,
                    defaultFontSize = 16f,
                )
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

            val openUrl = element.bindings["openUrl"]?.let {
                evaluator.evaluateString(it)
            }?.takeIf { it.isNotEmpty() }

            if (videoUrl.isNotEmpty()) {
                val videoFactory = LocalVideoPlayerFactory.current
                if (videoFactory != null) {
                    videoFactory(videoUrl, autoPlay, loop, muted, showControls, showFullscreen, openUrl, elementModifier)
                } else {
                    VideoPlayer(
                        videoUrl = videoUrl,
                        autoPlay = autoPlay,
                        loop = loop,
                        muted = muted,
                        showControls = showControls,
                        showFullscreen = showFullscreen,
                        openUrl = openUrl,
                        modifier = elementModifier
                    )
                }
            } else {
                NDLogger.w("NDElementRenderer", "VIDEO element '${element.id}' has no url binding — skipping render")
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
                NDLogger.w("NDElementRenderer", "HTML element '${element.id}' has no html/url binding — skipping render")
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

/**
 * Shared text rendering for TEXT and BUTTON elements.
 *
 * Handles both percent mode (font sizes in px, converted via [LocalDensity]) and
 * platform mode (font sizes already in sp-compatible units). In percent mode the
 * default line-height is 1.2× font size (CSS normal); in platform mode it is 1.5×.
 */
@Composable
private fun RenderTextContent(
    text: String,
    textProps: TextProperties,
    rootHeightPx: Float,
    modifier: Modifier = Modifier,
    defaultColor: Color = Color.Black,
    defaultFontSize: Float = 14f,
) {
    val isPercentMode = textProps.size?.unit == TextDimensionUnit.PERCENT
    val resolvedFontSize = textProps.size?.resolve(rootHeightPx) ?: defaultFontSize
    val fontFamily = resolveEffectiveFontFamily(textProps.family)

    if (isPercentMode) {
        val resolvedLineHeightPx = textProps.lineHeight?.resolve(rootHeightPx) ?: (resolvedFontSize * 1.2f)
        Text(
            text = text,
            modifier = modifier,
            color = parseColor(textProps.color) ?: defaultColor,
            fontSize = with(LocalDensity.current) { resolvedFontSize.toSp() },
            fontWeight = resolveFontWeight(textProps.weight),
            fontFamily = fontFamily,
            fontStyle = resolveFontStyle(textProps.style),
            letterSpacing = (textProps.letterSpacing ?: 0f).sp,
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
            modifier = modifier,
            color = parseColor(textProps.color) ?: defaultColor,
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
