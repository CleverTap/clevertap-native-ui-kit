package com.clevertap.tools

import java.awt.Color
import java.awt.RenderingHints
import java.awt.image.BufferedImage
import java.io.File
import java.util.Base64
import java.io.ByteArrayOutputStream
import javax.imageio.ImageIO

// ---------------------------------------------------------------------------
// Image I/O helpers (used across all files)
// ---------------------------------------------------------------------------

fun loadImage(file: File): BufferedImage? {
    return try {
        val raw = ImageIO.read(file) ?: return null
        // Normalise to TYPE_INT_RGB — all callers expect this
        if (raw.type == BufferedImage.TYPE_INT_RGB) raw
        else {
            val out = BufferedImage(raw.width, raw.height, BufferedImage.TYPE_INT_RGB)
            val g = out.createGraphics()
            g.color = Color.BLACK
            g.fillRect(0, 0, raw.width, raw.height)
            g.drawImage(raw, 0, 0, null)
            g.dispose()
            out
        }
    } catch (e: Exception) {
        System.err.println("Failed to load image ${file.name}: ${e.message}")
        null
    }
}

fun saveImage(img: BufferedImage, file: File) {
    file.parentFile?.mkdirs()
    ImageIO.write(img, "png", file)
}

fun imageToBase64(file: File): String {
    val bytes = file.readBytes()
    return Base64.getEncoder().encodeToString(bytes)
}

fun bufferedImageToBase64(img: BufferedImage): String {
    val baos = ByteArrayOutputStream()
    ImageIO.write(img, "png", baos)
    return Base64.getEncoder().encodeToString(baos.toByteArray())
}

// ---------------------------------------------------------------------------
// ImageAlignment
// ---------------------------------------------------------------------------

object ImageAlignment {

    /**
     * Resize both images to max(widthA, widthB) x max(heightA, heightB)
     * with aspect-preserved letterboxing (black bars).
     * Returns a Pair(alignedA, alignedB).
     */
    fun alignImages(
        imgA: BufferedImage,
        imgB: BufferedImage,
    ): Pair<BufferedImage, BufferedImage> {
        val targetW = maxOf(imgA.width, imgB.width)
        val targetH = maxOf(imgA.height, imgB.height)
        return Pair(
            letterbox(imgA, targetW, targetH),
            letterbox(imgB, targetW, targetH),
        )
    }

    /**
     * Scale [src] to fit within [targetW] x [targetH] while preserving aspect
     * ratio.  Pad remaining space with black bars (letterbox / pillarbox).
     */
    fun letterbox(src: BufferedImage, targetW: Int, targetH: Int): BufferedImage {
        val canvas = BufferedImage(targetW, targetH, BufferedImage.TYPE_INT_RGB)
        val g = canvas.createGraphics()
        g.color = Color.BLACK
        g.fillRect(0, 0, targetW, targetH)

        // Compute scaled dimensions preserving aspect
        val scaleX = targetW.toDouble() / src.width
        val scaleY = targetH.toDouble() / src.height
        val scale = minOf(scaleX, scaleY)

        val scaledW = (src.width * scale).toInt()
        val scaledH = (src.height * scale).toInt()

        val offsetX = (targetW - scaledW) / 2
        val offsetY = (targetH - scaledH) / 2

        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR)
        g.drawImage(src, offsetX, offsetY, scaledW, scaledH, null)
        g.dispose()

        return canvas
    }

    /**
     * Convert a TYPE_INT_RGB BufferedImage to a grayscale (luminance) 2-D
     * double array [row][col] with values in [0, 255].
     */
    fun toGrayscale(img: BufferedImage): Array<DoubleArray> {
        val w = img.width
        val h = img.height
        val gray = Array(h) { DoubleArray(w) }
        for (y in 0 until h) {
            for (x in 0 until w) {
                val rgb = img.getRGB(x, y)
                val r = (rgb shr 16) and 0xFF
                val g = (rgb shr 8) and 0xFF
                val b = rgb and 0xFF
                // BT.601 luminance
                gray[y][x] = 0.299 * r + 0.587 * g + 0.114 * b
            }
        }
        return gray
    }

    /**
     * Detect text-heavy rows using Sobel horizontal-edge density.
     * Returns a DoubleArray of length [h] where 1.0 = plain and 0.5 = text-heavy.
     * Text rows are down-weighted by 50% in the SSIM window average.
     */
    fun textRowWeights(gray: Array<DoubleArray>): DoubleArray {
        val h = gray.size
        val w = gray[0].size
        val weights = DoubleArray(h) { 1.0 }

        for (y in 1 until h - 1) {
            var edgeSum = 0.0
            for (x in 1 until w - 1) {
                // Sobel Y kernel — detects horizontal edges (typical for text baselines)
                val gy = (gray[y - 1][x - 1] + 2 * gray[y - 1][x] + gray[y - 1][x + 1]
                        - gray[y + 1][x - 1] - 2 * gray[y + 1][x] - gray[y + 1][x + 1])
                // Sobel X kernel — detects vertical edges (letter strokes)
                val gx = (gray[y - 1][x + 1] + 2 * gray[y][x + 1] + gray[y + 1][x + 1]
                        - gray[y - 1][x - 1] - 2 * gray[y][x - 1] - gray[y + 1][x - 1])
                edgeSum += Math.sqrt(gx * gx + gy * gy)
            }
            // Normalise edge density to [0, 1]
            val edgeDensity = edgeSum / ((w - 2) * 362.0) // 362 ≈ max gradient magnitude
            // High edge density + medium luminance variance → likely text row
            if (edgeDensity > 0.15) {
                weights[y] = 0.5
            }
        }
        return weights
    }
}
