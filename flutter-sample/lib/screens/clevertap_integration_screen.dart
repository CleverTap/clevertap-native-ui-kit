import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

/// Mirrors the Android CleverTapIntegrationScreen.
/// Subscribes to NativeDisplayBridge.eventStream to receive display units pushed
/// from the native CleverTap Core SDK and renders them via NativeDisplayView.
class CleverTapIntegrationScreen extends StatefulWidget {
  const CleverTapIntegrationScreen({super.key});

  @override
  State<CleverTapIntegrationScreen> createState() => _CleverTapIntegrationScreenState();
}

class _CleverTapIntegrationScreenState extends State<CleverTapIntegrationScreen> {
  final _eventController = TextEditingController();
  final List<String> _log = [];
  final List<NativeDisplayConfig> _units = [];
  StreamSubscription<Map<String, dynamic>>? _unitSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToUnits();
  }

  @override
  void dispose() {
    _unitSubscription?.cancel();
    _eventController.dispose();
    super.dispose();
  }

  void _log_(String msg) {
    final now = TimeOfDay.now();
    final ts = '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}]';
    setState(() => _log.add('$ts $msg'));
  }

  void _subscribeToUnits() {
    _unitSubscription = NativeDisplayBridge.eventStream.listen(
      (event) {
        if (event['type'] == 'units_updated') {
          final rawUnits = (event['units'] as List?)?.cast<String>() ?? [];
          final configs = <NativeDisplayConfig>[];
          for (final jsonStr in rawUnits) {
            if (jsonStr.isEmpty) continue;
            try {
              final map = jsonDecode(jsonStr) as Map<String, dynamic>;
              configs.add(NativeDisplayConfig.fromJson(map));
            } catch (e) {
              _log_('ERROR parsing unit: $e');
            }
          }
          setState(() {
            _units
              ..clear()
              ..addAll(configs);
            _log.add(
              '[${_timestamp()}] Received ${configs.length} Native Display unit(s)',
            );
          });
        }
      },
      onError: (Object e) => _log_('ERROR from event stream: $e'),
    );
  }

  String _timestamp() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendEvent() async {
    final name = _eventController.text.trim();
    if (name.isEmpty) return;
    await NativeDisplayBridge.pushEvent(name);
    _log_('Fired event: $name');
    _eventController.clear();
    setState(() {});
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
            isSendEnabled: _eventController.text.isNotEmpty,
            eventController: _eventController,
            onChanged: () => setState(() {}),
          ),
          Expanded(child: _CanvasContent(units: _units, onAction: _log_)),
          _EventLogFooter(messages: _log, onClear: () => setState(() => _log.clear())),
        ],
      ),
    );
  }
}

class _FireEventHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSendEnabled;
  final TextEditingController eventController;
  final VoidCallback onChanged;

  const _FireEventHeader({
    required this.controller,
    required this.onSend,
    required this.isSendEnabled,
    required this.eventController,
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
                onPressed: isSendEnabled ? onSend : null,
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

class _CanvasContent extends StatelessWidget {
  final List<NativeDisplayConfig> units;
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
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: NativeDisplayView(
          config: units[i],
          actionListener: (action, nodeId, params) => onAction('ACTION $action on $nodeId'),
        ),
      ),
    );
  }
}

class _EventLogFooter extends StatefulWidget {
  final List<String> messages;
  final VoidCallback onClear;

  const _EventLogFooter({required this.messages, required this.onClear});

  @override
  State<_EventLogFooter> createState() => _EventLogFooterState();
}

class _EventLogFooterState extends State<_EventLogFooter> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_EventLogFooter old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _msgColor(String msg) {
    if (msg.contains('EVENT')) return const Color(0xFFFFD54F);
    if (msg.contains('ACTION')) return const Color(0xFF81D4FA);
    if (msg.contains('ERROR')) return const Color(0xFFEF9A9A);
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
                TextButton(onPressed: widget.onClear, child: const Text('Clear', style: TextStyle(fontSize: 12))),
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
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF607D8B),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.messages.length,
                    itemBuilder: (ctx, i) => Text(
                      widget.messages[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _msgColor(widget.messages[i]),
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
