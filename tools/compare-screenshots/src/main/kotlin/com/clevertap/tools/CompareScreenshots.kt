package com.clevertap.tools

import java.io.File

// ---------------------------------------------------------------------------
// Video config stems that skip Tier 3 + 4
// ---------------------------------------------------------------------------
val VIDEO_SKIP_STEMS = setOf(
    "test-054",
    "test-136",
    "test-137",
    "test-138",
    "test-151",
)

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------
data class ComparisonResult(
    val config: String,
    val status: Status,
    val reason: String = "",
    val aspectRatioDiff: Double = 0.0,
    val colorDistance: Double = 0.0,
    val ssim: Double = 0.0,
    val diffImageBase64: String? = null,
    val diffImagePath: String? = null,
)

enum class Status { PASS, WARN, FAIL, SKIP_VIDEO, MISSING }

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
fun main(args: Array<String>) {
    if (args.size < 3) {
        System.err.println("Usage: CompareScreenshots <iosDir> <androidDir> <outputDir>")
        return
    }

    val iosDir = File(args[0])
    val androidDir = File(args[1])
    val outputDir = File(args[2])
    val diffsDir = File(outputDir, "diffs")

    outputDir.mkdirs()
    diffsDir.mkdirs()

    // Discover all config stems from both dirs combined
    val stems = discoverStems(iosDir, androidDir)

    println("Found ${stems.size} unique config stems to compare.")

    val results = mutableListOf<ComparisonResult>()

    stems.forEachIndexed { index, stem ->
        println("Comparing ${index + 1}/${stems.size}: $stem")

        val iosFile = findFile(iosDir, stem)
        val androidFile = findFile(androidDir, stem)

        if (iosFile == null || androidFile == null) {
            val missing = buildList {
                if (iosFile == null) add("iOS")
                if (androidFile == null) add("Android")
            }.joinToString(", ")
            println("  -> MISSING ($missing)")
            results += ComparisonResult(
                config = stem,
                status = Status.MISSING,
                reason = "missing: $missing",
            )
            return@forEachIndexed
        }

        val result = compareScreenshots(stem, iosFile, androidFile, diffsDir)
        println("  -> ${result.status}${if (result.reason.isNotEmpty()) " (${result.reason})" else ""}")
        results += result
    }

    println("\nGenerating report...")
    ReportGenerator.generate(results, outputDir)

    val counts = results.groupingBy { it.status }.eachCount()
    println("\n=== Summary ===")
    println("  Total   : ${results.size}")
    println("  PASS    : ${counts[Status.PASS] ?: 0}")
    println("  WARN    : ${counts[Status.WARN] ?: 0}")
    println("  FAIL    : ${counts[Status.FAIL] ?: 0}")
    println("  SKIP    : ${counts[Status.SKIP_VIDEO] ?: 0}")
    println("  MISSING : ${counts[Status.MISSING] ?: 0}")
    println("\nReport written to: ${outputDir.canonicalPath}/report.html")
}

// ---------------------------------------------------------------------------
// File discovery
// ---------------------------------------------------------------------------

private fun discoverStems(iosDir: File, androidDir: File): List<String> {
    val stems = linkedSetOf<String>()
    listOf(iosDir, androidDir).forEach { dir ->
        if (dir.exists()) {
            dir.listFiles()
                ?.filter { it.isFile && it.extension.equals("png", ignoreCase = true) }
                ?.mapTo(stems) { it.nameWithoutExtension }
        }
    }
    return stems.sorted()
}

private fun findFile(dir: File, stem: String): File? {
    if (!dir.exists()) return null
    return File(dir, "$stem.png").takeIf { it.isFile }
        ?: dir.listFiles()?.firstOrNull {
            it.isFile && it.nameWithoutExtension.equals(stem, ignoreCase = true)
                && it.extension.equals("png", ignoreCase = true)
        }
}

// ---------------------------------------------------------------------------
// Comparison pipeline
// ---------------------------------------------------------------------------

private fun compareScreenshots(
    stem: String,
    iosFile: File,
    androidFile: File,
    diffsDir: File,
): ComparisonResult {
    val isVideoConfig = VIDEO_SKIP_STEMS.any { stem.startsWith(it) }

    val iosImg = loadImage(iosFile) ?: return ComparisonResult(
        config = stem, status = Status.MISSING, reason = "could not load iOS image"
    )
    val androidImg = loadImage(androidFile) ?: return ComparisonResult(
        config = stem, status = Status.MISSING, reason = "could not load Android image"
    )

    // --- Tier 1: Aspect ratio ---
    val aspectDiff = Comparators.aspectRatioDiff(iosImg, androidImg)
    val tier1Warn = aspectDiff > 0.20

    // --- Tier 2: Color histogram distance ---
    val colorDist = Comparators.colorHistogramDistance(iosImg, androidImg)
    val tier2Warn = colorDist > 15.0

    val warnReasons = buildList {
        if (tier1Warn) add("aspect_ratio")
        if (tier2Warn) add("color_distance")
    }

    if (isVideoConfig) {
        val videoStatus = if (warnReasons.isNotEmpty()) Status.WARN else Status.SKIP_VIDEO
        return ComparisonResult(
            config = stem,
            status = videoStatus,
            reason = if (warnReasons.isNotEmpty()) warnReasons.joinToString(",") else "video_config",
            aspectRatioDiff = aspectDiff,
            colorDistance = colorDist,
            ssim = 0.0,
        )
    }

    // --- Tier 3: SSIM ---
    val (iosAligned, androidAligned) = ImageAlignment.alignImages(iosImg, androidImg)
    val ssimScore = Comparators.ssim(iosAligned, androidAligned)
    val tier3Fail = ssimScore < 0.85

    if (!tier3Fail) {
        val status = if (warnReasons.isNotEmpty()) Status.WARN else Status.PASS
        return ComparisonResult(
            config = stem,
            status = status,
            reason = warnReasons.joinToString(","),
            aspectRatioDiff = aspectDiff,
            colorDistance = colorDist,
            ssim = ssimScore,
        )
    }

    // --- Tier 4: Pixel diff heatmap (only on FAIL) ---
    val diffImg = Comparators.generateHeatmap(iosAligned, androidAligned)
    val diffFile = File(diffsDir, "$stem-diff.png")
    saveImage(diffImg, diffFile)
    val diffBase64 = imageToBase64(diffFile)

    val failReasons = (warnReasons + listOf("ssim")).distinct()

    return ComparisonResult(
        config = stem,
        status = Status.FAIL,
        reason = failReasons.joinToString(","),
        aspectRatioDiff = aspectDiff,
        colorDistance = colorDist,
        ssim = ssimScore,
        diffImageBase64 = diffBase64,
        diffImagePath = diffFile.canonicalPath,
    )
}
