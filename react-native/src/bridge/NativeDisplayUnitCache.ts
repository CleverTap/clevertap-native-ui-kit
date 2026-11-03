import { NativeDisplayUnit } from './NativeDisplayUnit';

export class NativeDisplayUnitCache {
  private cache = new Map<string, NativeDisplayUnit>();

  put(unit: NativeDisplayUnit): void {
    this.cache.set(unit.unitId, unit);
  }

  replaceAll(units: NativeDisplayUnit[]): void {
    this.cache.clear();
    for (const unit of units) {
      this.cache.set(unit.unitId, unit);
    }
  }

  get(unitId: string): NativeDisplayUnit | undefined {
    return this.cache.get(unitId);
  }

  getAll(): NativeDisplayUnit[] {
    return Array.from(this.cache.values());
  }

  clear(): void {
    this.cache.clear();
  }
}
