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

Render the home control inside `Home.ets` only; do not add a second copy through `HdsNavigation.titleBar.content.bottomBuilder`. Keep `Tabs` as the API 26 rounded floating material plate with transparent `barBackgroundColor`, `maskColor`, and `maskHeight`, and `barBottomMargin: 0`; the visible 36vp labels and indicator belong to the custom row above the plate. Keep the project's `targetSdkVersion=26.0.0` and `compatibleSdkVersion=6.1.0(23)` settings; the latter must not be changed back to 6.0.0(23). No HDS Tabs or low-version blur fallback is used for this home control.

For dynamic home labels, place the 36vp custom tab builders in the top host at `statusBarHeight + 56`; set `barWidth` to the available content width and use `BarMode.Scrollable` with `ScrollableBarModeOptions.margin: 16` and `nonScrollableLayoutStyle: LayoutStyle.ALWAYS_AVERAGE_SPLIT`. Native Tabs evenly splits intrinsic tab content while it fits and scrolls the intrinsic single-line items once the constrained bar width is exceeded; do not add host-row padding or manual `layoutWeight`/width overflow branches. Keep `topTabIndex`, `needUpdate`, selected/unselected colors, and content builders. Each custom tab item owns its centered 20x3vp indicator so it stays aligned when the label count changes; animate text state changes for about 180ms and indicator opacity/position for about 280ms with `Curve.Friction`, using component `.animation` rather than global `animateTo`. Keep the page root's top safe-area expansion separate from title-bar content; title-bar tools still avoid the status bar.

The home content host must remain full-size and edge-to-edge; do not add top padding or margin to a wrapper around `bookContentBuilder()` / `podcastContentBuilder()`, because that moves the scroll viewport and prevents scrolling into the status-bar area. Each selected home content component adds the title-bar offset directly to its existing scroll-container top padding: `statusBarHeight + 56 + existingTopPadding`. The `RecentEpisodes` and non-author grid pages use `statusBarHeight + 56 + 36`; `SubHome` (the page containing `继续收听`) and the author grid intentionally use `statusBarHeight + 56 + 31`, five vp tighter; the Add page keeps its existing `36 + 80` baseline. The pages rendered directly inside `MyNavigation` add the status-bar height to their existing title-bar offsets: Local `+69`, Log's first item `+56`, Setting `+56`, and Stats `+(86 or 66)`. This places content below the title bar while the scroll viewport still starts at the top.
