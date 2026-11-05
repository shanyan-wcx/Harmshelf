# Research: Navigation-only bottom avoidance with an expanded background

- Query: Find bottom safe-area APIs that protect controls from the navigation indicator while allowing the player background to reach the window edge.
- Scope: internal + local HarmonyOS documentation / SDK
- Date: 2026-11-05

## Findings

### Files found and code patterns

- `entry/src/main/ets/pages/Play.ets:898-912`: lower background is a separate 100%-sized Column with `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` already present.
- `Play.ets:914-1231`: controls are a separate foreground Column; the final controls Column uses layoutWeight and SpaceBetween, so its bottom follows its parent's available height.
- `Play.ets:1281-1285`: root uses width/height 100%, ignores TOP layout safe area and expands TOP rendering safe area. It does not explicitly ignore BOTTOM layout safe area.
- `Play.ets:1330`: builder is shown using bindContentCover. `Play.ets:1427`: collapsed action bar has bottom margin 108; do not reuse this mini-player offset as the full-screen navigation inset.
- `entry/src/main/ets/entryability/EntryAbility.ets:47`: main window enables full-screen layout.
- `entry/src/main/ets/pages/Index.ets:302-305`: existing window-avoid-area pattern gets TYPE_SYSTEM.topRect.height and converts px with UIContext.px2vp.
- SDK root `C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/`: `component/common.d.ts:17200-17298` defines expand/ignore behavior; `:823,858` supports Env + SystemProperties.WINDOW_AVOID_AREA; `api/@ohos.window.d.ts:1618-1647` defines VP environment data, including navigationIndicator.

### API distinctions

- `.expandSafeArea(...)` extends drawing without enlarging the original layout area. Apply BOTTOM expansion to the background, not the interactive control subtree. Expansion requires the component edge to meet the relevant safe-area boundary; arbitrary middle-of-page nodes cannot expand to the window bottom.
- `.ignoreLayoutSafeArea(...)` changes layout safe areas, including inherited component safeAreaPadding. With `.height('100%')`, ignoring an edge can change position without changing height; `.height(LayoutPolicy.matchParent)` is the documented option when size must expand too.
- `LayoutSafeAreaType.SYSTEM` includes component-level and page-level safe areas. It does **not** mean “navigation indicator only.” `SafeAreaType.SYSTEM` includes status and navigation areas; BOTTOM restricts the edge.
- `window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR` identifies the navigation indicator. Do not use TYPE_SYSTEM.topRect, displayHeight minus statusBarHeight, a fixed 20/34/108vp, or the app's bottom tab height for this purpose.

### Exact recommendation: retain automatic bottom avoidance when sufficient

Keep the existing root TOP-only ignore/expand modifiers, leave controls inside the bottom layout safe area, and retain this on the separate background:

```typescript
.width('100%')
.height('100%')
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
```

Add **0vp** of manual navigation padding in this mode. This is the smallest choice when the layout already avoids only the system bottom inset. Do not combine automatic avoidance and a second measured inset.

### Exact recommendation: opt out of inherited bottom avoidance, then protect controls only

If the unwanted bottom gap is inherited component padding, use this alternative as a complete pair, not a standalone modifier:

```typescript
// Full-screen player's root; preserve the existing top visual behavior.
.width('100%')
.height(LayoutPolicy.matchParent)
.ignoreLayoutSafeArea(
  [LayoutSafeAreaType.SYSTEM],
  [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM]
)
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
```

Use API 23+ environment data in the existing ComponentV2 (supported by installed/project API 26), with `window` imported from `@kit.ArkUI`:

```typescript
@Env(SystemProperties.WINDOW_AVOID_AREA)
windowAvoidArea: window.UIEnvWindowAvoidAreaInfoVP;
```

Apply **only to the foreground controls Column**:

```typescript
.padding({
  bottom: this.windowAvoidArea.navigationIndicator.visible
    ? this.windowAvoidArea.navigationIndicator.bottomRect.height
    : 0
})
```

This value is already vp: **do not px2vp it**. Extra cosmetic bottom spacing is **0vp** unless separately requested. Keep background as its sibling, with the BOTTOM expansion above; background is not inside the padded controls. This avoids only the visible bottom navigation indicator and ignores inherited bottom component gaps. Env responds to environmental changes without a manual event subscription. Installed API 26 also offers `ReadonlyEnvKey.WINDOW_AVOID_AREA`; the SystemProperties spelling is present in both local docs and SDK and remains supported.

Lower-API alternative: get the active window once, then obtain `uiContext.px2vp(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height)`. This API returns px. Update on `avoidAreaChange` only for TYPE_NAVIGATION_INDICATOR and unregister the same callback on destruction; catch window-query errors. Do not use getWindowAvoidAreaIgnoringVisibility when the requirement is visible navigation-only spacing. The current API-26 minimum makes this extra listener unnecessary.

### External references / versions

Read through `devecocli docs read`:

- `API参考/ArkUI_方舟UI框架/ArkTS组件/通用属性/布局与边框/安全区域/ts-universal-attributes-expand-safe-area`; [official safe-area reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-expand-safe-area). expandSafeArea API 10+, ignoreLayoutSafeArea API 20+.
- `API参考/ArkUI_方舟UI框架/ArkTS组件/响应式环境变量/Env_环境变量/ts-env-system-property`; [official Env reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-env-system-property). Env API 22+, WINDOW_AVOID_AREA API 23+.
- `API参考/ArkUI_方舟UI框架/ArkTS_API/窗口管理/ohos_window_窗口_/Interface_Window/arkts-apis-window-window`; [official Window reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-window-window#getwindowavoidarea9). getWindowAvoidArea and avoidAreaChange API 9+.
- `最佳实践/多设备界面开发/多设备窗口形态/窗口沉浸式/bpta-multi-device-window-immersive`; [official immersive-window practice](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-window-immersive), recommending navigation-indicator-specific bottom padding.
- Installed SDK API 26 / 26.0.0.105. The project targets and requires 26.0.0. Local docs describe an older enum shape but its recommended SystemProperties API is verified in the current declarations.

### Related specs

- `.trellis/spec/frontend/state-management.md`: retain ComponentV2 and existing Index-to-Play state flow; a system Env value does not need new global app state.
- `.trellis/spec/frontend/component-guidelines.md`: keep content action components and visual material rules; safe-area correction does not require redesigning them.

## Caveats / Not Found

- Static analysis cannot establish whether bindContentCover currently inherits an extra component bottom inset. Start with automatic avoidance; use the explicit alternative only if that inherited gap is observed.
- No build, emulator, rotation, gesture/three-button navigation or hidden-indicator verification. A side-mounted navigation area in landscape requires separate horizontal avoidance; bottom-only padding protects a bottom indicator only. Physical cutout avoidance is a separate requirement.
- Full-screen EntryAbility configuration alone does not establish each child component's resulting safe-area geometry. Verify control hit targets and background edge after implementation.
- `rtk` is unavailable in this shell; plain read-only commands were used. No production files changed and no Git operations performed.
