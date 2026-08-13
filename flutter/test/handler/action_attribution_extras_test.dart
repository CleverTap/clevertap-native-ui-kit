import 'package:flutter_test/flutter_test.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:clevertap_native_display/src/handler/action_attribution_extras.dart';
import 'package:clevertap_native_display/src/internal/nd_sdk_version.dart';

// Mirrors android/sdk .../handler/ActionAttributionExtrasTest.kt and the iOS
// equivalent — the flattening keys must match key-for-key for dashboard parity.
void main() {
  group('ActionAttributionExtras.from', () {
    test('null action returns empty map', () {
      expect(ActionAttributionExtras.from(null), isEmpty);
    });

    test('open_url emits url and browser flag and spreads metadata', () {
      final action = NDAction.fromJson({
        'type': 'open_url',
        'url': 'https://example.com',
        'openInBrowser': true,
        'metadata': {'wzrk_c2a': 'Buy Now'},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['action_type'], 'open_url');
      expect(extras['action_url'], 'https://example.com');
      expect(extras['action_open_in_browser'], true);
      expect(extras['wzrk_c2a'], 'Buy Now');
    });

    test('custom spreads JsonObject value entries verbatim', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'kv',
        'value': {'sku': 'SKU-123', 'qty': 2},
        'metadata': {'campaign': 'summer', 'tier': 'gold'},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['action_type'], 'custom');
      expect(extras['action_key'], 'kv');
      expect(extras.containsKey('action_value'), isFalse);
      expect(extras['sku'], 'SKU-123');
      expect(extras['qty'], 2);
      // metadata entries spread verbatim alongside value entries
      expect(extras['campaign'], 'summer');
      expect(extras['tier'], 'gold');
    });

    test('custom metadata wins on key collision with value entries', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'kv',
        'value': {'user_id': 'from-value', 'only_in_value': 'v'},
        'metadata': {'user_id': 'from-meta', 'only_in_meta': 'm'},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['user_id'], 'from-meta');
      expect(extras['only_in_value'], 'v');
      expect(extras['only_in_meta'], 'm');
    });

    test('custom with empty JsonObject value emits no spread entries', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'kv',
        'value': <String, dynamic>{},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras.containsKey('action_value'), isFalse);
      expect(extras.keys.toSet(), {'action_type', 'action_key'});
    });

    test('custom scalar value round-trips as native type under action_value', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'amount',
        'value': 42,
      });
      final extras = ActionAttributionExtras.from(action);
      expect(extras['action_value'], 42);
    });

    test('custom serializes non-map value collections to JSON string', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'list',
        'value': [1, 2, 3],
      });
      final extras = ActionAttributionExtras.from(action);
      expect(extras['action_value'], '[1,2,3]');
    });

    test('custom metadata spreads BE-injected wzrk attribution fields', () {
      final action = NDAction.fromJson({
        'type': 'custom',
        'key': 'kv',
        'value': <String, dynamic>{},
        'metadata': {
          'wzrk_element_id': 'btn_hero',
          'wzrk_c2a': 'Buy Now',
          'wzrk_act': 'click',
        },
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['wzrk_element_id'], 'btn_hero');
      expect(extras['wzrk_c2a'], 'Buy Now');
      expect(extras['wzrk_act'], 'click');
    });

    test('navigate emits destination and spreads params', () {
      final action = NDAction.fromJson({
        'type': 'navigate',
        'destination': 'profile',
        'params': {'user_id': 'u-1'},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['action_type'], 'navigate');
      expect(extras['action_destination'], 'profile');
      expect(extras['user_id'], 'u-1');
    });

    test('event emits name and spreads properties as scalars', () {
      final action = NDAction.fromJson({
        'type': 'event',
        'eventName': 'Banner Tapped',
        'properties': {'position': 3, 'is_hero': true},
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['action_type'], 'event');
      expect(extras['action_event_name'], 'Banner Tapped');
      expect(extras['position'], 3);
      expect(extras['is_hero'], true);
    });

    test('composite emits count and mode', () {
      final action = NDAction.fromJson({
        'type': 'composite',
        'executionMode': 'parallel',
        'actions': [
          {'type': 'open_url', 'url': 'https://a'},
          {'type': 'navigate', 'destination': 'home'},
        ],
      });
      final extras = ActionAttributionExtras.from(action);

      expect(extras['action_type'], 'composite');
      expect(extras['action_count'], 2);
      expect(extras['action_mode'], 'parallel');
    });

    test('client never injects wzrk_ keys — only present when in metadata', () {
      final action = NDAction.fromJson({
        'type': 'open_url',
        'url': 'https://example.com',
      });
      final extras = ActionAttributionExtras.from(action);
      expect(extras.keys.any((k) => k.startsWith('wzrk_')), isFalse);
    });
  });

  group('ActionAttributionExtras.sanitize', () {
    test('null input returns only the ND lib version stamp', () {
      final out = ActionAttributionExtras.sanitize(null);
      expect(out['nd_lib_v_name'], NDSdkVersion.name);
      expect(out['nd_lib_v_code'], NDSdkVersion.code);
      expect(out.keys.toSet(), {'nd_lib_v_name', 'nd_lib_v_code'});
    });

    test('empty input returns only the ND lib version stamp', () {
      final out = ActionAttributionExtras.sanitize(const {});
      expect(out.keys.toSet(), {'nd_lib_v_name', 'nd_lib_v_code'});
    });

    test('keeps scalars/collections and drops nulls and empty keys', () {
      final out = ActionAttributionExtras.sanitize({
        's': 'x',
        'i': 1,
        'b': true,
        'n': null,
        '': 'ignored',
        'arr': [1, 2, 3],
        'obj': {'k': 'v'},
      });

      expect(out['s'], 'x');
      expect(out['i'], 1);
      expect(out['b'], true);
      expect(out.containsKey('n'), isFalse);
      expect(out.containsKey(''), isFalse);
      expect(out['arr'], [1, 2, 3]);
      expect(out['obj'], {'k': 'v'});
      expect(out['nd_lib_v_name'], NDSdkVersion.name);
      expect(out['nd_lib_v_code'], NDSdkVersion.code);
    });

    test('does not overwrite caller-supplied version keys', () {
      final out = ActionAttributionExtras.sanitize({
        'nd_lib_v_name': 'caller-wins',
        'nd_lib_v_code': 999999,
      });
      expect(out['nd_lib_v_name'], 'caller-wins');
      expect(out['nd_lib_v_code'], 999999);
    });
  });

  group('ActionAttributionExtras.versionStamp', () {
    test('returns exactly the ND lib version keys', () {
      final out = ActionAttributionExtras.versionStamp();
      expect(out['nd_lib_v_name'], NDSdkVersion.name);
      expect(out['nd_lib_v_code'], NDSdkVersion.code);
      expect(out.keys.toSet(), {'nd_lib_v_name', 'nd_lib_v_code'});
    });
  });
}
