import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../evaluator/variable_evaluator.dart';
import '../../models/enums.dart';
import '../../models/native_display_node.dart';
import '../../models/style.dart';
import '../../utils/dimension_calculator.dart';
import '../root_height_scope.dart';
import '../style_applier.dart';

class HtmlElement extends StatefulWidget {
  final NativeDisplayElement node;
  final Style style;
  final VariableEvaluator evaluator;

  const HtmlElement({
    super.key,
    required this.node,
    required this.style,
    required this.evaluator,
  });

  @override
  State<HtmlElement> createState() => _HtmlElementState();
}

class _HtmlElementState extends State<HtmlElement> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final config = widget.node.htmlConfig;
    _controller = WebViewController()
      ..setJavaScriptMode(
        config?.javascriptEnabled == true
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(
        config?.transparentBackground != false
            ? const Color(0x00000000)
            : const Color(0xFFFFFFFF),
      );

    _loadContent();
  }

  void _loadContent() {
    final htmlBinding = widget.evaluator.evaluateString(
      widget.node.bindings['html'] ?? '',
    );
    if (htmlBinding.isNotEmpty) {
      _controller.loadHtmlString(
        htmlBinding,
        baseUrl: widget.node.htmlConfig?.baseUrl,
      );
      return;
    }
    final urlBinding = widget.evaluator.evaluateString(
      widget.node.bindings['url'] ?? '',
    );
    if (urlBinding.isNotEmpty) {
      _controller.loadRequest(Uri.parse(urlBinding));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootHeight = RootHeightScope.of(context);
    final layout = widget.node.layout;

    // HTML requires an explicit height — wrap_content is unsupported by WebView.
    // Resolve height from layout; fall back to 200dp for wrap_content or unspecified.
    final rawHeight = DimensionCalculator.resolve(layout?.height, parentSize: rootHeight);
    final isWrapContent = layout?.height?.special == SpecialDimension.wrapContent;
    final isMatchParent = layout?.height?.special == SpecialDimension.matchParent;
    if (isWrapContent) {
      debugPrint('[NativeDisplay] HtmlElement: wrap_content height unsupported; using 200dp fallback');
    }
    final double? height = isMatchParent
        ? null
        : (rawHeight ?? 200);

    Widget webView = WebViewWidget(controller: _controller);
    if (height != null) {
      webView = SizedBox(height: height, child: webView);
    } else {
      webView = Expanded(child: webView);
    }

    return StyleApplier.apply(
      webView,
      widget.style,
      rootHeight: rootHeight,
      padding: layout?.padding,
    );
  }
}
