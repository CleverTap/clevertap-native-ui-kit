package com.clevertap.tools

import java.awt.Color
import java.awt.image.BufferedImage
import kotlin.math.*

object Comparators {

    // -----------------------------------------------------------------------
    // Tier 1 — Aspect ratio
    // -----------------------------------------------------------------------

    /**
     * Returns the absolute fractional difference in aspect ratios.
     * e.g. 1080x1920 vs 1080x2340 → |0.5625 - 0.4615| / max(0.5625, 0.4615) ≈ 0.18
     */
    fun aspectRatioDiff(a: BufferedImage, b: BufferedImage): Double {
        val arA = a.width.toDouble() / a.height
        val arB = b.width.toDouble() / b.height
        val maxAr = maxOf(arA, arB)
        return if (maxAr == 0.0) 0.0 else abs(arA - arB) / maxAr
    }

    // -----------------------------------------------------------------------
    // Tier 2 — Color histogram distance (ΔE in histogram space)
    // -----------------------------------------------------------------------

    private const val HIST_BINS = 64   // per channel; 64^3 too large — use per-channel histograms

    /**
     * Computes per-channel (R, G, B) normalised histograms and returns the
     * average Earth-Mover's Distance (L1 cumulative) scaled to [0, 255].
     * A value > 15 suggests meaningfully different backgrounds / palettes.
     */
    fun colorHistogramDistance(a: BufferedImage, b: BufferedImage): Double {
        val histA = buildHistogram(a)
        val histB = buildHistogram(b)

        var totalEmd = 0.0
        for (ch in 0..2) {
            totalEmd += earthMoverDistance(histA[ch], histB[ch])
        }
        return totalEmd / 3.0
    }

    /** Returns 3 normalised histograms [R, G, B] each of length HIST_BINS. */
    private fun buildHistogram(img: BufferedImage): Array<DoubleArray> {
        val hists = Array(3) { DoubleArray(HIST_BINS) }
        val total = img.width.toLong() * img.height
        for (y in 0 until img.height) {
            for (x in 0 until img.width) {
                val rgb = img.getRGB(x, y)
                hists[0][((rgb shr 16) and 0xFF) * HIST_BINS / 256]++
                hists[1][((rgb shr 8) and 0xFF) * HIST_BINS / 256]++
                hists[2][(rgb and 0xFF) * HIST_BINS / 256]++
            }
        }
        // Normalise
        for (ch in 0..2) {
            for (i in hists[ch].indices) hists[ch][i] /= total.toDouble()
        }
        return hists
    }

    /**
     * Earth-Mover's Distance (Wasserstein-1) for two 1-D normalised histograms.
     * Scaled to [0, 255] by multiplying by (255 / HIST_BINS * HIST_BINS) then 255.
     */
    private fun earthMoverDistance(p: DoubleArray, q: DoubleArray): Double {
        var cdf = 0.0
        var emd = 0.0
        for (i in p.indices) {
            cdf += p[i] - q[i]
            emd += abs(cdf)
        }
        // Scale back to ~pixel intensity units
        return emd * 255.0 / HIST_BINS
    }

    // -----------------------------------------------------------------------
    // Tier 3 — Structural SSIM
    // -----------------------------------------------------------------------

    private const val WINDOW_SIZE = 8
    private const val K1 = 0.01
    private const val K2 = 0.03
    private const val L = 255.0

    private val C1 = (K1 * L).pow(2)   // (0.01 * 255)^2 = 6.5025
    private val C2 = (K2 * L).pow(2)   // (0.03 * 255)^2 = 58.5225

    /**
     * Sliding 8×8 window SSIM over grayscale images.
     * Text-heavy rows are down-weighted by 50%.
     * Both images MUST be the same size (use alignImages first).
     * Returns score in [0, 1].
     */
    fun ssim(imgA: BufferedImage, imgB: BufferedImage): Double {
        val grayA = ImageAlignment.toGrayscale(imgA)
        val grayB = ImageAlignment.toGrayscale(imgB)

        val rowWeightsA = ImageAlignment.textRowWeights(grayA)
        val rowWeightsB = ImageAlignment.textRowWeights(grayB)
        // Combined weight = minimum of the two (conservative)
        val rowWeights = DoubleArray(grayA.size) { i -> minOf(rowWeightsA[i], rowWeightsB[i]) }

        val h = grayA.size
        val w = grayA[0].size

        var totalSsim = 0.0
        var totalWeight = 0.0

        var windowY = 0
        while (windowY + WINDOW_SIZE <= h) {
            var windowX = 0
            while (windowX + WINDOW_SIZE <= w) {
                val (ssimVal, windowWeight) = ssimWindow(
                    grayA, grayB, windowX, windowY, WINDOW_SIZE, rowWeights
                )
                totalSsim += ssimVal * windowWeight
                totalWeight += windowWeight
                windowX += WINDOW_SIZE
            }
            windowY += WINDOW_SIZE
        }

        return if (totalWeight == 0.0) 1.0 else totalSsim / totalWeight
    }

    /**
     * Compute SSIM for a single window and return Pair(ssimValue, windowWeight).
     * windowWeight incorporates per-row text masking.
     */
    private fun ssimWindow(
        grayA: Array<DoubleArray>,
        grayB: Array<DoubleArray>,
        x0: Int, y0: Int,
        size: Int,
        rowWeights: DoubleArray,
    ): Pair<Double, Double> {
        var muA = 0.0
        var muB = 0.0
        var weightSum = 0.0

        // Weighted means
        for (dy in 0 until size) {
            val w = rowWeights[y0 + dy]
            for (dx in 0 until size) {
                muA += grayA[y0 + dy][x0 + dx] * w
                muB += grayB[y0 + dy][x0 + dx] * w
                weightSum += w
            }
        }
        if (weightSum == 0.0) return Pair(1.0, 0.0)
        muA /= weightSum
        muB /= weightSum

        var sigmaA2 = 0.0
        var sigmaB2 = 0.0
        var sigmaAB = 0.0

        for (dy in 0 until size) {
            val w = rowWeights[y0 + dy]
            for (dx in 0 until size) {
                val diffA = grayA[y0 + dy][x0 + dx] - muA
                val diffB = grayB[y0 + dy][x0 + dx] - muB
                sigmaA2 += diffA * diffA * w
                sigmaB2 += diffB * diffB * w
                sigmaAB += diffA * diffB * w
            }
        }
        sigmaA2 /= weightSum
        sigmaB2 /= weightSum
        sigmaAB /= weightSum

        val numerator = (2 * muA * muB + C1) * (2 * sigmaAB + C2)
        val denominator = (muA * muA + muB * muB + C1) * (sigmaA2 + sigmaB2 + C2)

        val ssimVal = if (denominator == 0.0) 1.0 else numerator / denominator
        return Pair(ssimVal.coerceIn(0.0, 1.0), weightSum)
    }

    // -----------------------------------------------------------------------
    // Tier 4 — Pixel diff heatmap
    // -----------------------------------------------------------------------

    /**
     * Generate an HSV-coloured heatmap where each pixel's colour maps the
     * absolute grayscale difference: 0 → green (H=120), 128 → yellow (H=60),
     * 255 → red (H=0).  Both images must be the same size.
     */
    fun generateHeatmap(imgA: BufferedImage, imgB: BufferedImage): BufferedImage {
        val w = imgA.width
        val h = imgA.height
        val heatmap = BufferedImage(w, h, BufferedImage.TYPE_INT_RGB)

        val grayA = ImageAlignment.toGrayscale(imgA)
        val grayB = ImageAlignment.toGrayscale(imgB)

        for (y in 0 until h) {
            for (x in 0 until w) {
                val diff = abs(grayA[y][x] - grayB[y][x]).coerceIn(0.0, 255.0)
                // Map diff 0..255 → hue 120..0 (green → yellow → red)
                val hue = (120.0 * (1.0 - diff / 255.0)).toFloat()
                val rgb = Color.HSBtoRGB(hue / 360f, 1f, 1f)
                heatmap.setRGB(x, y, rgb)
            }
        }

        return heatmap
    }
}
