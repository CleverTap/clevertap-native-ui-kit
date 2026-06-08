# Arrangement Strategies — Visual Guide

## Understanding Each Strategy

This guide shows exactly how each arrangement strategy affects the layout of the three items.

**Container Height**: 400dp  
**Item Heights**: 48dp each  
**Default Spacing** (SPACED): 16dp  
**Container Padding**: 16dp (all sides)

---

## Strategy 1: SPACED

**Description**: Fixed spacing between children  
**Spacing**: 16dp between items  
**Edges**: No extra space

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 16dp spacing                                 │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 16dp spacing                                 │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ Remaining space (240dp)                      │
│                                                 │
└─────────────────────────────────────────────────┘

Total Used: 48 + 16 + 48 + 16 + 48 = 176dp
Remaining: 400 - 32 (padding) - 176 = 192dp (empty at bottom)
```

**Use Case**: Standard list layouts, consistent spacing

---

## Strategy 2: SPACE_BETWEEN

**Description**: Equal space between items, none at edges  
**Spacing**: Dynamic (fills available space)  
**Edges**: Items flush to top and bottom

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp) - FLUSH TO TOP         │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 112dp spacing (calculated)                   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 112dp spacing (calculated)                   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp) - FLUSH TO BOTTOM      │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘

Calculation:
Container: 400dp - 32dp (padding) = 368dp available
Items: 48 × 3 = 144dp
Remaining: 368 - 144 = 224dp
Spaces: 224 ÷ 2 = 112dp each
```

**Use Case**: Spread layout, maximize vertical space utilization

---

## Strategy 3: SPACE_EVENLY

**Description**: Equal space everywhere including edges  
**Spacing**: Dynamic (same at edges and between)  
**Edges**: Equal space at top and bottom

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│  ↕ 74.67dp spacing                              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 74.67dp spacing                              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 74.67dp spacing                              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 74.67dp spacing                              │
│                                                 │
└─────────────────────────────────────────────────┘

Calculation:
Available: 368dp
Items: 144dp
Remaining: 224dp
Spaces: 4 (top + 3 between)
Each space: 224 ÷ 4 = 56dp
```

**Use Case**: Perfectly balanced layouts, centered groups

---

## Strategy 4: SPACE_AROUND

**Description**: Equal space around each item (half at edges)  
**Spacing**: Dynamic (half space at edges)  
**Edges**: Half the spacing of between items

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│  ↕ 37.33dp spacing (half)                       │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 74.67dp spacing (full)                       │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 74.67dp spacing (full)                       │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 37.33dp spacing (half)                       │
│                                                 │
└─────────────────────────────────────────────────┘

Calculation:
Available: 368dp
Items: 144dp
Remaining: 224dp
Each item gets: 224 ÷ 3 = 74.67dp around it
Edges get: 74.67 ÷ 2 = 37.33dp
```

**Use Case**: Visually balanced with gentle padding

---

## Strategy 5: START

**Description**: Items aligned to start (top)  
**Spacing**: No spacing between items  
**Edges**: All remaining space at bottom

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp) - AT TOP               │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp) - DIRECTLY BELOW       │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp) - DIRECTLY BELOW       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│                                                 │
│  (All remaining space at bottom)                │
│                                                 │
│                                                 │
│                                                 │
└─────────────────────────────────────────────────┘

Total Used: 48 × 3 = 144dp
Remaining: 368 - 144 = 224dp (all at bottom)
```

**Use Case**: Top-aligned content, header sections

---

## Strategy 6: CENTER

**Description**: Items centered vertically  
**Spacing**: No spacing between items  
**Edges**: Equal space at top and bottom

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│                                                 │
│  ↕ 112dp (equal space top)                      │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp) - CENTERED GROUP      │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp)                        │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ↕ 112dp (equal space bottom)                   │
│                                                 │
│                                                 │
└─────────────────────────────────────────────────┘

Calculation:
Available: 368dp
Items: 144dp
Remaining: 224dp
Top space: 224 ÷ 2 = 112dp
Bottom space: 112dp
```

**Use Case**: Hero sections, centered cards, modals

---

## Strategy 7: END

**Description**: Items aligned to end (bottom)  
**Spacing**: No spacing between items  
**Edges**: All remaining space at top

```
┌─────────────────────────────────────────────────┐
│ 🔴 Root Container (400dp height)                │
│    16dp padding ↓                               │
│                                                 │
│                                                 │
│                                                 │
│  (All remaining space at top)                   │
│                                                 │
│                                                 │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🔵 Item 1 (48dp) - DIRECTLY ABOVE       │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟢 Item 2 (48dp) - DIRECTLY ABOVE       │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🟠 Item 3 (48dp) - AT BOTTOM            │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘

Total Used: 48 × 3 = 144dp
Remaining: 368 - 144 = 224dp (all at top)
```

**Use Case**: Bottom-aligned content, footer sections, action buttons

---

## Quick Comparison Table

| Strategy | Top Space | Between Items | Bottom Space | Total Spacing |
|----------|-----------|---------------|--------------|---------------|
| SPACED | 0dp | 16dp each | 192dp | 224dp |
| BETWEEN | 0dp | 112dp each | 0dp | 224dp |
| EVENLY | 56dp | 56dp each | 56dp | 224dp |
| AROUND | 37.33dp | 74.67dp each | 37.33dp | 224dp |
| START | 0dp | 0dp | 224dp | 224dp |
| CENTER | 112dp | 0dp | 112dp | 224dp |
| END | 224dp | 0dp | 0dp | 224dp |

---

## When to Use Each Strategy

### SPACED
✅ Standard lists  
✅ Consistent spacing needed  
✅ Traditional UI layouts  
✅ Forms with labeled inputs

### SPACE_BETWEEN
✅ Maximize vertical spread  
✅ Two-endpoint designs  
✅ Dashboard cards  
✅ Navigation items

### SPACE_EVENLY
✅ Perfectly balanced layouts  
✅ Icon grids  
✅ Menu options  
✅ Gallery previews

### SPACE_AROUND
✅ Visual breathing room  
✅ Card collections  
✅ Feature highlights  
✅ Tag clouds

### START
✅ Header content  
✅ Top-aligned sections  
✅ Notification lists  
✅ Toolbar items

### CENTER
✅ Hero sections  
✅ Splash screens  
✅ Empty states  
✅ Modal dialogs

### END
✅ Footer content  
✅ Action button groups  
✅ Bottom sheets  
✅ Confirmation dialogs

---

## Troubleshooting

| Symptom | Likely cause |
|---------|-------------|
| Items overlapping | Container height is too small for the content |
| Too much empty space | Item heights smaller than expected |
| Uneven spacing with `space_*` | Items have different heights; dynamic strategies distribute space based on remaining room |
| `spaced` looks identical to `start` | Container has `wrap_content` height — no leftover space for spacing to show |

## Tips

1. **Use `spaced` for consistency** — most predictable, fixed gap every time
2. **Use `space_between` for dashboards** — fills all available height nicely
3. **Use `center` for hero sections** — draws the eye to the middle
4. **Use `start`/`end` sparingly** — leaves a large blank area on one side
5. **Pair with `padding`** — use container padding for edge breathing room instead of relying on `space_evenly`/`space_around`
6. **Give containers a fixed height** — dynamic strategies (`space_between`, `space_evenly`, `space_around`, `center`, `end`) have no effect when the container is `wrap_content`
