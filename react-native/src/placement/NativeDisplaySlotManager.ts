import { NativeDisplayBridge, NativeDisplayBridgeListener } from '../bridge/NativeDisplayBridge';
import { NativeDisplayUnit } from '../bridge/NativeDisplayUnit';

export interface NativeDisplaySlotObserver {
  onUnitAvailable(unit: NativeDisplayUnit): void;
  onUnitCleared(slotId: string): void;
}

class NativeDisplaySlotManager implements NativeDisplayBridgeListener {
  private static _instance: NativeDisplaySlotManager | null = null;

  static get shared(): NativeDisplaySlotManager {
    if (!this._instance) {
      this._instance = new NativeDisplaySlotManager();
    }
    return this._instance;
  }

  private readonly _slots = new Map<string, Set<NativeDisplaySlotObserver>>();
  private readonly _unitIndex = new Map<string, NativeDisplayUnit>();

  constructor() {
    NativeDisplayBridge.shared.addListener(this);
  }

  registerSlot(slotId: string, observer: NativeDisplaySlotObserver): void {
    if (!this._slots.has(slotId)) {
      this._slots.set(slotId, new Set());
    }
    this._slots.get(slotId)!.add(observer);
    console.log(`[NativeDisplaySlotManager] Registered observer for slot: ${slotId}`);

    // Immediate delivery if unit already cached
    const cached = this._unitIndex.get(slotId);
    if (cached) {
      console.log(`[NativeDisplaySlotManager] Delivering cached unit ${cached.unitId} to new observer for slot: ${slotId}`);
      observer.onUnitAvailable(cached);
    }
  }

  unregisterSlot(slotId: string, observer: NativeDisplaySlotObserver): void {
    const observers = this._slots.get(slotId);
    if (!observers) return;
    observers.delete(observer);
    if (observers.size === 0) {
      this._slots.delete(slotId);
    }
    console.log(`[NativeDisplaySlotManager] Unregistered observer for slot: ${slotId}`);
  }

  getActiveSlotIds(): Set<string> {
    return new Set(this._slots.keys());
  }

  getUnit(slotId: string): NativeDisplayUnit | null {
    return this._unitIndex.get(slotId) ?? null;
  }

  clearSlot(slotId: string): void {
    this._unitIndex.delete(slotId);
    const observers = this._slots.get(slotId);
    if (observers) {
      for (const observer of observers) {
        try { observer.onUnitCleared(slotId); } catch { /* ignore */ }
      }
    }
  }

  clearAll(): void {
    for (const slotId of this._unitIndex.keys()) {
      this.clearSlot(slotId);
    }
  }

  syncCurrentSlotIds(cleverTap: unknown): void {
    if (!cleverTap || typeof cleverTap !== 'object') return;
    const ct = cleverTap as Record<string, unknown>;
    if (typeof ct['recordEvent'] !== 'function') return;

    const slotIds = Array.from(this.getActiveSlotIds()).join(',');
    console.log(`[NativeDisplaySlotManager] Syncing active slot IDs: ${slotIds}`);
    (ct['recordEvent'] as (name: string, props: Record<string, unknown>) => void)(
      'wzrk_nd_slot_sync',
      { slot_ids: slotIds },
    );
  }

  // NativeDisplayBridgeListener
  onNativeDisplaysLoaded(units: NativeDisplayUnit[]): void {
    for (const unit of units) {
      if (!unit.slotId) continue;
      this._unitIndex.set(unit.slotId, unit);
      const observers = this._slots.get(unit.slotId);
      if (observers) {
        for (const observer of observers) {
          try {
            observer.onUnitAvailable(unit);
          } catch (e) {
            console.error(`[NativeDisplaySlotManager] Observer threw an exception for slot ${unit.slotId}:`, e);
          }
        }
      }
    }
  }
}

export { NativeDisplaySlotManager };
