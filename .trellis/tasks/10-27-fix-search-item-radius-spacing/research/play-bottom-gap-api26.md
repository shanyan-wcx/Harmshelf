# Research: Play foreground bottom gap and lower-cover sizing

- Query: Explain the remaining bottom gap in `Play.ets` after commit `7e4bc0d`/current `HEAD`, verify the API-26 navigation-indicator value and safe-area modifiers, and determine how the lower cover can fill its region without distortion or crop.
- Scope: internal + local HarmonyOS API 26 documentation
- Date: 2026-11-05

## Findings

### Files found and code patterns

- `entry/src/main/ets/pages/Play.ets:900-915`: the lower background is a `Column` with `height('100%')`, `backgroundImageSize(ImageSize.FILL)`, and both `ignoreLayoutSafeArea(BOTTOM)` and `expandSafeArea(BOTTOM)`.
- `Play.ets:917-1223`: the foreground control `Column` has `layoutWeight(1)` and `justifyContent(FlexAlign.SpaceBetween)`, but its parent is the `Stack` at line 900. API-26 `common.d.ts:17448-17462` says `layoutWeight` allocates along the main axis only for `Row`, `Column`, or `Flex`; it has no sizing effect in a `Stack`. The foreground therefore remains intrinsic-height unless it receives an explicit height, so its bottom padding is not a full lower-region layout contract. Restore an explicit `height('100%')` (or another parent-sized height) on this foreground `Column` before using `justifyContent(SpaceBetween)` to distribute controls through the lower region.
- `Play.ets:1224-1234`: the lower background/foreground `Stack` is the weighted child of the outer `Column`, so its `layoutWeight(1)` is effective there. The ineffective weight is the one on the foreground `Column` inside the `Stack`.
- `Play.ets:1286-1290`: current root uses `height(LayoutPolicy.matchParent)` with `ignoreLayoutSafeArea(SYSTEM, [TOP, BOTTOM])`; this matches the API-26 immersive guidance. The earlier `height('100%')` did not satisfy the documentation's explicit `matchParent` requirement for changing both size and position.
- `Play.ets:1227-1229`: `@Env(SystemProperties.WINDOW_AVOID_AREA)` supplies `UIEnvWindowAvoidAreaInfoVP`; the padding expression is already in vp and should not be converted again.

### Safe-area conclusions

- API-26 `common.d.ts:17200-17263` defines `expandSafeArea` as a rendering/drawing extension that does not change layout size; it requires the component boundary to overlap the target safe area. `common.d.ts:17265-17298` defines `ignoreLayoutSafeArea` as a layout extension, with `.ignoreLayoutSafeArea` taking effect before `.expandSafeArea` when both are present.
- API-26 `common.d.ts:715-731` and `:833-874` state that `ReadonlyEnvKey.WINDOW_AVOID_AREA` / `SystemProperties.WINDOW_AVOID_AREA` expose window avoid areas measured in vp. `@ohos.window.d.ts:850-885` defines `navigationIndicator.bottomRect` as the bottom rectangle in vp, and `:1618-1647` maps it into `UIEnvWindowAvoidAreaInfoVP`. Therefore `navigationIndicator.visible ? navigationIndicator.bottomRect.height : 0` is the correct navigation-indicator-only inset, not a px value and not a system-bar total.
- The background does not need `ignoreLayoutSafeArea(BOTTOM)` merely to paint behind the navigation indicator. `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` is the appropriate rendering modifier. Keeping layout-ignore on this background can move its layout position because its height is not `LayoutPolicy.matchParent`; it is redundant for a visual-only sibling and can make alignment harder to reason about. The root's `matchParent` + bottom layout ignore is the layout prerequisite; the foreground owns the explicit navigation padding.
- The expected bottom blank space inside the foreground is the navigation-indicator inset. If the observed gap is substantially larger, first remove the non-effective foreground `layoutWeight` assumption and give that `Column` the full Stack height; do not increase or re-convert `bottomRect.height`. A device with no visible navigation indicator should produce zero padding from this expression.

### Lower-cover sizing

- API-26 `component/enums.d.ts:2427-2467` defines `ImageSize.FILL` as scaling without preserving aspect ratio to fill the boundary, so the current lower background is necessarily distorted whenever the cover and lower region have different aspect ratios.
- The same declaration defines `ImageSize.Cover` as preserving aspect ratio while filling (therefore cropping when ratios differ), and `ImageSize.Contain` as preserving aspect ratio while displaying the complete image inside the boundary (therefore leaving unused/letterboxed space when ratios differ). No single image-fit mode can fill an arbitrary non-square lower region while simultaneously preserving the complete source and its aspect ratio.
- If “no distortion and no crop” is absolute, use an aspect-preserving `Contain` image in a host whose aspect ratio matches the cover, and fill the remaining lower-region pixels with a separate blurred/color layer. If the lower layer is decorative and crop is acceptable, `Cover` is the correct non-distorting full-bleed choice. The primary square cover at `Play.ets:828-851` should remain `ImageFit.Contain`; the separate 96vp decorative copy at `Play.ets:854-895` is independently cropped by `ImageFit.Cover` and cannot be made both full-bleed and uncropped without changing its host geometry.

### External references / versions

- Installed SDK: `C:\Program Files\Huawei\DevEco Studio\sdk\default\sdk-pkg.json` reports API `26`, HarmonyOS `26.0.0`, SDK `26.0.0.105`.
- Local API declarations: `openharmony/ets/component/common.d.ts`, `openharmony/ets/component/enums.d.ts`, and `openharmony/ets/api/@ohos.window.d.ts`.
- `devecocli docs read API参考/ArkUI_方舟UI框架/ArkTS组件/通用属性/布局与边框/安全区域/ts-universal-attributes-expand-safe-area` confirms that `ignoreLayoutSafeArea` + `height(LayoutPolicy.matchParent)` expands page layout, while `expandSafeArea` extends only drawing. The local immersive-window guide recommends `TYPE_NAVIGATION_INDICATOR` bottom padding for content avoidance.

### Related specs

- `.trellis/spec/frontend/directory-structure.md`: `Play.ets` owns the full-screen player UI.
- `.trellis/spec/frontend/state-management.md`: `Play.ets` is a V2 component; the environment value can stay local and does not require new provider state.
- `.trellis/spec/frontend/component-guidelines.md`: existing visual/component conventions remain unaffected by this geometry-only safe-area correction.

## Caveats / Not Found

- No device or emulator is connected (`devecocli device list` reported none), so the exact runtime gap in vp could not be measured or screenshot-verified.
- The lower-region aspect ratio varies by window size/orientation; a strict no-crop/no-distortion result requires a layered design or a host aspect-ratio decision, not a different single `ImageSize` enum.
- `rtk` is not installed in this shell; read-only PowerShell/`rg` and `devecocli docs` commands were used. No production source was changed and no Git commit was made.
