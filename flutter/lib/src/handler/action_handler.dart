import 'package:url_launcher/url_launcher.dart';

import '../internal/nd_logger.dart';
import '../models/action.dart';
import '../models/enums.dart';
import '../renderer/native_display_view.dart';

class ActionHandler {
  final NativeDisplayActionListener? listener;

  const ActionHandler({this.listener});

  Future<void> handle(NDAction action, String nodeId) async {
    return switch (action) {
      OpenUrlAction a => _handleOpenUrl(a, nodeId),
      CustomAction a => _handleCustom(a, nodeId),
      NavigateAction a => _handleNavigate(a, nodeId),
      TrackEventAction a => _handleTrackEvent(a, nodeId),
      CompositeAction a => _handleComposite(a, nodeId),
    };
  }

  Future<void> _handleOpenUrl(OpenUrlAction action, String nodeId) async {
    // Match Core SDK openUrl: strip newlines, route via OS so custom schemes
    // (myapp://, fb://, spotify://) work without a scheme allowlist.
    final sanitized = action.url.replaceAll('\n', '').replaceAll('\r', '');
    final uri = Uri.tryParse(sanitized);
    if (uri == null) return;
    try {
      final LaunchMode mode;
      if (action.openInBrowser) {
        mode = LaunchMode.externalApplication;
      } else if (action.customTabsEnabled) {
        // Chrome Custom Tabs on Android, SFSafariViewController on iOS.
        mode = LaunchMode.inAppBrowserView;
      } else {
        mode = LaunchMode.platformDefault;
      }
      await launchUrl(uri, mode: mode);
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
