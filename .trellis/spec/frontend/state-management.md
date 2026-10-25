# State Management

## Architecture

The app uses ArkUI's V2 state management (`@ObservedV2` / `@ComponentV2`).

### Global state (via @Provider / @Consumer)

`Index.ets` acts as the global state hub. State classes are:

| Class | Provider key | Consumer type | Persistence |
|-------|-------------|---------------|-------------|
| `ServerIndex` | `serverIndex` | optional | `PersistenceV2.connect()` |
| `ServerSetting` | `serverSetting` | optional | `PersistenceV2.connect()` |
| `ColorMode` | `colorMode` | optional | `PersistenceV2.connect()` |
| `PlaySetting` | `playSetting` | optional | `PersistenceV2.connect()` |
| `OtherSetting` | `otherSetting` | optional | `PersistenceV2.connect()` |
| `DownloadSetting` | `downloadSetting` | optional | `PersistenceV2.connect()` |
| `ProjectSkipSettings` | `projectSkipSettings` | optional | `PersistenceV2.connect()` |

Primitives (simple `@Provider` decorated fields):
- `displayWidth`, `displayHeight`, `isPlaying`, `showPlay`, `playingItem`, etc.
- Accessed via `@Consumer` in child components

### Cross-component data flow

```
Index.ets (Provider)
  └─ Play.ets (Consumer)
  └─ Setting.ets (Consumer)
  └─ Home.ets (Consumer)
     └─ tabs/*.ets (Consumer)
```

### @Local component state

- Used for UI-only state: `isSyncing`, `sliderMoving`, `playerState`, etc.
- NOT persisted across sessions
- Not visible to parent/child components

## Conventions

- Use `@Trace` on fields that need reactive UI updates
- Use `PersistenceV2.connect(Class, () => new Class())` for persisted state
- Use `@Local` for non-reactive or local-only state
- Use `@Consumer() var | undefined = undefined` with optional chaining (`?.`)
- Mutate `@Provider` state from anywhere via direct assignment: `this.playSetting.fadeInOut = true`

## Home tab synchronization

The root `Index.ets` owns `topTabIndex`, so the home tab control in `Home.ets` must use that shared value. Keep the dynamic label rules in one exported helper and use the same index for the custom label row and the content builders.

```ts
Stack() {
  Tabs({ barPosition: BarPosition.End, index: this.topTabIndex }) {
    // Empty custom tab bars keep Tabs as the immersive material plate only.
  }
  .barOverlap(true)
  .vertical(false)
  .barWidth(this.homeTabContentWidth())
  .barHeight(36)
  .barBackgroundColor(Color.Transparent)
  .barFloatingStyle({
    barBottomMargin: 0,
    maskColor: Color.Transparent,
    maskHeight: 0,
    systemMaterial: new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      applyShadow: false,
      interactive: true,
      lightEffect: { color: Color.White }
    })
  })

  // 36vp custom tab builders use intrinsic single-line label widths; native Tabs decides whether to split or scroll.
  // Each custom tab item owns a centered 20x3vp indicator and uses Curve.Friction.
}
```

Render the home control inside `Home.ets` only; do not add a second copy through `HdsNavigation.titleBar.content.bottomBuilder`. Keep `Tabs` as the API 26 rounded floating material plate with transparent `barBackgroundColor`, `maskColor`, and `maskHeight`, and `barBottomMargin: 0`; the visible 36vp labels and indicator belong to the custom row above the plate. Keep the project's `targetSdkVersion=26.0.0` and `compatibleSdkVersion=26.0.0` settings. Since API 26 is the minimum runtime, do not add API-version guards or low-version fallbacks for this home control. No HDS Tabs is used for this home control.

For dynamic home labels, place the 36vp custom tab builders in the top host at `statusBarHeight + 56`; set `barWidth` to the available content width and use `BarMode.Scrollable` with `ScrollableBarModeOptions.margin: 16` and `nonScrollableLayoutStyle: LayoutStyle.ALWAYS_AVERAGE_SPLIT`. Native Tabs evenly splits intrinsic tab content while it fits and scrolls the intrinsic single-line items once the constrained bar width is exceeded; do not add host-row padding or manual `layoutWeight`/width overflow branches. Keep `topTabIndex`, `needUpdate`, selected/unselected colors, and content builders. Each custom tab item owns its centered 20x3vp indicator so it stays aligned when the label count changes; animate text state changes for about 180ms and indicator opacity/position for about 280ms with `Curve.Friction`, using component `.animation` rather than global `animateTo`. Keep the page root's top safe-area expansion separate from title-bar content; title-bar tools still avoid the status bar.

The home content host must remain full-size and edge-to-edge; do not add top padding or margin to a wrapper around `bookContentBuilder()` / `podcastContentBuilder()`, because that moves the scroll viewport and prevents scrolling into the status-bar area. Each selected home content component adds the title-bar offset directly to its existing scroll-container top padding: `statusBarHeight + 56 + existingTopPadding`. The `RecentEpisodes` and non-author grid pages use `statusBarHeight + 56 + 36`; `SubHome` (the page containing `继续收听`) and the author grid intentionally use `statusBarHeight + 56 + 31`, five vp tighter; the Add page keeps its existing `36 + 80` baseline. The pages rendered directly inside `MyNavigation` add the status-bar height to their existing title-bar offsets: Local `+69`, Setting `+56`, and Stats `+(86 or 66)`. Log is now a nested `NavPathStack` destination from Settings and keeps its existing first-item `+56` offset; its title bar displays `日志`, while the filter `Select` uses API 26 `systemMaterial` and copy/share remain title-bar menu actions. This places content below the title bar while the scroll viewport still starts at the top.

When the main navigation `pageIndex` changes, preserve every page scroller's current position. Do not add `pageIndex` monitors that call `scrollEdge` or otherwise reset vertical `Scroll`/`Grid`/`List` instances or Home's horizontal lists; switching bottom Tabs or the desktop side menu must not unexpectedly move the user's viewport. Data-loading monitors must likewise leave scroll positions unchanged.

### Home content identity and transitions

The selected home page must be rendered from `Home.build()` through the existing `bookContentBuilder()` / `podcastContentBuilder()` methods, and those builders must read the reactive `@Consumer topTabIndex` directly. Do not pass the index through an intermediate parameterized Builder: ArkUI V2 can retain that value as a construction-time snapshot, so the visible page never changes. Also do not use `ForEach([this.topTabIndex], ...)` with the tab index as the key or attach `TransitionEffect` to a dynamically keyed grid host: API 26 can destroy/recreate the `Grid` subtree and leave the newly selected grid invisible. Keep page-switch animation on the native `Tabs` bar (and the bottom navigation `Tabs`) unless a replacement transition is verified on device.

## Device-specific main navigation

`Index.ets` and `utils/Component.ets` share one `getMainNavigationItems()` definition for the four main labels and symbols: 首页/`house`, 统计/`arrow_counterclockwise_clock`, 本地/`folder`, and 设置/`slider_vertical_3`. On `phone` and `tablet`, bypass `HdsSideBar` and render those items as a bottom `Tabs` bar using API 26 `barFloatingStyle` with `ImmersiveMaterial`; changing the tab updates the provider `pageIndex` and clears `pageInfos` just like the sidebar selection. The bottom tab's selected symbol/text use `sys.color.comp_emphasize_secondary`, matching the Home underline; unselected symbol/text use `sys.color.font_secondary`, matching the Home unselected label. Omit only the `open_sidebar` title-bar action on these devices. Keep the existing `HdsSideBar`, title-bar action, and content layout for `2in1` and other desktop device types. The Log page is reached from a Log entry immediately above About in `Setting.ets` through the same `NavPathStack`.

## Bottom tab content avoidance

The mobile/tablet bottom-content avoidance baseline is `75vp`, plus the bottom tab's `16vp` floating bottom margin. Root `Scroll`, `List`, and `Grid` content, plus mobile floating controls that can overlap the bar, must use `getBottomContentInset(desktopInset)` from `utils/Layout.ets` for their final bottom padding or margin. On `phone` and `tablet` this returns at least `91vp`; on `2in1` and desktop it returns the supplied desktop inset unchanged. Existing playback-state insets larger than `91vp` remain the effective value.

Do not apply this helper to internal card, dialog, or nested component padding unless that component itself owns the page's final scroll viewport. The last root item must receive the inset so the user can scroll it completely above the floating tab bar.
