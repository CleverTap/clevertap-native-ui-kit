import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';

NativeDisplayConfig _config() => NativeDisplayConfig.fromJson(const {
      'root': {
        'type': 'element',
        'id': 't',
        'elementType': 'text',
        'bindings': {'text': 'Hi'},
        'layout': {
          'width': {'value': 100, 'unit': 'dp'},
          'height': {'value': 40, 'unit': 'dp'},
        },
      },
    });

NativeDisplayUnit _unit(String unitId, String? slotId) => NativeDisplayUnit(
      unitId: unitId,
      slotId: slotId,
      config: _config(),
    );

// Raw CleverTap display-unit JSON (as forwarded from clevertap_plugin) with an
// inline native_display_config — exercises the parse+route ingestion path.
Map<String, dynamic> _rawUnit(String unitId, String slotId) => {
      'wzrk_id': unitId,
      'slot_id': slotId,
      'native_display_config': {
        'root': {
          'type': 'element',
          'id': 't',
          'elementType': 'text',
          'bindings': {'text': 'Hi'},
          'layout': {
            'width': {'value': 100, 'unit': 'dp'},
            'height': {'value': 40, 'unit': 'dp'},
          },
        },
      },
    };

class _RecordingObserver implements NativeDisplaySlotObserver {
  final List<NativeDisplayUnit> available = [];
  final List<String> cleared = [];

  @override
  void onUnitAvailable(NativeDisplayUnit unit) => available.add(unit);

  @override
  void onUnitCleared(String slotId) => cleared.add(slotId);
}

void main() {
  final manager = NativeDisplaySlotManager.instance;

  setUp(manager.resetForTest);
  tearDown(manager.resetForTest);

  group('routing', () {
    test('unit delivered to a registered observer for its slot', () {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(observer.available.map((u) => u.unitId), ['u1']);
    });

    test('a cached unit is delivered immediately on late registration', () {
      manager.deliverUnits([_unit('u1', 'hero')]);

      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);

      expect(observer.available.single.unitId, 'u1');
    });

    test('all observers for a slot receive the unit', () {
      final a = _RecordingObserver();
      final b = _RecordingObserver();
      manager.registerSlot('hero', a);
      manager.registerSlot('hero', b);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(a.available.single.unitId, 'u1');
      expect(b.available.single.unitId, 'u1');
    });

    test('units are routed only to their matching slot', () {
      final hero = _RecordingObserver();
      final footer = _RecordingObserver();
      manager.registerSlot('hero', hero);
      manager.registerSlot('footer', footer);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(hero.available, hasLength(1));
      expect(footer.available, isEmpty);
    });

    test('a unit without a slot_id is ignored', () {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);

      manager.deliverUnits([_unit('u1', null)]);

      expect(observer.available, isEmpty);
    });

    test('the latest unit replaces the cached one for a slot', () {
      manager.deliverUnits([_unit('u1', 'hero')]);
      manager.deliverUnits([_unit('u2', 'hero')]);

      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);

      expect(observer.available.single.unitId, 'u2');
    });

    test('registering the same observer twice does not double-deliver', () {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);
      manager.registerSlot('hero', observer);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(observer.available, hasLength(1));
    });

    test('an observer that unregisters during delivery does not break the loop',
        () {
      final survivor = _RecordingObserver();
      late final NativeDisplaySlotObserver selfRemoving;
      selfRemoving = _UnregisterOnDelivery(manager, 'hero', () => selfRemoving);

      manager.registerSlot('hero', selfRemoving);
      manager.registerSlot('hero', survivor);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(survivor.available, hasLength(1));
    });
  });

  group('registration lifecycle', () {
    test('getActiveSlotIds reflects live registrations', () {
      final a = _RecordingObserver();
      final b = _RecordingObserver();
      manager.registerSlot('hero', a);
      manager.registerSlot('footer', b);

      expect(manager.getActiveSlotIds(), {'hero', 'footer'});
    });

    test('unregister stops delivery and removes an emptied slot', () {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);
      manager.unregisterSlot('hero', observer);

      manager.deliverUnits([_unit('u1', 'hero')]);

      expect(observer.available, isEmpty);
      expect(manager.getActiveSlotIds(), isEmpty);
    });

    test('a slot keeps its entry while other observers remain', () {
      final a = _RecordingObserver();
      final b = _RecordingObserver();
      manager.registerSlot('hero', a);
      manager.registerSlot('hero', b);
      manager.unregisterSlot('hero', a);

      expect(manager.getActiveSlotIds(), {'hero'});
    });
  });

  group('clearing', () {
    test('clearSlot notifies observers and drops the cached unit', () {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);
      manager.deliverUnits([_unit('u1', 'hero')]);

      manager.clearSlot('hero');

      expect(observer.cleared, ['hero']);
      // A fresh registration must not receive the cleared unit.
      final late = _RecordingObserver();
      manager.registerSlot('hero', late);
      expect(late.available, isEmpty);
    });

    test('clearAll notifies every observer', () {
      final hero = _RecordingObserver();
      final footer = _RecordingObserver();
      manager.registerSlot('hero', hero);
      manager.registerSlot('footer', footer);
      manager.deliverUnits([_unit('u1', 'hero'), _unit('u2', 'footer')]);

      manager.clearAll();

      expect(hero.cleared, ['hero']);
      expect(footer.cleared, ['footer']);
    });
  });

  group('server slot-sync', () {
    test('syncActiveSlots returns false when no callback is wired', () {
      manager.registerSlot('hero', _RecordingObserver());
      expect(manager.syncActiveSlots(), isFalse);
    });

    test('syncActiveSlots emits wzrk_nd_slot_sync with the active slot ids', () {
      String? event;
      Map<String, Object?>? data;
      manager.onSlotSync = (e, d) {
        event = e;
        data = d;
      };
      manager.registerSlot('hero', _RecordingObserver());
      manager.registerSlot('footer', _RecordingObserver());

      final ok = manager.syncActiveSlots();

      expect(ok, isTrue);
      expect(event, NativeDisplaySlotManager.wzrkNdSlotSync);
      expect((data?['slots'] as List).toSet(), {'hero', 'footer'});
    });
  });

  group('ingestion (parse + route)', () {
    test('processDisplayUnits parses raw JSON and routes by slot', () async {
      final observer = _RecordingObserver();
      manager.registerSlot('hero', observer);

      await manager.processDisplayUnits([_rawUnit('u1', 'hero')]);

      expect(observer.available.single.unitId, 'u1');
    });

    test('processDisplayUnit routes a single raw unit', () async {
      final observer = _RecordingObserver();
      manager.registerSlot('footer', observer);

      await manager.processDisplayUnit(_rawUnit('u9', 'footer'));

      expect(observer.available.single.unitId, 'u9');
    });
  });
}

class _UnregisterOnDelivery implements NativeDisplaySlotObserver {
  _UnregisterOnDelivery(this._manager, this._slotId, this._self);

  final NativeDisplaySlotManager _manager;
  final String _slotId;
  final NativeDisplaySlotObserver Function() _self;

  @override
  void onUnitAvailable(NativeDisplayUnit unit) =>
      _manager.unregisterSlot(_slotId, _self());

  @override
  void onUnitCleared(String slotId) {}
}
