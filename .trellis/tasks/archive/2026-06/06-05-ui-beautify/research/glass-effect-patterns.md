# Research: ArkUI Glass Effect Patterns & API 20 → 23 Compatibility

- **Query**: HarmonyOS ArkUI glass effect (frosted glass / glassmorphism) API patterns and API 20→23 compatibility concerns
- **Scope**: Mixed (internal codebase + external HarmonyOS docs)
- **Date**: 2026-06-05

## Findings

### 1. backgroundBlurStyle with BlurStyle Values

#### BlurStyle Enum (two categories)

**Generic (older) — may be deprecated in future:**
| Member | Usage in project |
|---|---|
| `BlurStyle.Thin` | `Play.ets:1354` — primary button background |
| `BlurStyle.Regular` | *not used* |
| `BlurStyle.Thick` | *not used* |
| `BlurStyle.UltraThick` | *not used* |

**Scene-specific (preferred):**
| Member | Meaning | Usage in project |
|---|---|---|
| `BlurStyle.BACKGROUND_THIN` | Thin blur for backgrounds | *not used* |
| `BlurStyle.BACKGROUND_REGULAR` | Regular blur for backgrounds | *not used* |
| `BlurStyle.BACKGROUND_THICK` | Thick blur for backgrounds | `Component.ets:464,567`, `CollectionDetail.ets:273`, `Add.ets:291` |
| `BlurStyle.BACKGROUND_ULTRA_THICK` | Ultra thick blur for backgrounds | `Play.ets:1309`, `Component.ets:758,816` |
| `BlurStyle.COMPONENT_THIN` | Thin blur for components | *not used* |
| `BlurStyle.COMPONENT_REGULAR` | Regular blur for components | `Component.ets:98`, `Setting.ets:853` (menu backgrounds) |
| `BlurStyle.COMPONENT_THICK` | Thick blur for components | **Most common** — `Component.ets:516,616,704,885`, `LibraryItemDetail.ets:2123`, `Log.ets:193,208,223`, `FilterItems.ets:172`, all tab pages |
| `BlurStyle.COMPONENT_ULTRA_THICK` | Ultra thick blur for components | `Home.ets:289,409` (tab bar) |

**Key rule of thumb:**
- `BACKGROUND_*` — use when blurring behind an image/backdrop (cover backgrounds, full-page backgrounds)
- `COMPONENT_*` — use for UI elements floating above content (buttons, labels, overlays, text labels)

#### backgroundBlurStyle Signature

```typescript
.backgroundBlurStyle(style: Optional<BlurStyle>, options?: BackgroundBlurStyleOptions, sysOptions?: SystemAdaptiveOptions): T
```

**BackgroundBlurStyleOptions** (API 10+):
```typescript
interface BackgroundBlurStyleOptions {
  colorMode?: ThemeColorMode       // LIGHT | DARK | SYSTEM (default)
  adaptiveColor?: AdaptiveColor    // DEFAULT | AVERAGE | PRIMARY
  scale?: number                   // 0.0–1.0, default 1.0
  blurOptions?: BlurOptions        // { grayscale?: number[] } for fine control
  policy?: BlurStyleActivePolicy   // NEW in API 23 — see §3
  inactiveColor?: ResourceColor    // NEW in API 23 — see §3
}
```

**SystemAdaptiveOptions** (NEW 3rd param, API 23):
```typescript
interface SystemAdaptiveOptions {
  disableSystemAdaptation?: boolean  // API 23+
}
```

---

### 2. Glass Card Pattern: shadow + borderRadius + backgroundColor

#### Current Glass Card Pattern in Project

The project already uses a consistent glass card pattern:

**Pattern A — Floating button/overlay (most common):**
```typescript
Button({ type: ButtonType.Circle }) { /* content */ }
  .width(36).height(36)
  .borderRadius(6)
  .backgroundColor(Color.Transparent)   // IMPORTANT: transparent background
  .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)  // blur effect
  .shadow({ radius: 12, color: $r('sys.color.font') })
```
Used in: `LibraryItemDetail.ets:2119-2127`, all tab page "back to top" buttons, `Log.ets` buttons.

**Pattern B — Full-page background blur:**
```typescript
Column() { /* content */ }
  .width('100%').height('100%')
  .backgroundImage(url)
  .backgroundImageSize(ImageSize.FILL)
  .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
  .backgroundBrightness({ rate: 0.2, lightUpDegree: 0.1 })
```
Used in: `Play.ets:1303-1313` (full player background).

**Pattern C — Overlay label on image (name label):**
```typescript
Column() { /* Text(name) */ }
  .width(width)
  .padding(3)
  .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)  // or COMPONENT_THICK
```
Used in: `Component.ets:756-758` (AuthorComponent name overlay).

**Pattern D — Single-image backdrop blur (for stacks with 1 item):**
```typescript
Column() { /* Image */ }
  .width('100%').height('100%')
  .backgroundImage(url)
  .backgroundImageSize(ImageSize.FILL)
  .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
```
Used in: `Component.ets:462-464` (SeriesItemComponent single-book), `Component.ets:565-567`, `CollectionDetail.ets:270-273`.

**Pattern E — border-radius + clip pattern:**
```typescript
Column() { /* content */ }
  .borderRadius(10)
  .clip(true)       // clips the blur to the border radius
```
Used in: `Component.ets:486-488, 518-519, 706-707, 760-761, 818-819`.

Key observation: **Every glass card uses `.clip(true)` after `.borderRadius(...)`** — this is essential for blending the blur within rounded corners to avoid overflow.

---

### 3. BlurStyleActivePolicy with inactiveColor

#### What It Is

`BlurStyleActivePolicy` was added in **API 23** (6.1.0). It controls how blur material responds to window active/inactive state.

**Enum values:**
| Value | Description |
|---|---|
| `FOLLOWS_WINDOW_ACTIVE_STATE` (0) | Blur adapts: active = full blur, inactive = `inactiveColor` fallback |
| `ALWAYS_ACTIVE` (1) | Blur always shows at full effect regardless of window state |
| `ALWAYS_INACTIVE` (2) | Blur always shows the inactive state |

#### Usage in Project

Already used in `Home.ets:289-292, 409-412`:
```typescript
.barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
  policy: BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE,
  inactiveColor: $r('sys.color.ohos_id_color_hover')
})
```

There's also a commented-out example at `Home.ets:443-446` that shows the same pattern for `backgroundBlurStyle`.

**Note:** This API requires API 23+ at compile time. If `compatibleSdkVersion` stays at 20, the `policy` option won't cause a runtime crash on API 20 devices (it's an optional field that gets ignored), but it may cause a compile warning if the SDK's lint rules flag it.

#### Which Components Support It

- `backgroundBlurStyle(style, options)` — options accept `policy` and `inactiveColor` from API 23
- `barBackgroundBlurStyle(style, options)` — for Tabs bar
- `menuBackgroundBlurStyle(style, options)` — for Select/ContextMenu
- `backgroundEffect(options)` — also supports `policy` and `inactiveColor` from API 23

---

### 4. backgroundEffect API (Alternative to backgroundBlurStyle)

Available from API 19+ (6.0.0 Beta1+). Provides more granular control:

```typescript
.backgroundEffect({
  radius: 60,           // blur radius in vp
  saturation: 0,        // 0 = desaturate, 1 = full
  brightness: 1,        // 0–1 brightness adjustment
  color: Color.White,   // tint color overlay
  blurOptions: { grayscale: [20, 20] },  // fine control
  policy?: BlurStyleActivePolicy,
  inactiveColor?: ResourceColor
})
```

This is a newer, more flexible API. The current project uses `backgroundBlurStyle` everywhere, but `backgroundEffect` could be used for custom blur effects not covered by BlurStyle presets.

---

### 5. Existing Glass Card Visual Patterns Summary

| File | Component | Pattern | BlurStyle | BorderRadius | Shadow |
|---|---|---|---|---|---|
| `Component.ets` | `SeriesItemComponent` | Bkg blur on single-image stack | `BACKGROUND_THICK` | 10 | Offset shadow on stacked images |
| `Component.ets` | `SeriesItemComponent` name label | Overlay | `COMPONENT_THICK` | — | — |
| `Component.ets` | `CollectionItemComponent` | Bkg blur on single-image stack | `BACKGROUND_THICK` | 10 | Offset shadow on stacked images |
| `Component.ets` | `PlaylistItemComponent` name | Overlay | `COMPONENT_THICK` | — | — |
| `Component.ets` | `AuthorComponent` name | Overlay | `BACKGROUND_ULTRA_THICK` | — | — |
| `Component.ets` | `AuthorComponent1` name | Overlay | `BACKGROUND_ULTRA_THICK` | 10 | — |
| `Component.ets` | `RecentEpisodeComponent` label | Overlay badge | `COMPONENT_THICK` | 5 | — |
| `Component.ets` | `titleBarBuilder` Select menu | Menu | `COMPONENT_REGULAR` | 8 | — |
| `Component.ets` | `pageUpDown` buttons | Solid bkg (needs glass) | *none* | 5 | *none* |
| `LibraryItemDetail.ets` | Scroll-to-top button | Floating circle | `COMPONENT_THICK` | 6 | radius=12 |
| `Log.ets` | Select + Buttons | Floating | `COMPONENT_THICK` | — | radius=12 |
| `Play.ets` | Full page bg | Full backdrop | `BACKGROUND_ULTRA_THICK` | — | — |
| `Play.ets` | Primary button | Floating circle | `Thin` | circle | radius=8 |
| `Home.ets` | Tab bar | Bar | `COMPONENT_ULTRA_THICK` | — | — |
| `Add.ets` | Search bar | Bkg blur | `BACKGROUND_THICK` | 8 | — |
| All tab pages | Scroll-to-top | Floating circle | `COMPONENT_THICK` | 6 | radius=12 |

---

### 6. API 20 → 23 Compatibility Concerns

#### Current Configuration
```json5
// build-profile.json5 (current)
"targetSdkVersion": "6.0.0(20)",
"compatibleSdkVersion": "6.0.0(20)",

// Target (per PRD)
"targetSdkVersion": "6.1.0(23)",   // changed
"compatibleSdkVersion": "6.0.0(20)"  // stays the same for backward compat
```

#### Changes Between API 20 and API 23 Relevant to This Project

**A. BlurStyleActivePolicy (NEW in API 23)**
- Added `BlurStyleActivePolicy` enum with `FOLLOWS_WINDOW_ACTIVE_STATE`, `ALWAYS_ACTIVE`, `ALWAYS_INACTIVE`
- Added `policy` and `inactiveColor` to `BackgroundBlurStyleOptions`
- Added `policy` and `inactiveColor` to `BackgroundEffectOptions`
- Already used in `Home.ets` — will compile fine with API 23
- On API 20 devices, these options are ignored (no runtime crash)

**B. backgroundBlurStyle / backgroundEffect 3rd parameter (NEW in API 23)**
- Added optional 3rd parameter `sysOptions?: SystemAdaptiveOptions` to:
  - `backgroundBlurStyle(style, options?, sysOptions?)`
  - `backgroundEffect(options, sysOptions?)`
  - `foregroundBlurStyle(style, options?, sysOptions?)`
  - `blur(radius, options?, sysOptions?)`
  - `backdropBlur(radius, options?, sysOptions?)`
- Not currently used in project — no migration needed

**C. Navigation title/toolbar blur options (NEW in API 23)**
- `NavigationTitleOptions` added: `backgroundBlurStyleOptions`, `backgroundEffect`
- `NavigationToolbarOptions` added: `backgroundBlurStyleOptions`, `backgroundEffect`, `moreButtonOptions`
- `NavigationMenuOptions` added: `moreButtonOptions` with `backgroundBlurStyle`
- Relevant for `Component.ets` MyNavigation title bar enhancement (PRD §11)

**D. SheetOptions additions (API 23)**
- `SheetOptions` added: `showInSubWindow` (optional boolean)
- Not used in project — no impact

**E. ActionSheet / AlertDialog deprecation (API 26, not 23)**
- `ActionSheet` and `AlertDialog` classes deprecated at API 26 (future version)
- No immediate action needed for API 23 migration

**F. `barBackgroundBlurStyle` starting version change**
- From API 15 → API 18 (documentation-only, no code impact)

**G. ScrollPage parameter type change (API 23)**
- `Scroller.scrollPage(value: { next: boolean })` → `scrollPage(value: ScrollPageOptions)`
- `ScrollPageOptions` adds `animation` field
- Used in `Component.ets:2170,2184` as `scrollPage({ next: false/true, animation: true })` — already compatible with new type

#### APIs That Are NOT Breaking (Same Signature)

From the ArkUI API diff analysis, the following APIs used by this project have **no signature changes** between API 20 and 23:
- `shadow()` — unchanged
- `borderRadius()` — unchanged
- `backgroundImage()` / `backgroundImageSize()` — unchanged
- `backgroundBrightness()` — unchanged
- `clip()` — unchanged
- `backgroundColor` — unchanged
- `BlurStyle` enum values — unchanged (only added `BlurStyleActivePolicy`)
- `menuBackgroundBlurStyle` — unchanged
- `SymbolGlyph` — unchanged
- `HdsTabs` / `HdsNavigation` (framework components) — unaffected

#### No Deprecated APIs Requiring Immediate Migration

Based on the ArkUI API diff files for API 23:
- No APIs currently used by this project have been deprecated in API 23
- The `BlurStyle.Thin` usage at `Play.ets:1354` is the older generic enum style but is NOT deprecated — both generic and scene-specific variants coexist

---

### 7. Best Practices for Glass Cards (HarmonyOS ArkUI)

1. **Always pair with `.clip(true)`** — blur overflow beyond border radius looks broken
2. **Use `Color.Transparent` as backgroundColor** when using `backgroundBlurStyle` (they conflict if both are non-transparent)
3. **Match BlurStyle to context:**
   - `COMPONENT_THICK` — standard frosted glass for interactive elements (buttons, overlays)
   - `BACKGROUND_THICK/BACKGROUND_ULTRA_THICK` — full background blur (page backgrounds, large backdrops)
   - `COMPONENT_ULTRA_THICK` — strongest separation, good for navigation bars
4. **Shadow helps depth** — use `.shadow({ radius, color })` alongside blur for the "floating" glass effect
5. **For cover images** — use `backgroundImage(url)` + `backgroundImageSize(FILL)` + `backgroundBlurStyle(BACKGROUND_THICK)` as a blurred backdrop, then overlay the actual image
6. **backgroundBrightness** — controls brightness overlay on blurred backgrounds; useful for readability over blurred images (see `Play.ets:1310-1313`)
7. **API 23 BlurStyleActivePolicy** — use `FOLLOWS_WINDOW_ACTIVE_STATE` with `inactiveColor` for elements that should dim when the window is inactive (e.g., tab bars, persistent overlays)

---

### Files Referenced

| File | Description |
|---|---|
| `entry/src/main/ets/utils/Component.ets` | Principal glass card components (LibraryItemComponent, SeriesItemComponent, CollectionItemComponent, PlaylistItemComponent, AuthorComponent, RecentEpisodeComponent, pageUpDown) |
| `entry/src/main/ets/pages/Play.ets` | Full-page background blur with brightness, primary button with `BlurStyle.Thin` |
| `entry/src/main/ets/pages/Home.ets` | `barBackgroundBlurStyle` with `BlurStyleActivePolicy` |
| `entry/src/main/ets/pages/Log.ets` | Floating buttons with COMPONENT_THICK + shadow |
| `entry/src/main/ets/pages/LibraryItemDetail.ets` | Scroll-to-top button glass pattern |
| `entry/src/main/ets/pages/CollectionDetail.ets` | Background blur on cover stack |
| `entry/src/main/ets/pages/tabs/*.ets` | All tab page "back to top" buttons |
| `entry/src/main/ets/pages/tabs/Add.ets` | Search bar with background blur + brightness |
| `entry/src/main/ets/pages/Setting.ets` | Select menuBackgroundBlurStyle |
| `entry/src/main/ets/pages/FilterItems.ets` | backgroundBlurStyle usage |
| `build-profile.json5` | Current API version config |

### External References

- [HarmonyOS ArkUI Blur Effect Guide](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-blur-effect) — official blur/glass effect documentation
- [backgroundBlurStyle API Reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-background#backgroundblurstyle9) — official API docs
- [HarmonyOS 6.1.0(23) Version Overview](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-610) — API 23 release notes
- [ArkUI API Diff (API 23 Beta2)](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/js-apidiff-arkui-6102) — detailed API changes between versions
- [HarmonyOS 6.0.0(20) Release Notes](https://developer.huawei.com/consumer/cn/doc/atomic-releases/atomic-releasenotes-600) — API 20 release notes

### Caveats

- `BlurStyleActivePolicy` (used in `Home.ets`) is **only available with API 23 SDK**. When compiling with API 23 as target and API 20 as compatible, it will compile fine. At runtime on API 20 devices, the `policy` option is silently ignored.
- `BlurStyle.Thin` at `Play.ets:1354` is the older-style enum member. Consider migrating to `BlurStyle.COMPONENT_THIN` or `BlurStyle.COMPONENT_REGULAR` for consistency, though it's not deprecated.
- The `pageUpDown` component (`Component.ets:2154-2190`) currently uses solid `backgroundColor($r('sys.color.ohos_id_color_button_normal'))` with no blur — this is one of the targets for glass effect enhancement per the PRD.
- `backgroundEffect()` (API 19+) is an alternative to `backgroundBlurStyle` that offers more granular control (radius, saturation, brightness, color). It also supports `policy`/`inactiveColor` from API 23. Consider it for custom glass effects that don't fit the BlurStyle presets.
