# Use bottom immersive tabs on phone and tablet

## Goal

Use a bottom floating tab bar with immersive light material as the main navigation on phone and tablet. Keep the existing sidebar navigation and title-bar behavior unchanged for PC/2-in-1 devices. The new mobile tabs must use the same four symbols and labels as the current main navigation and stay synchronized with the shared page index; Log remains available from Settings above About.

## Confirmed facts

- `build-profile.json5` targets SDK `26.0.0` and declares `compatibleSdkVersion` `26.0.0`.
- API 26 is the project's minimum compatible runtime, so direct `Tabs.barFloatingStyle()` and `uiMaterial.ImmersiveMaterial` usage is valid without compatibility guards.
- The current main navigation is defined by four items: 首页/house, 统计/arrow_counterclockwise_clock, 本地/folder, 设置/slider_vertical_3. Log is available from Settings immediately above About.
- Local SDK declarations mark `barFloatingStyle`, `FloatingTabBarStyle`, `uiMaterial.ImmersiveMaterial`, `uiMaterial.ImmersiveStyle`, and its material options as API 26.0.0 features.
- `utils/Component.ets` owns `HdsNavigation`, title-bar actions, and page rendering; `Index.ets` owns the outer sidebar container and shared page index.
- The user's current Home changes are `.barHeight('auto')` and removal of `ScrollableBarModeOptions.margin`; both are intentional and must remain unchanged.

## Requirements

1. On `phone` and `tablet`, bypass the `HdsSideBar` container and render navigation through a bottom floating `Tabs` bar.
2. Configure the mobile tab bar with API 26 immersive material and transparent mask/background settings.
3. Render each of the four tabs as symbol + text using the existing main-navigation symbols and labels; changing a tab updates `pageIndex` and clears the navigation stack as before.
4. Hide the title-bar `open_sidebar` action only on phone/tablet.
5. Keep PC/2-in-1 sidebar layout, title-bar actions, and page rendering unchanged.
6. Use `sys.color.comp_emphasize_secondary` for selected bottom-tab symbol/text and `sys.color.font_secondary` for unselected symbol/text, matching the Home underline and unselected label.
7. Preserve the API 26 minimum configuration and the existing home tab behavior, animations, colors, and data synchronization.

## Acceptance Criteria

- [ ] Phone/tablet render four bottom floating tabs with immersive light material.
- [ ] Mobile tab symbols and labels match the current sidebar exactly.
- [ ] Selected and unselected mobile tab colors match the Home underline and unselected label respectively.
- [ ] Mobile tab selection updates the same `pageIndex` used by page content and clears nested navigation.
- [ ] The mobile title bar has no sidebar button; search/download actions remain available.
- [ ] PC/2-in-1 retain the existing `HdsSideBar` and title-bar sidebar behavior.
- [ ] API 26-compatible debug build succeeds and `git diff --check` passes.

## Out of scope

- No change to `targetSdkVersion` or `compatibleSdkVersion` after the API 26 baseline update.
- No changes to media APIs, request APIs, or PC/2-in-1 sidebar behavior.
- No new dependency or separate navigation state is introduced.
