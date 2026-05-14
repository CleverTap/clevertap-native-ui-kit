package com.clevertap.android.nativedisplay.renderer

import androidx.compose.animation.core.EaseInBack
import androidx.compose.animation.core.EaseOutBack
import androidx.compose.animation.core.FastOutLinearInEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.models.ArrangementStrategy
import com.clevertap.android.nativedisplay.models.ChildArrangement
import com.clevertap.android.nativedisplay.models.DimensionUnit
import com.clevertap.android.nativedisplay.models.Easing
import com.clevertap.android.nativedisplay.models.FontWeight
import androidx.compose.ui.text.font.FontStyle as ComposeFontStyle
import androidx.compose.ui.text.font.FontWeight as ComposeFontWeight
import androidx.compose.ui.text.style.TextOverflow as ComposeTextOverflow

/**
 * Parse hex color string to Compose Color.
 */
internal fun parseColor(colorString: String?): Color? {
    if (colorString == null) return null

    return try {
        val hex = colorString.removePrefix("#")
        when (hex.length) {
            6 -> {
                val rgb = hex.toLong(16)
                Color(
                    red = ((rgb shr 16) and 0xFF) / 255f,
                    green = ((rgb shr 8) and 0xFF) / 255f,
                    blue = (rgb and 0xFF) / 255f,
                    alpha = 1f
                )
            }
            8 -> {
                // Server sends RGBA format (#RRGGBBAA), convert to Compose Color
                val rgba = hex.toLong(16)
                Color(
                    red = ((rgba shr 24) and 0xFF) / 255f,
                    green = ((rgba shr 16) and 0xFF) / 255f,
                    blue = ((rgba shr 8) and 0xFF) / 255f,
                    alpha = (rgba and 0xFF) / 255f
                )
            }
            else -> null
        }
    } catch (_: Exception) {
        null
    }
}

/**
 * Resolve font weight from model to Compose.
 */
internal fun resolveFontWeight(fontWeight: FontWeight?): ComposeFontWeight {
    return when (fontWeight) {
        FontWeight.LIGHT -> ComposeFontWeight.Light
        FontWeight.NORMAL -> ComposeFontWeight.Normal
        FontWeight.MEDIUM -> ComposeFontWeight.Medium
        FontWeight.BOLD -> ComposeFontWeight.Bold
        null -> ComposeFontWeight.Normal
    }
}

/**
 * Resolve font style from model to Compose.
 */
internal fun resolveFontStyle(fontStyle: com.clevertap.android.nativedisplay.models.FontStyle?): ComposeFontStyle {
    return when (fontStyle) {
        com.clevertap.android.nativedisplay.models.FontStyle.ITALIC -> ComposeFontStyle.Italic
        com.clevertap.android.nativedisplay.models.FontStyle.NORMAL, null -> ComposeFontStyle.Normal
    }
}

internal typealias ndtd = com.clevertap.android.nativedisplay.models.TextDecoration

/**
 * Resolve text decoration from model to Compose.
 */
internal fun resolveTextDecoration(decoration: ndtd?): TextDecoration {
    return when (decoration) {
        ndtd.UNDERLINE -> TextDecoration.Underline
        ndtd.STRIKETHROUGH -> TextDecoration.LineThrough
        ndtd.NONE, null -> TextDecoration.None
    }
}

/**
 * Resolve text alignment from string to Compose.
 */
internal fun resolveTextAlign(align: String?): TextAlign {
    return when (align?.lowercase()) {
        "left" -> TextAlign.Left
        "center" -> TextAlign.Center
        "right" -> TextAlign.Right
        "justify" -> TextAlign.Justify
        else -> TextAlign.Start
    }
}

/**
 * Resolve text overflow from model to Compose.
 */
internal fun resolveTextOverflow(overflow: com.clevertap.android.nativedisplay.models.TextOverflow?): ComposeTextOverflow {
    return when (overflow) {
        com.clevertap.android.nativedisplay.models.TextOverflow.CLIP -> ComposeTextOverflow.Clip
        com.clevertap.android.nativedisplay.models.TextOverflow.ELLIPSIS -> ComposeTextOverflow.Ellipsis
        com.clevertap.android.nativedisplay.models.TextOverflow.VISIBLE -> ComposeTextOverflow.Visible
        null -> ComposeTextOverflow.Clip
    }
}

/**
 * Resolve horizontal arrangement strategy for Row containers.
 * Maps ArrangementStrategy enum to Compose Arrangement.Horizontal.
 */
internal fun resolveHorizontalArrangement(arrangement: ChildArrangement?): Arrangement.Horizontal {
    if (arrangement == null) {
        return Arrangement.spacedBy(0.dp)
    }

    return when (arrangement.strategy) {
        ArrangementStrategy.SPACED -> {
            val spacing = arrangement.spacing ?: 0f
            when (arrangement.spacingUnit) {
                DimensionUnit.DP -> Arrangement.spacedBy(spacing.dp)
                else -> Arrangement.spacedBy(spacing.dp) // Default to DP for other units
            }
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Start
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.End
    }
}

/**
 * Resolve vertical arrangement strategy for Column containers.
 * Maps ArrangementStrategy enum to Compose Arrangement.Vertical.
 */
internal fun resolveVerticalArrangement(arrangement: ChildArrangement?): Arrangement.Vertical {
    if (arrangement == null) {
        return Arrangement.spacedBy(0.dp)
    }

    return when (arrangement.strategy) {
        ArrangementStrategy.SPACED -> {
            val spacing = arrangement.spacing ?: 0f
            when (arrangement.spacingUnit) {
                DimensionUnit.DP -> Arrangement.spacedBy(spacing.dp)
                else -> Arrangement.spacedBy(spacing.dp) // Default to DP for other units
            }
        }
        ArrangementStrategy.SPACE_BETWEEN -> Arrangement.SpaceBetween
        ArrangementStrategy.SPACE_EVENLY -> Arrangement.SpaceEvenly
        ArrangementStrategy.SPACE_AROUND -> Arrangement.SpaceAround
        ArrangementStrategy.START -> Arrangement.Top
        ArrangementStrategy.CENTER -> Arrangement.Center
        ArrangementStrategy.END -> Arrangement.Bottom
    }
}

/**
 * Resolve easing enum to Compose easing function.
 */
internal fun resolveEasing(easing: Easing): androidx.compose.animation.core.Easing {
    return when (easing) {
        Easing.LINEAR -> LinearEasing
        Easing.EASE_IN -> FastOutLinearInEasing
        Easing.EASE_OUT -> LinearOutSlowInEasing
        Easing.EASE_IN_OUT -> FastOutSlowInEasing
        Easing.EASE_IN_BACK -> EaseInBack
        Easing.EASE_OUT_BACK -> EaseOutBack
        Easing.SPRING -> LinearEasing  // Spring handled differently
    }
}

/**
 * Resolve the effective FontFamily using a 3-layer priority system:
 * 1. Client-provided default (LocalFontFamily) — HIGHEST priority
 * 2. JSON fontFamily resolved via client resolver (LocalFontFamilyResolver)
 * 3. System default (null) — LOWEST priority
 */
@Composable
internal fun resolveEffectiveFontFamily(jsonFontFamily: String?): FontFamily? {
    val clientDefault = LocalFontFamily.current
    val clientResolver = LocalFontFamilyResolver.current

    // Layer 1: Client-provided default (HIGHEST)
    if (clientDefault != null) return clientDefault

    // Layer 2: JSON fontFamily
    if (jsonFontFamily != null) {
        val resolved = clientResolver?.invoke(jsonFontFamily)
        if (resolved != null) return resolved
    }

    // Layer 3: System default
    return null
}
