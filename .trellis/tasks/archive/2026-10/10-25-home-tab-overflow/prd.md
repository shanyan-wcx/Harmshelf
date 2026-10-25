# Fix narrow home tab layout

## Goal

Make the home content tab bar stable on narrow screens: up to five tabs evenly fill the constrained bar, while additional tabs keep a readable single-line width and can be reached by horizontal scrolling instead of being squeezed or pushed below the bar.

## Confirmed facts

- `entry/src/main/ets/pages/Home.ets` owns the home content `Tabs` and derives labels from `getHomeTabLabels()`.
- `播放列表` is conditionally appended as the last label when playlists exist; admin/book combinations can produce six labels.
- The current implementation decides overflow from measured label width and always uses `BarMode.Scrollable` with `LayoutStyle.ALWAYS_AVERAGE_SPLIT`. Its custom tab builder also switches between `layoutWeight(1)` and a fixed max-label width, while the host Row supplies the 16vp side spacing through `padding`.
- The DevEco Tabs documentation states that `barWidth` limits the TabBar width, `BarMode.Scrollable` uses actual tab widths and scrolls when the total exceeds `barWidth`, `ScrollableBarModeOptions.margin` supplies the horizontal TabBar margins, and `LayoutStyle.ALWAYS_AVERAGE_SPLIT` evenly splits the TabBar while its content fits.
- Existing home tab synchronization uses the shared `topTabIndex` and `needUpdate`; this task must preserve it. The existing 36vp height, underline, immersive material, animation, and `fadingEdge(true)` are also preserved.

## Requirements

1. Keep `BarMode.Scrollable` with `nonScrollableLayoutStyle: LayoutStyle.ALWAYS_AVERAGE_SPLIT` so content that fits is evenly split and content that exceeds the constrained bar can scroll.
2. Set the native `Tabs.barWidth` to constrain the TabBar to the home content width instead of relying on the host Row's horizontal padding.
3. Set `ScrollableBarModeOptions.margin` to the existing 16vp left/right spacing and remove the host Row `padding` used for that spacing.
4. Let each custom tab item use its intrinsic single-line label width; native `ALWAYS_AVERAGE_SPLIT` must evenly distribute the items while they fit and let the extra items scroll once the constrained `barWidth` is exceeded.
5. Keep the existing dynamic label order, `topTabIndex`/`needUpdate` synchronization, selected underline and colors, 36vp height, immersive styling, animation, fading edge setting, and title-bar spacing unchanged.

## Out of scope

- No changes to the tab labels, page content components, bottom navigation, title-bar tools, or other pages.
- No replacement of the native `Tabs` component or addition of a separate `Scroll`/`Row` tab implementation.
- No API compatibility change; the project remains target SDK 26 with compatible SDK 6.1.0 (23).

## Acceptance Criteria

- [ ] With four labels, all four tab slots are on one row and evenly divide the constrained TabBar width.
- [ ] With five labels, all five tab slots are on one row and evenly divide the constrained TabBar width.
- [ ] With six or more labels on a narrow screen, the first five remain correctly laid out and the sixth/overflow items stay on one row, remain single-line, and can be reached by horizontal scrolling.
- [ ] Selecting any tab still updates the displayed home content through the existing shared index and preserves the selected underline alignment.
- [ ] Existing tab height, immersive appearance, fading edge, animation, 16vp margin, and title-bar position remain unchanged.
- [ ] Static checks show no whitespace errors and the diff is limited to the home tab layout implementation plus task artifacts.

## Validation plan

- Inspect the final diff and run `git diff --check`.
- Run the project API 23 debug HAP build when the user requests or permits build verification.
- If a device/emulator is available, verify 4-, 5-, and 6-tab states on a narrow window; otherwise report visual validation as deferred.
