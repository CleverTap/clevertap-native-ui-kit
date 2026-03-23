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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.clevertap.android.nativedisplay.evaluator.VariableEvaluator
import com.clevertap.android.nativedisplay.handler.ActionHandler
import com.clevertap.android.nativedisplay.internal.ImageLoaderProvider
import com.clevertap.android.nativedisplay.models.DividerConfig
import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.ImageFit
import com.clevertap.android.nativedisplay.models.Layout
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import com.clevertap.android.nativedisplay.models.Orientation
import com.clevertap.android.nativedisplay.models.Style

/**
 * Render an element based on its type.
 */
@Composable
internal fun RenderElement(
    element: NativeDisplayElement,
    evaluator: VariableEvaluator,
    resolvedStyle: Style,
    layout: Layout?,
    modifier: Modifier = Modifier,
    actionHandler: ActionHandler? = null
) {
    val elementModifier = modifier.applyPadding(layout)

    when (element.elementType) {
        ElementType.TEXT -> {
            val text = element.bindings["text"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            val textProps = resolvedStyle.extractTextProperties()
            Text(
                text = text,
                modifier = elementModifier,
                color = parseColor(textProps.color) ?: Color.Black,
                fontSize = (textProps.size ?: 14f).sp,
                fontWeight = resolveFontWeight(textProps.weight),
                fontStyle = resolveFontStyle(textProps.style),
                letterSpacing = (textProps.letterSpacing ?: 0f).sp,
                textDecoration = resolveTextDecoration(textProps.decoration),
                textAlign = resolveTextAlign(textProps.align),
                lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp,
                maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                overflow = resolveTextOverflow(textProps.overflow)
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

            Box(
                modifier = elementModifier,
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = buttonText,
                    color = parseColor(textProps.color) ?: Color.White,
                    fontSize = (textProps.size ?: 16f).sp,
                    fontWeight = resolveFontWeight(textProps.weight),
                    fontStyle = resolveFontStyle(textProps.style),
                    letterSpacing = (textProps.letterSpacing ?: 0f).sp,
                    textDecoration = resolveTextDecoration(textProps.decoration),
                    textAlign = resolveTextAlign(textProps.align),
                    lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp,
                    maxLines = textProps.maxLines ?: Int.MAX_VALUE,
                    overflow = resolveTextOverflow(textProps.overflow)
                )
            }
        }

        ElementType.VIDEO -> {
            val videoUrl = element.bindings["url"]?.let {
                evaluator.evaluateString(it)
            } ?: ""

            val autoPlay = element.bindings["autoPlay"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val loop = element.bindings["loop"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val muted = element.bindings["muted"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: false

            val showControls = element.bindings["showControls"]?.let {
                evaluator.evaluateString(it).toBoolean()
            } ?: true

            val showFullscreen = element.bindings["showFullscreen"]?.let {
                evaluator.evaluateString(it).toBoolean()
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
