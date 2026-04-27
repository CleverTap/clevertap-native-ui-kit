package com.clevertap.android.nativeui.sample

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.clevertap.android.nativedisplay.renderer.LocalFontFamilyResolver
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

/**
 * FontDemoScreen — demonstrates the three font resolution layers available in NativeDisplayView:
 *
 *   1. No fontFamily param   → system default font (Roboto on Android)
 *   2. fontFamily parameter  → client-provided FontFamily passed directly to NativeDisplayView
 *   3. LocalFontFamilyResolver → CompositionLocal closure that maps JSON fontFamily strings to
 *                               FontFamily instances, enabling per-name font swapping
 *
 * Uses banner-09-premium-subscription.json from assets as the demo config since it contains
 * multiple text elements that visibly illustrate typeface differences.
 */
@Composable
fun FontDemoScreen() {
    val context = LocalContext.current

    // Load the banner config once; all three sections share the same config so differences
    // are purely due to font resolution, not content.
    val config = remember {
        JsonLoader.loadFromAssets(context, "banners/banner-09-premium-subscription.json")
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5)),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {

        // Page header
        item {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Font Customization",
                    style = MaterialTheme.typography.headlineSmall
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Three sections show the same banner rendered with different font " +
                            "resolution layers. Use FontFamily.Serif / Monospace as stand-ins " +
                            "for custom brand fonts.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF666666)
                )
            }
        }

        // ── Section A: System Default ─────────────────────────────────────────────────────────
        item {
            FontDemoSection(
                label = "System Default Font",
                description = "No fontFamily parameter — SDK uses the system default (Roboto)."
            ) {
                if (config != null) {
                    // No fontFamily argument; system default applies
                    NativeDisplayView(
                        config = config,
                        modifier = Modifier.fillMaxWidth()
                    )
                } else {
                    ErrorMessage("Failed to load banner config")
                }
            }
        }

        // ── Section B: Client FontFamily via parameter ────────────────────────────────────────
        item {
            FontDemoSection(
                label = "Client Font — Serif (via parameter)",
                description = "fontFamily = FontFamily.Serif overrides all text rendered by this " +
                        "NativeDisplayView instance. Highest-priority client override."
            ) {
                if (config != null) {
                    // fontFamily parameter: applies FontFamily.Serif to every text element
                    NativeDisplayView(
                        config = config,
                        modifier = Modifier.fillMaxWidth(),
                        fontFamily = FontFamily.Serif
                    )
                } else {
                    ErrorMessage("Failed to load banner config")
                }
            }
        }

        // ── Section C: LocalFontFamilyResolver via CompositionLocal ───────────────────────────
        item {
            FontDemoSection(
                label = "Client Font — Monospace (via CompositionLocal + resolver)",
                description = "LocalFontFamilyResolver maps JSON fontFamily strings to " +
                        "FontFamily instances. 'mono' resolves to Monospace; all other names " +
                        "resolve to Serif. No fontFamily parameter is set here."
            ) {
                if (config != null) {
                    // LocalFontFamilyResolver: closure receives the fontFamily string from JSON
                    // and returns the matching FontFamily, enabling per-name font selection.
                    CompositionLocalProvider(
                        LocalFontFamilyResolver provides { name ->
                            when (name.lowercase()) {
                                "mono" -> FontFamily.Monospace
                                else -> FontFamily.Serif
                            }
                        }
                    ) {
                        NativeDisplayView(
                            config = config,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                } else {
                    ErrorMessage("Failed to load banner config")
                }
            }
        }
    }
}

/**
 * Wraps a demo content block with a titled card and description label.
 */
@Composable
private fun FontDemoSection(
    label: String,
    description: String,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Section label — mirrors the labelLarge style used in other demo screens
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFF888888)
            )
            Spacer(modifier = Modifier.height(12.dp))
            content()
        }
    }
}
