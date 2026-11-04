import 'package:url_launcher/url_launcher.dart';

import '../internal/nd_logger.dart';
import '../models/action.dart';
import '../models/enums.dart';
import '../renderer/native_display_view.dart';

class ActionHandler {
  final NativeDisplayActionListener? listener;

  /// Host open-url interceptor. When it returns `true`, the SDK does not open the
  /// URL itself (the host handled it). Mirrors native `onOpenUrl(...) -> Bool`.
  final NativeDisplayOpenUrlCallback? onOpenUrl;

  const ActionHandler({this.listener, this.onOpenUrl});

  Future<void> handle(NDAction action, String nodeId) async {
    return switch (action) {
      final OpenUrlAction a => _handleOpenUrl(a, nodeId),
      final CustomAction a => _handleCustom(a, nodeId),
      final NavigateAction a => _handleNavigate(a, nodeId),
      final TrackEventAction a => _handleTrackEvent(a, nodeId),
      final CompositeAction a => _handleComposite(a, nodeId),
    };
  }

  Future<void> _handleOpenUrl(OpenUrlAction action, String nodeId) async {
    // Host opt-out (mirrors native onOpenUrl -> Bool): if the host handles the URL
    // itself — e.g. in-app routing for a deeplink — the SDK must not also open it.
    if (onOpenUrl?.call(action.url, action.openInBrowser) ?? false) {
      NDLogger.d('ActionHandler', 'open_url handled by host: ${action.url}');
      return;
    }

    // Match Core SDK openUrl: strip newlines before parsing.
    final sanitized = action.url.replaceAll('\n', '').replaceAll('\r', '');
    final uri = Uri.tryParse(sanitized);
    if (uri == null) {
      NDLogger.w('ActionHandler', 'Invalid URL: ${action.url}');
      return;
    }

    // External-only for now, consistent across platforms: the OS routes deeplinks
    // / app URLs (myapp://, tel:, mailto:) to the registered app and http/https to
    // the external browser (app-claimed / Universal Links still go to the owning
    // app). Matches native Android (Intent.ACTION_VIEW).
    // TODO(custom-tabs): when in-app browser support lands, honour
    // customTabsEnabled → LaunchMode.inAppBrowserView (Chrome Custom Tabs /
    // SFSafariViewController) for http/https.
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        NDLogger.w('ActionHandler', 'No app available to open URL: ${action.url}');
      }
    } catch (e) {
      NDLogger.w('ActionHandler', 'failed to launch URL ${action.url}: $e');
    }
    listener?.call('open_url', nodeId, {
      'url': action.url,
      // Surface query params alongside attribution metadata so listeners can
      // act on deep-link state without re-parsing the URL.
      if (uri.queryParameters.isNotEmpty) ...uri.queryParameters,
      if (action.metadata != null) ...?action.metadata,
    });
  }

  void _handleCustom(CustomAction action, String nodeId) {
    listener?.call('custom', nodeId, {
      'key': action.key,
      if (action.value != null) 'value': action.value,
      if (action.metadata != null) ...?action.metadata,
    });
  }

  void _handleNavigate(NavigateAction action, String nodeId) {
    listener?.call('navigate', nodeId, {
      'destination': action.destination,
      if (action.params != null) ...?action.params,
    });
  }

  void _handleTrackEvent(TrackEventAction action, String nodeId) {
    listener?.call('event', nodeId, {
      'eventName': action.eventName,
      if (action.properties != null) ...?action.properties,
    });
  }

  Future<void> _handleComposite(CompositeAction action, String nodeId) async {
    if (action.executionMode == ExecutionMode.parallel) {
      await Future.wait(action.actions.map((a) => handle(a, nodeId)));
    } else {
      for (final a in action.actions) {
        await handle(a, nodeId);
      }
    }
  }
}
