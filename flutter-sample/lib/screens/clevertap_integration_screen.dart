import 'dart:async';

import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import '../automation/asset_manifest_automation.dart';
import '../automation/automation_signals.dart';

class CleverTapIntegrationScreen extends StatefulWidget {
  const CleverTapIntegrationScreen({super.key});

  @override
  State<CleverTapIntegrationScreen> createState() => _CleverTapIntegrationScreenState();
}

class _CleverTapIntegrationScreenState extends State<CleverTapIntegrationScreen> {
  final _eventController = TextEditingController();
  final List<String> _log = [];
  final List<NativeDisplayUnit> _units = [];

  // CleverTapPlugin() returns the singleton — needed for instance method registration.
  final _ct = CleverTapPlugin();

  @override
  void initState() {
    super.initState();
    _ct.setCleverTapDisplayUnitsLoadedHandler(_onUnitsLoaded);
    //_fetchCachedUnits();

    // Automation only (ND_AUTOMATION): warm the image cache from the
    // incremental manifest before any campaign is fired, so the first
    // screenshot pass renders warm. No-op in normal runs. Needs a BuildContext
    // for precacheImage, so defer to the first frame.
    if (AssetManifestAutomation.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AssetManifestAutomation.warmCache(context);
      });
    }
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _fetchCachedUnits() async {
    try {
      final units = await CleverTapPlugin.getAllDisplayUnits();
      await _onUnitsLoaded(units?.cast<dynamic>(),
          source: 'getAllDisplayUnits PULL (init)');
    } catch (e) {
      _addLog('ERROR fetching cached units: $e');
    }
  }

  Future<void> _onUnitsLoaded(List<dynamic>? rawUnits,
      {String source = 'delegate PUSH (onDisplayUnitsLoaded)'}) async {
    // Log every raw unit the SDK hands us, on both the push and pull paths, with
    // the same identifiers the native sample prints — so one-behind delivery is
    // visible per event (fire event N, see which unit actually arrives).
    _logUnits(source, rawUnits);

    if (rawUnits == null || rawUnits.isEmpty) return;

    // Automation only (ND_AUTOMATION): accumulate every asset URL in the raw
    // units into the incremental manifest so a later run can warm the image
    // cache before capturing. No-op in normal runs.
    unawaited(AssetManifestAutomation.recordUnits(rawUnits));

    // Parsing (deep-cast + 3-strategy extraction + style resolution) runs off
    // the main thread via Isolate.run() in NativeDisplayConfigParser.
    final parsed = await NativeDisplayConfigParser.parseAll(rawUnits);

    // clevertap_plugin exposes a single display-units handler (unlike the
    // native multi-listener bridge), so this screen is the one sink. Fan the
    // parsed units out to the SlotManager too: units carrying a `slot_id` are
    // routed to their NativeDisplaySlot on the Slots tab, while the canvas
    // below shows every unit. Mirrors the native bridge's fan-out.
    NativeDisplaySlotManager.instance.deliverUnits(parsed);

    if (!mounted) return;
    setState(() {
      _units
        ..clear()
        ..addAll(parsed);
      _log.add('[${_ts()}] Received ${parsed.length} Native Display unit(s)');
    });

    // Automation handshake (ND_AUTOMATION): signal that a new display-units
    // batch has landed and been rendered. The screenshot suite polls this to
    // know *this* event's response is on the canvas before capturing. Harmless
    // in normal runs — nothing reads it.
    AutomationSignals.batchCount.value++;

    if (parsed.length < rawUnits.length) {
      _addLog('WARN: ${rawUnits.length - parsed.length} unit(s) had no recognisable NativeDisplayConfig');
    }
  }

  Future<void> _sendEvent() async {
    final name = _eventController.text.trim();
    if (name.isEmpty) return;

    // Dismiss the soft keyboard on send. Flutter does NOT auto-dismiss when the
    // send is a button tap (only an IME completion action would), so the field
    // keeps focus and the keyboard stays up otherwise — worse UX and it lingers
    // during automation. Unfocus explicitly.
    FocusManager.instance.primaryFocus?.unfocus();

    // Automation only (ND_AUTOMATION): clear the canvas the moment we fire so it
    // returns to the "Waiting for Native Display response…" state until the new
    // batch arrives. Combined with the batch-counter handshake, this guarantees
    // a screenshot can never capture the *previous* event's campaign. Gated so
    // normal interactive use doesn't flash the canvas empty on every send.
    if (AssetManifestAutomation.enabled) {
      setState(() => _units.clear());
    }

    await CleverTapPlugin.recordEvent(name, {});
    debugPrint('[CT-ND ${_ts()}] >>> fired event: "$name"');
    _addLog('Fired event: $name');
    _eventController.clear();
    setState(() {});
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() => _log.add('[${_ts()}] $msg'));
  }

  /// Logs every raw display unit the SDK delivers, tagged by source
  /// (`delegate PUSH` vs `getAllDisplayUnits PULL`), with the id/extras the
  /// native sample prints. Fire event N and watch which campaign actually
  /// arrives — this makes Core's one-behind delegate delivery visible.
  void _logUnits(String source, List<dynamic>? rawUnits) {
    final count = rawUnits?.length ?? 0;
    debugPrint('[CT-ND ${_ts()}] $source → $count unit(s)');
    _addLog('$source → $count unit(s)');
    if (rawUnits == null) return;
    for (var i = 0; i < rawUnits.length; i++) {
      final u = rawUnits[i];
      final wzrk = (u is Map) ? u['wzrk_id'] : null;
      final ti = (u is Map) ? u['ti'] : null;
      final slot = (u is Map) ? u['slot_id'] : null;
      final title =
          RegExp(r'Title - (\w+) event fired').firstMatch('$u')?.group(1);
      final detail = '[$i] wzrk_id=$wzrk ti=$ti slot=$slot title=${title ?? "?"}';
      debugPrint('[CT-ND]   $detail');
      _addLog(detail);
    }
  }

  String _ts() {
    final n = DateTime.now();
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${p(n.hour)}:${p(n.minute)}:${p(n.second)}.${p(n.millisecond, 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CleverTap Integration'),
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
                  // Automation hook — matches Android `ct-event-input` testTag
                  // and iOS `ct-event-input` accessibilityIdentifier so the
                  // cross-platform screenshot suites drive the same UI.
                  key: const Key('ct-event-input'),
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
                key: const Key('ct-send-event-btn'),
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
  final List<NativeDisplayUnit> units;
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
    // Mirror each native sample's parent-size behaviour so Flutter matches the
    // verified native rendering per platform:
    //  - iOS native injects the canvas geometry (\.nativeDisplayParentSize), so on
    //    iOS we pass the canvas size as parentSize (viewport-anchored).
    //  - Android native injects nothing; its SDK derives the parent from the
    //    (unbounded, in a LazyColumn) constraints and falls back to screen. So on
    //    Android we pass null and let the SDK mirror that exactly.
    // Width is minus the 16dp horizontal padding on each side.
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = defaultTargetPlatform == TargetPlatform.iOS
            ? Size(constraints.maxWidth - 32, constraints.maxHeight)
            : null;
        return ListView.builder(
      itemCount: units.length,
      itemBuilder: (ctx, i) {
        final unit = units[i];
        final unitId = unit.unitId.isNotEmpty ? unit.unitId : null;
        return Padding(
          // Stable identity so the list preserves each unit's element/State
          // (video playback, nested gallery page, etc.) across deliveries
          // rather than reusing State by position. unitId is unique per unit;
          // empty-id units fall back to a per-index key (distinct type, no clash).
          key: ValueKey(unitId ?? i),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: NativeDisplayView(
            config: unit.config,
            resolvedStyles: unit.resolvedStyles,
            unitId: unitId,
            parentSize: canvasSize,
            // Impression attribution — fired once per unit by the SDK.
            onNotificationViewed: (id) {
              CleverTapPlugin.pushDisplayUnitViewedEvent(id);
              onAction('VIEWED unit $id');
            },
            // Element-level click attribution — extras already sanitized by the SDK.
            onNotificationClicked: (id, elementId, extras) {
              if (elementId.isNotEmpty) {
                CleverTapPlugin.pushDisplayUnitElementClickedEvent(id, extras);
                onAction('CLICKED element $elementId on unit $id');
              } else {
                // Fallback: no element id — record a unit-level click.
                CleverTapPlugin.pushDisplayUnitClickedEvent(id);
                onAction('CLICKED unit $id');
              }
            },
            actionListener: (action, nodeId, params) {
              onAction('ACTION $action on $nodeId');
            },
          ),
        );
      },
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

  // Log is visible by default on every launch (matches Android/iOS). The
  // automation suites tap `event-log-toggle` once to collapse it so it doesn't
  // cover the Native Display canvas in screenshots.
  bool _logVisible = true;

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
    if (msg.contains('VIEWED')) return const Color(0xFFCE93D8);
    if (msg.contains('CLICKED')) return const Color(0xFFFFAB91);
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_logVisible && widget.messages.isNotEmpty)
                    TextButton(
                      onPressed: widget.onClear,
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  IconButton(
                    key: const Key('event-log-toggle'),
                    tooltip: _logVisible ? 'Hide log' : 'Show log',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _logVisible ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _logVisible = !_logVisible),
                  ),
                ],
              ),
            ],
          ),
          if (_logVisible)
            Container(
              key: const Key('event-log-content'),
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
