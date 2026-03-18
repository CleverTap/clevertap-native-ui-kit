package com.clevertap.tools

import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

object ReportGenerator {

    fun generate(results: List<ComparisonResult>, outputDir: File) {
        outputDir.mkdirs()
        writeJson(results, File(outputDir, "summary.json"))
        writeHtml(results, File(outputDir, "report.html"))
    }

    // -----------------------------------------------------------------------
    // JSON
    // -----------------------------------------------------------------------

    private fun writeJson(results: List<ComparisonResult>, file: File) {
        val counts = results.groupingBy { it.status }.eachCount()

        val sb = StringBuilder()
        sb.appendLine("{")
        sb.appendLine("  \"total\": ${results.size},")
        sb.appendLine("  \"pass\": ${counts[Status.PASS] ?: 0},")
        sb.appendLine("  \"warn\": ${counts[Status.WARN] ?: 0},")
        sb.appendLine("  \"fail\": ${counts[Status.FAIL] ?: 0},")
        sb.appendLine("  \"skip\": ${counts[Status.SKIP_VIDEO] ?: 0},")
        sb.appendLine("  \"missing\": ${counts[Status.MISSING] ?: 0},")
        sb.appendLine("  \"results\": [")

        results.forEachIndexed { i, r ->
            sb.append("    {")
            sb.append("\"config\": ${jsonStr(r.config)}, ")
            sb.append("\"status\": ${jsonStr(r.status.name)}, ")
            sb.append("\"reason\": ${jsonStr(r.reason)}, ")
            sb.append("\"aspect_ratio_diff\": ${r.aspectRatioDiff.fmt4()}, ")
            sb.append("\"color_distance\": ${r.colorDistance.fmt4()}, ")
            sb.append("\"ssim\": ${r.ssim.fmt4()}")
            if (r.diffImagePath != null) {
                sb.append(", \"diff_image\": ${jsonStr(r.diffImagePath)}")
            }
            sb.append("}")
            if (i < results.lastIndex) sb.append(",")
            sb.appendLine()
        }

        sb.appendLine("  ]")
        sb.append("}")

        file.writeText(sb.toString())
    }

    private fun jsonStr(s: String): String = "\"${s.replace("\\", "\\\\").replace("\"", "\\\"")}\""
    private fun Double.fmt4(): String = "%.4f".format(this)

    // -----------------------------------------------------------------------
    // HTML
    // -----------------------------------------------------------------------

    private fun writeHtml(results: List<ComparisonResult>, file: File) {
        val counts = results.groupingBy { it.status }.eachCount()
        val total = results.size
        val pass = counts[Status.PASS] ?: 0
        val warn = counts[Status.WARN] ?: 0
        val fail = counts[Status.FAIL] ?: 0
        val skip = counts[Status.SKIP_VIDEO] ?: 0
        val missing = counts[Status.MISSING] ?: 0

        val generatedAt = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))

        val rowsHtml = results.joinToString("\n") { r -> buildRow(r) }

        // JS snippets are assembled separately to avoid Kotlin treating $-signs as interpolation
        val jsFilter = """
function setFilter(btn, filter) {
  document.querySelectorAll('.filter-btn').forEach(function(b) { b.classList.remove('active'); });
  btn.classList.add('active');
  document.querySelectorAll('#results-table tbody tr').forEach(function(row) {
    if (filter === 'ALL' || row.getAttribute('data-status') === filter) {
      row.style.display = '';
    } else {
      row.style.display = 'none';
    }
  });
}
function openDiff(src) {
  document.getElementById('diff-modal-img').src = src;
  document.getElementById('diff-modal').classList.add('open');
}
function closeModal() {
  document.getElementById('diff-modal').classList.remove('open');
}
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeModal(); });
""".trimIndent()

        val html = buildString {
            appendLine("<!DOCTYPE html>")
            appendLine("<html lang=\"en\">")
            appendLine("<head>")
            appendLine("<meta charset=\"UTF-8\">")
            appendLine("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">")
            appendLine("<title>Screenshot Comparison Report</title>")
            appendLine("<style>")
            appendLine("  * { box-sizing: border-box; margin: 0; padding: 0; }")
            appendLine("  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f7; color: #1d1d1f; }")
            appendLine("  header { background: #1d1d1f; color: #f5f5f7; padding: 24px 32px; }")
            appendLine("  header h1 { font-size: 24px; font-weight: 600; }")
            appendLine("  header p  { font-size: 13px; opacity: 0.6; margin-top: 4px; }")
            appendLine("  .summary { display: flex; gap: 16px; padding: 24px 32px; flex-wrap: wrap; }")
            appendLine("  .card { background: white; border-radius: 12px; padding: 16px 24px; min-width: 100px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }")
            appendLine("  .card .num  { font-size: 36px; font-weight: 700; }")
            appendLine("  .card .lbl  { font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; color: #6e6e73; margin-top: 4px; }")
            appendLine("  .card.pass  .num { color: #34c759; }")
            appendLine("  .card.warn  .num { color: #ff9f0a; }")
            appendLine("  .card.fail  .num { color: #ff3b30; }")
            appendLine("  .card.skip  .num { color: #af52de; }")
            appendLine("  .card.miss  .num { color: #8e8e93; }")
            appendLine("  .card.total .num { color: #007aff; }")
            appendLine("  .controls { padding: 0 32px 16px; display: flex; gap: 8px; flex-wrap: wrap; }")
            appendLine("  .filter-btn { padding: 6px 16px; border-radius: 20px; border: 1.5px solid #d1d1d6; background: white; cursor: pointer; font-size: 13px; font-weight: 500; transition: all 0.15s; }")
            appendLine("  .filter-btn:hover { border-color: #007aff; color: #007aff; }")
            appendLine("  .filter-btn.active { background: #007aff; color: white; border-color: #007aff; }")
            appendLine("  .filter-btn.pass.active  { background: #34c759; border-color: #34c759; }")
            appendLine("  .filter-btn.warn.active  { background: #ff9f0a; border-color: #ff9f0a; }")
            appendLine("  .filter-btn.fail.active  { background: #ff3b30; border-color: #ff3b30; }")
            appendLine("  .filter-btn.skip.active  { background: #af52de; border-color: #af52de; }")
            appendLine("  .filter-btn.miss.active  { background: #8e8e93; border-color: #8e8e93; }")
            appendLine("  .table-wrap { padding: 0 32px 40px; overflow-x: auto; }")
            appendLine("  table { width: 100%; border-collapse: collapse; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }")
            appendLine("  thead th { background: #f5f5f7; padding: 12px 16px; text-align: left; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; color: #6e6e73; font-weight: 600; }")
            appendLine("  tbody td { padding: 12px 16px; border-top: 1px solid #f0f0f5; font-size: 13px; vertical-align: top; }")
            appendLine("  tbody tr:hover td { background: #f9f9fb; }")
            appendLine("  .badge { display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.04em; }")
            appendLine("  .badge-PASS       { background: #d1f2da; color: #1a7a31; }")
            appendLine("  .badge-WARN       { background: #fff3cd; color: #7a5200; }")
            appendLine("  .badge-FAIL       { background: #fde8e8; color: #7a1a1a; }")
            appendLine("  .badge-SKIP_VIDEO { background: #f0e6fb; color: #5a1a7a; }")
            appendLine("  .badge-MISSING    { background: #ebebed; color: #3a3a3c; }")
            appendLine("  .mono { font-family: 'SF Mono', 'Fira Code', monospace; font-size: 12px; }")
            appendLine("  .diff-thumb { max-width: 160px; max-height: 80px; border-radius: 6px; cursor: pointer; margin-top: 6px; display: block; }")
            appendLine("  .diff-modal { display:none; position:fixed; inset:0; background:rgba(0,0,0,0.7); z-index:9999; align-items:center; justify-content:center; }")
            appendLine("  .diff-modal.open { display:flex; }")
            appendLine("  .diff-modal img { max-width:90vw; max-height:90vh; border-radius:8px; }")
            appendLine("  .diff-modal .close { position:absolute; top:20px; right:28px; color:white; font-size:32px; cursor:pointer; line-height:1; }")
            appendLine("  @media (max-width: 600px) { .summary { gap: 8px; } .card { min-width: 80px; } }")
            appendLine("</style>")
            appendLine("</head>")
            appendLine("<body>")
            appendLine("<header>")
            appendLine("  <h1>Screenshot Comparison Report</h1>")
            appendLine("  <p>Generated $generatedAt &nbsp;&middot;&nbsp; $total configs compared</p>")
            appendLine("</header>")
            appendLine("")
            appendLine("<div class=\"summary\">")
            appendLine("  <div class=\"card total\"><div class=\"num\">$total</div><div class=\"lbl\">Total</div></div>")
            appendLine("  <div class=\"card pass\"><div class=\"num\">$pass</div><div class=\"lbl\">Pass</div></div>")
            appendLine("  <div class=\"card warn\"><div class=\"num\">$warn</div><div class=\"lbl\">Warn</div></div>")
            appendLine("  <div class=\"card fail\"><div class=\"num\">$fail</div><div class=\"lbl\">Fail</div></div>")
            appendLine("  <div class=\"card skip\"><div class=\"num\">$skip</div><div class=\"lbl\">Skip</div></div>")
            appendLine("  <div class=\"card miss\"><div class=\"num\">$missing</div><div class=\"lbl\">Missing</div></div>")
            appendLine("</div>")
            appendLine("")
            appendLine("<div class=\"controls\">")
            appendLine("  <button class=\"filter-btn active\" data-filter=\"ALL\" onclick=\"setFilter(this,'ALL')\">All ($total)</button>")
            appendLine("  <button class=\"filter-btn pass\" data-filter=\"PASS\" onclick=\"setFilter(this,'PASS')\">Pass ($pass)</button>")
            appendLine("  <button class=\"filter-btn warn\" data-filter=\"WARN\" onclick=\"setFilter(this,'WARN')\">Warn ($warn)</button>")
            appendLine("  <button class=\"filter-btn fail\" data-filter=\"FAIL\" onclick=\"setFilter(this,'FAIL')\">Fail ($fail)</button>")
            appendLine("  <button class=\"filter-btn skip\" data-filter=\"SKIP_VIDEO\" onclick=\"setFilter(this,'SKIP_VIDEO')\">Skip ($skip)</button>")
            appendLine("  <button class=\"filter-btn miss\" data-filter=\"MISSING\" onclick=\"setFilter(this,'MISSING')\">Missing ($missing)</button>")
            appendLine("</div>")
            appendLine("")
            appendLine("<div class=\"table-wrap\">")
            appendLine("  <table id=\"results-table\">")
            appendLine("    <thead>")
            appendLine("      <tr>")
            appendLine("        <th>#</th>")
            appendLine("        <th>Config</th>")
            appendLine("        <th>Status</th>")
            appendLine("        <th>Aspect Ratio &#916;</th>")
            appendLine("        <th>Color &#916;E</th>")
            appendLine("        <th>SSIM</th>")
            appendLine("        <th>Reason</th>")
            appendLine("        <th>Diff</th>")
            appendLine("      </tr>")
            appendLine("    </thead>")
            appendLine("    <tbody>")
            append(rowsHtml)
            appendLine()
            appendLine("    </tbody>")
            appendLine("  </table>")
            appendLine("</div>")
            appendLine("")
            appendLine("<!-- Diff lightbox modal -->")
            appendLine("<div class=\"diff-modal\" id=\"diff-modal\" onclick=\"closeModal()\">")
            appendLine("  <span class=\"close\" onclick=\"closeModal()\">&#x2715;</span>")
            appendLine("  <img id=\"diff-modal-img\" src=\"\" alt=\"Diff heatmap\">")
            appendLine("</div>")
            appendLine("")
            appendLine("<script>")
            appendLine(jsFilter)
            appendLine("</script>")
            appendLine("</body>")
            append("</html>")
        }

        file.writeText(html)
    }

    private fun buildRow(r: ComparisonResult): String {
        val statusBadge = "<span class=\"badge badge-${r.status.name}\">${r.status.name.replace("_", " ")}</span>"

        val arCell = if (r.status == Status.MISSING) "—"
        else {
            val pct = "%.1f%%".format(r.aspectRatioDiff * 100)
            val cls = if (r.aspectRatioDiff > 0.20) "style=\"color:#ff3b30;font-weight:600\"" else ""
            "<span class=\"mono\" $cls>$pct</span>"
        }

        val colorCell = if (r.status == Status.MISSING) "—"
        else {
            val cls = if (r.colorDistance > 15.0) "style=\"color:#ff3b30;font-weight:600\"" else ""
            "<span class=\"mono\" $cls>${"%.1f".format(r.colorDistance)}</span>"
        }

        val ssimCell = when {
            r.status == Status.MISSING -> "—"
            r.status == Status.SKIP_VIDEO -> "<span class=\"mono\" style=\"color:#af52de\">skipped</span>"
            r.ssim == 0.0 && r.status != Status.FAIL -> "—"
            else -> {
                val cls = if (r.ssim < 0.85) "style=\"color:#ff3b30;font-weight:600\"" else ""
                "<span class=\"mono\" $cls>${"%.4f".format(r.ssim)}</span>"
            }
        }

        val diffCell = when {
            r.diffImageBase64 != null -> {
                val dataUri = "data:image/png;base64,${r.diffImageBase64}"
                "<img class=\"diff-thumb\" src=\"$dataUri\" alt=\"diff\" onclick=\"openDiff(this.src)\" title=\"Click to enlarge\">"
            }
            else -> "—"
        }

        val reasonCell = if (r.reason.isNotEmpty())
            "<span class=\"mono\">${escapeHtml(r.reason)}</span>"
        else "—"

        return """      <tr data-status="${r.status.name}">
        <td class="mono" style="color:#8e8e93"></td>
        <td><strong>${escapeHtml(r.config)}</strong></td>
        <td>$statusBadge</td>
        <td>$arCell</td>
        <td>$colorCell</td>
        <td>$ssimCell</td>
        <td>$reasonCell</td>
        <td>$diffCell</td>
      </tr>"""
    }

    private fun escapeHtml(s: String): String = s
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\"", "&quot;")
}
