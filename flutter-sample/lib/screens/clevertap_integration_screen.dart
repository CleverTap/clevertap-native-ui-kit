import 'dart:convert';

import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

class CleverTapIntegrationScreen extends StatefulWidget {
  const CleverTapIntegrationScreen({super.key});

  @override
  State<CleverTapIntegrationScreen> createState() => _CleverTapIntegrationScreenState();
}

class _CleverTapIntegrationScreenState extends State<CleverTapIntegrationScreen> {
  final _eventController = TextEditingController();
  final List<String> _log = [];
  final List<_UnitEntry> _units = [];

  // CleverTapPlugin() returns the singleton — needed for instance method registration.
  final _ct = CleverTapPlugin();

  @override
  void initState() {
    super.initState();
    _ct.setCleverTapDisplayUnitsLoadedHandler(_onUnitsLoaded);
    _fetchCachedUnits();
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _fetchCachedUnits() async {
    try {
      final units = await CleverTapPlugin.getAllDisplayUnits();
      if (units != null && units.isNotEmpty) {
        _onUnitsLoaded(units.cast<dynamic>());
      }
    } catch (e) {
      _addLog('ERROR fetching cached units: $e');
    }
  }

  void _onUnitsLoaded(List<dynamic>? units) {
    if (units == null || units.isEmpty) return;
    final parsed = <_UnitEntry>[];
    for (final unit in units) {
      final entry = _extractEntry(unit);
      if (entry != null) {
        parsed.add(entry);
      } else {
        _addLog('WARN: unit has no recognisable NativeDisplayConfig');
      }
    }
    if (!mounted) return;
    setState(() {
      _units
        ..clear()
        ..addAll(parsed);
      _log.add('[${_ts()}] Received ${parsed.length} Native Display unit(s)');
    });
  }

  /// Platform channel maps arrive as Map<Object?, Object?> at every nesting level.
  /// This recursively converts the entire tree to Map<String, dynamic>.
  static Map<String, dynamic> _deepCast(Map raw) =>
      raw.map((k, v) => MapEntry(k.toString(), _deepCastValue(v)));

  static dynamic _deepCastValue(dynamic v) {
    if (v is Map) return _deepCast(v);
    if (v is List) return v.map(_deepCastValue).toList();
    return v;
  }

  /// Mirrors the 3-strategy extraction from the old SampleApplication.kt.
  _UnitEntry? _extractEntry(dynamic raw) {
    if (raw is! Map) return null;
    final unit = _deepCast(raw);
    final unitId = unit['wzrk_id']?.toString() ?? unit['slot_id']?.toString();

    // Strategy 1: native_display_config key
    final ndRaw = unit['native_display_config'];
    if (ndRaw is Map<String, dynamic>) {
      try {
        return _UnitEntry(NativeDisplayConfig.fromJson(ndRaw), unitId);
      } catch (e) {
        _addLog('ERROR parsing native_display_config: $e');
      }
    }

    // Strategy 2: custom_kv.nd_config string
    final kv = unit['custom_kv'];
    if (kv is Map<String, dynamic>) {
      final ndStr = kv['nd_config'];
      if (ndStr is String && ndStr.isNotEmpty) {
        try {
          return _UnitEntry(
            NativeDisplayConfig.fromJson(jsonDecode(ndStr) as Map<String, dynamic>),
            unitId,
          );
        } catch (e) {
          _addLog('ERROR parsing custom_kv.nd_config: $e');
        }
      }
    }

    // Strategy 3: top-level root key
    if (unit.containsKey('root')) {
      try {
        return _UnitEntry(NativeDisplayConfig.fromJson(unit), unitId);
      } catch (e) {
        _addLog('ERROR parsing root-level config: $e');
      }
    }

    return null;
  }

  Future<void> _sendEvent() async {
    final name = _eventController.text.trim();
    if (name.isEmpty) return;
    await CleverTapPlugin.recordEvent(name, {});
    _addLog('Fired event: $name');
    _eventController.clear();
    setState(() {});
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() => _log.add('[${_ts()}] $msg'));
  }

  String _ts() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CleverTap Integration'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _FireEventHeader(
            controller: _eventController,
            onSend: _sendEvent,
            onChanged: () => setState(() {}),
          ),
          Expanded(
            child: _CanvasContent(
              units: _units,
              onAction: _addLog,
            ),
          ),
          _EventLogFooter(
            messages: _log,
            onClear: () => setState(() => _log.clear()),
          ),
        ],
      ),
    );
  }
}

class _UnitEntry {
  final NativeDisplayConfig config;
  final String? unitId;
  const _UnitEntry(this.config, this.unitId);
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FireEventHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onChanged;

  const _FireEventHeader({
    required this.controller,
    required this.onSend,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter event name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => onChanged(),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: controller.text.isNotEmpty ? onSend : null,
                child: const Text('Send Event'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Native Display Canvas',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Canvas ────────────────────────────────────────────────────────────────────

class _CanvasContent extends StatelessWidget {
  final List<_UnitEntry> units;
  final void Function(String) onAction;

  const _CanvasContent({required this.units, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return Center(
        child: Text(
          'Waiting for Native Display response…',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      itemCount: units.length,
      itemBuilder: (ctx, i) {
        final entry = units[i];
        // DEBUG: outer slot shown in red, inner card in its natural state
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: NativeDisplayView(
            config: entry.config,
            actionListener: (action, nodeId, params) {
              onAction('ACTION $action on $nodeId');
              if (entry.unitId != null) {
                CleverTapPlugin.pushDisplayUnitClickedEvent(entry.unitId!);
              }
            },
          ),
        );
      },
    );
  }
}

// ── Event Log ─────────────────────────────────────────────────────────────────

class _EventLogFooter extends StatefulWidget {
  final List<String> messages;
  final VoidCallback onClear;

  const _EventLogFooter({required this.messages, required this.onClear});

  @override
  State<_EventLogFooter> createState() => _EventLogFooterState();
}

class _EventLogFooterState extends State<_EventLogFooter> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_EventLogFooter old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _color(String msg) {
    if (msg.contains('Fired')) return const Color(0xFFFFD54F);
    if (msg.contains('ACTION')) return const Color(0xFF81D4FA);
    if (msg.contains('ERROR') || msg.contains('WARN')) return const Color(0xFFEF9A9A);
    if (msg.contains('Received')) return const Color(0xFFA5D6A7);
    return const Color(0xFF80CBC4);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Event Log', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (widget.messages.isNotEmpty)
                TextButton(
                  onPressed: widget.onClear,
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF263238),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: widget.messages.isEmpty
                ? const Text(
                    'No events yet',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF607D8B)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: widget.messages.length,
                    itemBuilder: (ctx, i) => Text(
                      widget.messages[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _color(widget.messages[i]),
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
