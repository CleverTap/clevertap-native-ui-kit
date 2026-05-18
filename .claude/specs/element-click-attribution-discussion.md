# Element-level Click Attribution for Native Display — Discussion Doc

**Status**: Discussion draft (for team review, no implementation commitment)
**Audience**: Core SDK team (Android + iOS), Native Display SDK team, analytics/dashboard stakeholders
**Related**: Jira `SDK-5793`; ND PR [#32](https://github.com/CleverTap/clevertap-native-ui-kit/pull/32); Ultron BE PR [#44025](https://github.com/CleverTap-Platform/Ultron/pull/44025); Core SDK PRs [#999](https://github.com/CleverTap/clevertap-android-sdk/pull/999) (Android) and [#538](https://github.com/CleverTap/clevertap-ios-sdk/pull/538) (iOS)

---

## TL;DR

The Core SDK's existing `pushDisplayUnitClickedEventForID(unitId)` was designed when a display unit was a **single tappable entity**. Native Display (ND) units are **multi-element**: a single unit hosts N buttons / text / images, each with its own `onClick` action. Attributing "which element was clicked, with what KV payload" through a method whose contract is "unit was clicked" is the wrong shape — it forces us into one of two awkward workarounds (Core SDK overload that piggybacks the same method name, or cache-mutation hacks). This doc lays out the current state, the workarounds we've evaluated, their cost, and proposes a **new dedicated Core SDK method** purpose-built for element-level interactions. **No implementation decision is requested in this doc — just alignment on the problem framing before we lock the contract.**

---

## 1. Current Core SDK display-unit attribution

Two public methods, one per direction:

### Android — `clevertap-core/src/main/java/com/clevertap/android/sdk/CleverTapAPI.java`

```java
public void pushDisplayUnitViewedEventForID(String unitID)
public void pushDisplayUnitClickedEventForID(String unitID)
```

Body (in `AnalyticsManager.java:197-252`):

```java
JSONObject event = new JSONObject();
event.put("evtName", "Notification Clicked");          // or "Notification Viewed"
CleverTapDisplayUnit displayUnit = controllerManager.getCTDisplayUnitController()
                                                   .getDisplayUnitForID(unitID);
JSONObject eventExtraData = displayUnit.getWZRKFields();   // filter cached unit JSON to wzrk_* keys
event.put("evtData", eventExtraData);
coreMetaData.setWzrkParams(eventExtraData);                // attach to wzrk_ref batch header
baseEventQueueManager.queueEvent(context, event, RAISED_EVENT,
                                 getFlattenedEventProperties(eventExtraData));
```

`getWZRKFields()` (`CleverTapDisplayUnit.java:214-232`) is a filter: **every top-level key from the cached unit JSON that starts with `wzrk_`** flows onto the event.

### iOS — `CleverTapSDK/CleverTap+DisplayUnit.h`

```objc
- (void)recordDisplayUnitViewedEventForID:(NSString *)unitID;
- (void)recordDisplayUnitClickedEventForID:(NSString *)unitID;
```

Body (in `CleverTap.m:3974-4008` → `CTEventBuilder.m:380-405`):

```objc
NSDictionary *data = displayUnit.json;
for (NSString *x in [data allKeys]) {
    if (![CTUtils doesString:x startWith:@"wzrk_"]
        && ![CTUtils doesString:x startWith:@"W$"]) continue;
    NSString *key = [x stringByReplacingOccurrencesOfString:@"W$" withString:@"wzrk_"];
    notif[key] = data[x];
}
notif[@"wzrk_cts"] = @((long)[NSDate timeIntervalSince1970]);
event[CLTAP_EVENT_NAME] = @"Notification Clicked";    // or "Notification Viewed"
event[CLTAP_EVENT_DATA] = notif;
```

Same shape: filter cached unit JSON's top-level keys by `wzrk_*` prefix, emit as `Notification Clicked` / `Notification Viewed`.

### What both contracts assume

> "A display unit was clicked." The unit is the unit of attribution. The cached unit JSON owns the entire `wzrk_*` enrichment — `wzrk_id` (campaign id), `wzrk_pivot` (variant), `wzrk_cgId` (control group), etc. There is one click event per unit click, and the unit's identity carries all the attribution context.

For a single-image App Inbox-style unit, this is correct. For ND, **it isn't**.

---

## 2. What Native Display introduces

An ND display unit is a server-driven tree (see `clevertap-native-ui-kit/docs/JSON_STRUCTURE_REFERENCE.md`): a root container with N children, where each leaf can be a `BUTTON`, `IMAGE`, `TEXT`, etc., and each node has its own `actions` map keyed by trigger (`onClick`, `onAppear`, …) whose values are `Action` objects (`open_url`, `custom`, `navigate`, `composite`).

Concrete example — a campaign with 3 buttons:

```jsonc
{
  "wzrk_id": "1778663560_20260513",
  "wzrk_pivot": "wzrk_default",
  "native_display_config": {
    "root": {
      "type": "container",
      "id": "root",
      "actions": {
        "onClick": { "type": "custom", "key": "kv", "value": {"k1":"v1", "k2":"v2", "k3":"v3"} }
      },
      "children": [
        {
          "type": "element", "id": "button-1", "elementType": "button",
          "actions": { "onClick": { "type": "custom", "key": "kv", "value": {"k1":"v1", "k2":"v2"} } }
        },
        {
          "type": "element", "id": "button-2", "elementType": "button",
          "actions": { "onClick": { "type": "open_url", "url": {"android":"https://fb.com","ios":"https://google.com"} } }
        },
        {
          "type": "element", "id": "button-3", "elementType": "button",
          "actions": { "onClick": { "type": "custom", "key": "close", "value": true } }
        }
      ]
    }
  }
}
```

When `button-2` is clicked, the dashboard needs to know:
- Which **campaign** was clicked (`wzrk_id`, `wzrk_pivot`, …) — same data as today's `pushDisplayUnitClickedEventForID(unitId)` already provides.
- Which **element** within the campaign was clicked (`button-2`).
- What **action context** the click carried (`open_url`, the URL, the `openInBrowser` flag, etc.).

The third bucket — per-click context that varies per element — has **no home** in the current method contract. It's not on the cached unit JSON (the unit JSON is server-static; the action context is per-element-per-click). And the existing method signature `(unitId) -> void` provides no channel for it.

---

## 3. Approaches we've evaluated

This section is a candid record of the design space, not a recommendation list. Each approach has been concretely sketched; each has a real cost.

### 3.1 Approach A — Overload the existing method with `additionalProperties`

> Add `pushDisplayUnitClickedEventForID(unitId, HashMap<String,Object>)` / `recordDisplayUnitClickedEventForID:additionalProperties:` on Core SDK. Bridge reflectively detects the overload at runtime; calls it when present, falls back to the single-arg call otherwise.

Status: **partially shipped**. ND PR [#32](https://github.com/CleverTap/clevertap-native-ui-kit/pull/32) implements the bridge side. Core SDK overload not yet added to PRs #999 / #538.

**Pros**
- Minimal API surface — one new overload per platform.
- Clean separation: extras are explicit, no cache mutation.
- Forward-compat reflection means ND SDK doesn't have to pin a Core SDK version.

**Cons / mismatches**
- **Semantic mismatch is preserved.** The method name is still `pushDisplayUnitClicked…` — for an element click, the name is misleading.
- The shape "click an element, but reuse the unit-level method with extras" requires every reader/consumer (Core SDK code, future maintainers, dashboard query authors) to know that `additionalProperties` here means "per-element-click context, not unit-level metadata."
- Clients on older Core SDK get **silent attribution loss** for the action context — `additionalProperties` is just dropped. The event still fires but contains no per-button info. That's the original problem you raised about "forcing clients to upgrade."
- The event name on the wire is still `Notification Clicked` — analytics consumers can't distinguish element-level clicks from unit-level clicks. If a campaign has multiple buttons, every click looks like the same event with different `evtData` shape.

### 3.2 Approach B — Cache-inject `wzrk_*` keys before each push

> Before calling the existing single-arg method, mutate the cached unit JSON to add `wzrk_btn_id`, `wzrk_nd_action_url`, `wzrk_nd_k1`, etc. at top level. Core SDK's `wzrk_*` filter forwards them to `evtData`. After the call, restore the cache JSON.

Sketched as the "backward-compat fallback" in earlier discussion (see plan file).

**Pros**
- Works against **any** Core SDK version. No client upgrade required.

**Cons**
- **`wzrk_*` namespace squatting.** That prefix is server-owned (`wzrk_id` / `wzrk_pivot` / future evolution per Ultron PR #43454). We're injecting client-controlled data into the server's namespace.
- **Mutate-and-restore complexity.** Subsequent Viewed/Clicked events on the same unit would pick up stale keys without a restore step. We've designed a try/finally + cache overlay pattern, but it's a significant ND-SDK-side state-management burden.
- **Once-per-session `wzrk_ref` propagation.** Both Core SDKs attach the click's `evtData` to subsequent batched-request headers as `wzrk_ref` (Android `QueueHeaderBuilder.kt:181-186`; iOS `CleverTap.m:3981/3999`). Our injected `wzrk_nd_*` keys would ride along on unrelated batched events. Verified noise, not corruption, but it's there.
- **Dashboard schema split** (only mitigated, not avoided): the cache-inject path emits `wzrk_nd_action_url` etc.; the overload path emits unprefixed `action_url`. Two shapes for the same logical fields. We discussed unifying via `wzrk_nd_*` in both paths, but that worsens the namespace-squatting issue without solving the semantic mismatch.

### 3.3 Approach C — Fire a separate `pushEvent("Notification Element Clicked", props)`

Considered very early. **Rejected**: Core SDK's `DEFAULT_RESTRICTED_EVENT_NAMES` blocks event names in the `Notification *` family from being raised via `pushEvent`. Public API path is closed.

### 3.4 Approach D — Spread vs stringify nested `CustomAction.value`

A sub-detail of the bridge-side helper, not an approach to the bigger problem. Recorded for completeness — the helper (ND PR #32, commit `1864382`) spreads JsonObject `value` entries as first-class keys on the additionalProperties payload, so a button with `value: {k1: "v1", k2: "v2"}` lands `k1`, `k2` as queryable properties instead of one stringified blob. Compatible with both Approach A and Approach B contracts.

---

## 4. Proposed direction — a new Core SDK method dedicated to element interactions

> Add a NEW method (not an overload) on Core SDK that is purpose-built for "element within a display unit was interacted with." Existing methods stay for unit-level attribution.

**Proposed signatures** (open for naming bikeshed):

```java
// Android (CleverTapAPI.java)
public void pushDisplayUnitElementClickedEventForID(
    String unitID,
    String elementID,
    HashMap<String, Object> additionalProperties
)
```

```objc
// iOS (CleverTap+DisplayUnit.h)
- (void)recordDisplayUnitElementClickedEventForID:(NSString *)unitID
                                        elementID:(NSString *)elementID
                             additionalProperties:(NSDictionary<NSString *, id> *)props;
```

**Internal behavior**
- Look up the unit by id → enrich with `wzrk_*` from cached unit JSON (same as today).
- Add the `elementID` to the event payload as a first-class field (e.g. `wzrk_element_id` — within `wzrk_*` filter so it naturally rides on `wzrk_ref` propagation if any element-aware re-attribution is wanted).
- Merge `additionalProperties` into `evtData` after enrichment. Strip any `wzrk_*` keys defensively (server namespace stays one-way).
- **Open question**: emit as a distinct event name on the wire (`Notification Element Clicked`) so the dashboard can distinguish unit-vs-element interactions cleanly? Or piggyback `Notification Clicked` and let analytics differentiate by presence of `wzrk_element_id`?

**Why a new method beats Approach A's overload**
- The method name **encodes the semantic**: this is an element-level interaction, not a unit-level one. Future maintainers and dashboard query authors don't need tribal knowledge to read it correctly.
- Older Core SDK clients call the **existing unit-level method** as a graceful degradation — they still attribute the campaign click, they just don't get element granularity. That's the same fallback Approach A gives, but without the overload-naming confusion.
- A new method gives us room to make `elementID` **required** (vs. an optional `additionalProperties` key in Approach A). Required-elementID makes the contract self-documenting.
- The Core SDK side can fire a **distinct event name** if we want clean dashboard separation. (With Approach A overload, we'd be back to one event name regardless.)

**Implications for ND SDK**
- Bridge replaces the current `pushDisplayUnit*EventForID(unitId, extras)` reflective call with a `pushDisplayUnitElementClickedEventForID(unitId, elementId, extras)` reflective call (button click) and keeps the legacy `pushDisplayUnit*EventForID(unitId)` call for root-container clicks. Method-presence check via reflection drives the fallback as today.
- Action-attribution helper output shape becomes simpler — no `wzrk_nd_*` namespace required, no `action_key` confusion. Just `additionalProperties = {action_type, action_url, …, k1, k2}` and `elementId` as a separate first-class argument.

---

## 5. Backward compatibility strategy

Whichever method (or methods) the Core SDK exposes, the ND SDK has to gracefully handle three Core SDK age cohorts:

| Cohort | Has `setDisplayUnitCache` (SDK-5763/5764) | Has new attribution method | ND SDK behavior |
|---|---|---|---|
| Old | No | No | Reflective seed via `ReflectionSeeder`; call legacy `pushDisplayUnit*EventForID(unitId)`. **No per-element attribution** — degrade to unit-level click. |
| Mid | Yes | No | Cache adapter wired; call legacy `pushDisplayUnit*EventForID(unitId)`. **No per-element attribution.** |
| New | Yes | Yes | Cache adapter wired; call new method with `elementId` + `additionalProperties`. **Full per-element attribution.** |

This means **graceful degradation**, not "force clients to upgrade or break." Clients on old Core SDK get coarse unit-level attribution (as they do today); clients on new Core SDK get fine-grained per-element attribution. No silent data corruption, no namespace squatting, no cache mutation.

If we want a stronger backward-compat story (older clients still see per-element KVs on the dashboard), we'd revisit Approach B (cache-inject) — but only after deciding it's worth the namespace + mutation cost. The recommendation in this doc is that **graceful degradation is the right floor**; Approach B is a lever we can pull later if business needs it, not a default.

---

## 6. Open questions for the team

1. **New method vs Approach A overload?** This doc argues for a new method. Counter-arguments?
2. **Event name on the wire** — `Notification Element Clicked` (new) vs `Notification Clicked` (existing, with `wzrk_element_id` field)?
3. **Should `Viewed` get the same element-level treatment?** Per-button impression isn't really a thing in ND (we view the whole unit), so probably no — but worth confirming.
4. **`elementID` shape** — string (button's `node.id` from the JSON config) or richer (button's `elementType` + index)? Recommend string for simplicity; element type can ride on `additionalProperties` if needed.
5. **Backward-compat floor** — graceful degradation (recommended), or do we invest in Approach B's cache-inject for older clients too?
6. **Naming bikeshed** — `pushDisplayUnitElementClickedEventForID` is verbose. Shorter alternatives: `pushDisplayUnitButtonClickedEventForID` (button-specific but excludes future non-button interactions), `pushDisplayUnitInteractedEventForID` (generic), `pushDisplayUnitChildClickedEventForID` (tree-aware).
7. **Dashboard schema** — does analytics want to keep a single `Notification Clicked` table with optional element fields, or a separate table for element clicks? Affects whether we fire a distinct event name.

---

## 7. What we'd ask the Core SDK team to confirm before locking the contract

- Are there any **runtime side effects** of introducing a new `Notification *` event name beyond the dashboard pipeline (e.g. campaign-frequency-capping, in-app re-evaluation, profile updates)? The doc above verified the existing flow doesn't touch profile; we'd want similar confidence for any new event name.
- Is **`wzrk_element_id`** a name the server backend can adopt cleanly, or would they prefer a non-`wzrk_*` field? (Affects whether `wzrk_ref` re-attribution can chain by element.)
- Are there **release-window constraints**? If a new method has a long lead time, we may still want Approach A's overload as a near-term stopgap with this new method as the v+1 plan.

---

## Appendix — Repo evidence cited in this doc

- Android Core SDK: `clevertap-core/src/main/java/com/clevertap/android/sdk/AnalyticsManager.java:197-252` (existing push methods), `CleverTapDisplayUnit.java:214-232` (`getWZRKFields` filter), `QueueHeaderBuilder.kt:181-186` (`wzrk_ref` propagation), `Constants.java` (`WZRK_PREFIX = "wzrk_"`).
- iOS Core SDK: `CleverTapSDK/CleverTap+DisplayUnit.h:147+157` (existing public selectors), `CleverTap.m:3974-4008` (record methods), `CTEventBuilder.m:380-405` (`buildDisplayViewStateEvent` enrichment), `CTConstants.h:87-90` (prefixes).
- ND SDK: `android/sdk/src/main/kotlin/com/clevertap/android/nativedisplay/handler/ActionAttributionExtras.kt` + Swift counterpart (the bridge-side helper that builds extras from a click action), `bridge/NativeDisplayBridge.kt` + Swift counterpart (reflective overload-dispatch fallback).
- Ultron BE PR [#44025](https://github.com/CleverTap-Platform/Ultron/pull/44025) — the new BE shape `{type:"custom", key:"kv", value:{…}}` for multi-KV button clicks.
- Memory note `reference_core_sdk_attribution_enrichment.md` for the `wzrk_*` filter contract details.
