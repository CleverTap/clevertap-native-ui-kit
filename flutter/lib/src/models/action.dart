import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'enums.dart';

// Coerce metadata JSON values to String. Primitives go through toString();
// nested objects/arrays are serialized to a compact JSON string so the map
// stays Map<String, String> without crashing on the dynamic cast.
// Mirrors parseMetadataToStringMap on Android and ndMetadataToStringMap on iOS.
Map<String, String>? _parseMetadataToStringMap(dynamic raw) {
  if (raw is! Map) return null;
  final result = <String, String>{};
  raw.forEach((k, v) {
    if (v == null) return;
    if (v is String) {
      result[k.toString()] = v;
    } else if (v is bool || v is num) {
      result[k.toString()] = v.toString();
    } else {
      result[k.toString()] = jsonEncode(v);
    }
  });
  return result.isEmpty ? null : result;
}

// Resolve the OpenUrl `url` field. Accepts:
//   "https://..."                     — plain string
//   {"android":"...","ios":"..."}     — platform object (prefer host platform)
//   {"android":{text,replacements}}   — legacy Ultron object; use `text`
String _resolveOpenUrlValue(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw;
  if (raw is! Map) return '';
  final key = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  final altKey = defaultTargetPlatform == TargetPlatform.iOS ? 'android' : 'ios';
  final platformVal = raw[key] ?? raw[altKey];
  if (platformVal is String) return platformVal;
  if (platformVal is Map) {
    final text = platformVal['text'];
    if (text is String) return text;
  }
  return '';
}

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
  // url can be a plain string, a platform map {"android": "...", "ios": "..."},
  // or the legacy Ultron {text, replacements} object — resolved at parse time.
  final String url;
  final bool openInBrowser;
  final bool customTabsEnabled;
  final Map<String, String>? metadata;

  const OpenUrlAction({
    required this.url,
    this.openInBrowser = false,
    this.customTabsEnabled = true,
    this.metadata,
  });

  factory OpenUrlAction.fromJson(Map<String, dynamic> json) => OpenUrlAction(
        url: _resolveOpenUrlValue(json['url']),
        openInBrowser: json['openInBrowser'] as bool? ?? false,
        customTabsEnabled: json['customTabsEnabled'] as bool? ?? true,
        metadata: _parseMetadataToStringMap(json['metadata']),
      );
}

class CustomAction extends NDAction {
  final String key;
  final dynamic value;
  final Map<String, String>? metadata;

  const CustomAction({required this.key, this.value, this.metadata});

  factory CustomAction.fromJson(Map<String, dynamic> json) => CustomAction(
        key: json['key'] as String? ?? '',
        value: json['value'],
        metadata: _parseMetadataToStringMap(json['metadata']),
      );
}

class NavigateAction extends NDAction {
  final String destination;
  final Map<String, String>? params;

  const NavigateAction({required this.destination, this.params});

  factory NavigateAction.fromJson(Map<String, dynamic> json) => NavigateAction(
        destination: json['destination'] as String? ?? '',
        params: (json['params'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
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
