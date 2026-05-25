import 'enums.dart';

sealed class NDAction {
  const NDAction();

  factory NDAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'open_url' => OpenUrlAction.fromJson(json),
      'custom' => CustomAction.fromJson(json),
      'navigate' => NavigateAction.fromJson(json),
      'event' => TrackEventAction.fromJson(json),
      'composite' => CompositeAction.fromJson(json),
      _ => CustomAction(key: type, value: null),
    };
  }
}

class OpenUrlAction extends NDAction {
  // url can be a plain string, or a platform map {"android": "...", "ios": "..."}
  final String url;
  final bool openInBrowser;
  final bool customTabsEnabled;

  const OpenUrlAction({
    required this.url,
    this.openInBrowser = false,
    this.customTabsEnabled = true,
  });

  factory OpenUrlAction.fromJson(Map<String, dynamic> json) {
    final urlRaw = json['url'];
    String url;
    if (urlRaw is Map) {
      // Platform-specific URL map — use 'ios' key for Flutter (treated as iOS-like)
      url = (urlRaw['ios'] as String?) ?? (urlRaw['android'] as String?) ?? '';
    } else {
      url = urlRaw as String? ?? '';
    }
    return OpenUrlAction(
      url: url,
      openInBrowser: json['openInBrowser'] as bool? ?? false,
      customTabsEnabled: json['customTabsEnabled'] as bool? ?? true,
    );
  }
}

class CustomAction extends NDAction {
  final String key;
  final dynamic value;
  final Map<String, String>? metadata;

  const CustomAction({required this.key, this.value, this.metadata});

  factory CustomAction.fromJson(Map<String, dynamic> json) => CustomAction(
        key: json['key'] as String? ?? '',
        value: json['value'],
        metadata: (json['metadata'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)),
      );
}

class NavigateAction extends NDAction {
  final String destination;
  final Map<String, String>? params;

  const NavigateAction({required this.destination, this.params});

  factory NavigateAction.fromJson(Map<String, dynamic> json) => NavigateAction(
        destination: json['destination'] as String? ?? '',
        params: (json['params'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)),
      );
}

class TrackEventAction extends NDAction {
  final String eventName;
  final Map<String, dynamic>? properties;

  const TrackEventAction({required this.eventName, this.properties});

  factory TrackEventAction.fromJson(Map<String, dynamic> json) => TrackEventAction(
        eventName: json['eventName'] as String? ?? '',
        properties: json['properties'] as Map<String, dynamic>?,
      );
}

class CompositeAction extends NDAction {
  final List<NDAction> actions;
  final ExecutionMode executionMode;

  const CompositeAction({
    required this.actions,
    this.executionMode = ExecutionMode.sequential,
  });

  factory CompositeAction.fromJson(Map<String, dynamic> json) => CompositeAction(
        actions: (json['actions'] as List?)
                ?.map((e) => NDAction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        executionMode: ExecutionMode.fromJson(json['executionMode'] as String? ?? 'sequential'),
      );
}

abstract final class ActionTriggers {
  static const onClick = 'onClick';
  static const onLongPress = 'onLongPress';
  static const onDoubleTap = 'onDoubleTap';
  static const onAppear = 'onAppear';
  static const onDisappear = 'onDisappear';
}
