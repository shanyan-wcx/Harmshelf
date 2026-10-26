# Research: HdsTabs immersive action rectangle

- Query: Determine why `ImmersiveActionButton` still shows a rectangular clipping/backing boundary after custom `clip`, `backgroundColor`, and `gradientMask` were removed, and identify the smallest documented HdsTabs fix that preserves native `systemMaterialEffect`.
- Scope: mixed — Harmshelf source, local DevEco CLI HarmonyOS documentation and SDK declarations, plus official Huawei documentation/forum evidence.
- Date: 2026-10-26
- Status: This records the pre-fix source shape and diagnosis. The current implementation applies the core recommendation below; source line references in this document are the investigation snapshot.

## Files found

- `entry/src/main/ets/utils/Component.ets` — shared `ImmersiveActionButton`; the relevant implementation is lines 106-183.
- `entry/src/main/ets/pages/LibraryItemDetail.ets` — play/next, download, and more action call sites at lines 1143-1264.
- `entry/src/main/ets/pages/EpisodeDetail.ets` — play, download, and more action call sites at lines 614-723.
- `.trellis/spec/frontend/component-guidelines.md` — project rule that the shared helper owns one native HdsTabs instance and must not add a second painted background.
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\UI_Design_Kit_UI设计套件\ArkTS组件\HdsTabs\ui-design-hdstabs.md` — local HdsTabs API reference, metadata version V189.
- `C:\Users\21633\.local\share\deveco-cli\docs\开发指南\UI_Design_Kit_UI设计套件\底部页签\设置页签栏的悬浮样式\ui-design-hds-tabs-bar-floating.md` — official floating-style guide, metadata version V20.
- `C:\Users\21633\.local\share\deveco-cli\docs\开发指南\UI_Design_Kit_UI设计套件\底部页签\设置页签栏的模糊样式\ui-design-hds-tabs-fuzzy-style.md` — official blur/background guidance, metadata version V20.
- `C:\Users\21633\.local\share\deveco-cli\docs\开发指南\UI_Design_Kit_UI设计套件\沉浸光感\ui-design-hds-component-material.md` — official HDS immersive-material guide, metadata version V20.
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\导航与切换\TabContent\ts-container-tabcontent.md` — `tabBar` custom-builder and overflow-clipping contract, metadata version V214.
- `C:\command-line-tools\sdk\default\hms\ets\api\@hms.hds.hdsBaseComponent.d.ets` — installed SDK declarations for `HdsTabsFloatingStyle`, `HdsTabsBackgroundStyle`, and HdsTabs attributes.
- `C:\command-line-tools\sdk\default\openharmony\ets\component\tab_content.d.ts` — installed SDK declaration showing TabContent’s default clip behavior.

## Findings

### Bottom line

The primary rectangular backing is created by the current `.barFloatingStyle(...)` at `Component.ets:158-170`, not by the custom `Stack` builder. HdsTabsFloatingStyle’s documented default `gradientMask` is a non-transparent bottom mask: light mode `#CCF1F3F5`, dark mode `#99000000`, with height equal to the tab-bar default height plus 16vp (`ui-design-hdstabs.md:693-699`). Therefore, deleting an explicit `gradientMask` restores the native default; it does not make the floating host transparent.

There is a second implicit surface: the current `.barOverlap(true)` at `Component.ets:153`. HdsTabs documents that `true` makes the TabBar overlap/blur the TabContent and changes the default `barBackgroundBlurStyle` to `BlurStyle.COMPONENT_THICK` (`ui-design-hdstabs.md:388-413`). The official fuzzy-style guide explicitly tells developers to set `barBackgroundBlurStyle(BlurStyle.NONE)` when they need to remove that default TabBar blur (`ui-design-hds-tabs-fuzzy-style.md:19-25`). The default divider is another possible line boundary: HdsTabs’ divider defaults to follow-scroll (`ui-design-hdstabs.md:519-540`), and the official no-border forum example disables it.

The custom builder is transparent, but it does not own the HdsTabs floating host. `buttonTabBarBuilder()` creates a `Stack` with width/height 100% and a radius, but no background or clip (`Component.ets:128-137`). A radius on a transparent child cannot reshape an ancestor’s native floating mask. The HdsTabs root owns the bar geometry and effects (`Component.ets:140-169`).

### Current source trace

1. `ImmersiveActionButton` accepts fixed `50` or measured `'100%'` widths and a `50` height (`Component.ets:106-119`).
2. Its custom tab-bar builder wraps the caller content in a full-size `Stack`, applies `borderRadius(getImmersiveActionRadius(...))`, and binds the menu (`Component.ets:128-137`). No custom `backgroundColor`, `clip`, or `gradientMask` is present in this helper.
3. The helper creates one HdsTabs with a zero-size `TabContent` (`Column().width(0).height(0)`) and attaches that custom builder with `.tabBar(...)` (`Component.ets:139-146`).
4. The HdsTabs host is explicitly sized, uses `barWidth`/`barHeight`, enables overlap, uses fixed bar mode, and enables floating style with native IMMERSIVE/ADAPTIVE material (`Component.ets:148-169`).
5. Both detail pages preserve the outer action-row sizes, sheets, callbacks, and menu data; the three controls only provide the shared builder content (`LibraryItemDetail.ets:1141-1283`, `EpisodeDetail.ets:612-741`).

### Exact local/API evidence

#### Floating-style host and default mask

- The floating guide requires `barPosition(BarPosition.End)`, `vertical(false)`, and `barOverlap(true)`; it supports `BottomTabBarStyle` and `CustomBuilder` (`ui-design-hds-tabs-bar-floating.md:26-32`). The current helper meets those constraints at `Component.ets:153-155` and uses a custom builder at `Component.ets:146`.
- The official sample uses a normal full-size `TabContent`, then `.barOverlap(true)`, `.barPosition(BarPosition.End)`, `.vertical(false)`, and `.barFloatingStyle(...)` (`ui-design-hds-tabs-bar-floating.md:70-112`). Its explicit `gradientMask` is a visible backplate, while `systemMaterialEffect` is a separate field (`ui-design-hds-tabs-bar-floating.md:99-107`).
- The API reference defines `barFloatingStyle` as the switch that sets the TabBar to floating style (`ui-design-hdstabs.md:639-657`). `HdsTabsFloatingStyle.gradientMask` is specifically the backplate mask, and its default color/height are non-transparent (`ui-design-hdstabs.md:659-699`). The SDK declaration independently confirms that `gradientMask` and `systemMaterialEffect` are separate optional fields (`@hms.hds.hdsBaseComponent.d.ets:5380-5453`).
- `HdsTabsFloatingStyle.barWidth` is the floating bar’s breakpoint width; the default is 76/80vp for small tab counts and up to 328vp for larger counts (`ui-design-hdstabs.md:671-676`). The range fields are `smallWidth`, `mediumWidth`, and `largeWidth`; percentage values are not supported (`ui-design-hdstabs.md:753-790`). The current helper’s measured numeric width in all three ranges is therefore the right way to keep a 50vp or measured primary-action host from falling back to the default 76/80vp width (`Component.ets:151-163`).

#### Overlap, background, blur, and divider

- `barOverlap(true)` is not a transparent/no-op setting. The reference says it overlays the TabBar on TabContent and changes the default blur to `BlurStyle.COMPONENT_THICK`; `false` removes blur and overlap (`ui-design-hdstabs.md:388-413`).
- `barBackgroundColor` controls the TabBar background and its documented default is already `Color.Transparent` (`ui-design-hdstabs.md:417-440`). Adding `.barBackgroundColor(Color.Transparent)` is a useful explicit guard but is not the root cause and cannot override the non-transparent floating `gradientMask` default.
- `barBackgroundStyle` is the ordinary HdsTabs gradient-blur mask, not the floating-style `gradientMask`. It sets mask color/height and the API notes that the default blur becomes invalid when this style is used (`ui-design-hdstabs.md:554-580`; `ui-design-hds-tabs-fuzzy-style.md:35-41`). It is not needed for a transparent per-action floating bar; adding it risks configuring a second, page-sized mask.
- HdsTabs’ divider API defaults to a follow-scroll divider (`ui-design-hdstabs.md:519-540`). A standalone one-tab action should explicitly use `divider({ mode: DividerMode.NONE })` if a residual separator line is visible. This is separate from the filled rectangular mask.
- `BarMode.Fixed` is not the source of the rectangle. Standard Tabs documentation says Fixed mode evenly divides the configured `barWidth`; HdsTabs’ `HdsBarMode` is the normal `BarMode` plus its side-bar extension (`ts-container-tabs.md:208-240`; `ui-design-hdstabs.md:1300-1317`). With one custom tab, Fixed simply gives that tab the configured width. `barMode` should not be changed to Scrollable or HALF_SCREEN_FIXED for this issue.

#### Custom builder and clipping

- `TabContent.tabBar` accepts `CustomBuilder`, and the builder can contain arbitrary components (`ts-container-tabcontent.md:35-64`, `:98-143`). The floating guide explicitly lists `CustomBuilder` as a supported floating-bar style (`ui-design-hds-tabs-bar-floating.md:26-32`), so a transparent custom bar is a supported input.
- The TabContent API says content exceeding the tab-bar item is clipped (`ts-container-tabcontent.md:35-44`, `:98-106`). The installed ArkUI declaration also says TabContent’s default `clip` is `true` and must be disabled only when content needs to extend outside the component (`tab_content.d.ts:870-876`). Removing a `.clip()` from the inner Stack does not remove this framework-level TabContent/tab-bar overflow rule.
- The HdsTabs API’s custom-builder sample uses a builder with a rounded 48vp image (`ui-design-hdstabs.md:1537-1582`) but does not show a host-background or host-radius API. This demonstrates that builder content styling and the HdsTabs host surface are separate.
- In this helper the builder content fits inside the 50vp bar and does not bleed, so TabContent clipping is not the likely visible rectangular backing. It can explain a rectangular clipping limit for oversized content, but not a filled/blurred rectangle around an in-bounds icon.

#### Native immersive material

- The HDS immersive guide states that HDS bottom-tab immersive material is configured through `HdsTabsFloatingStyle.systemMaterialEffect` (`ui-design-hds-component-material.md:4-13`). Its official sample keeps `barOverlap(true)`, `vertical(false)`, `barPosition(End)`, and `barFloatingStyle.systemMaterialEffect` together (`ui-design-hds-component-material.md:213-242`).
- `SystemMaterialParams.materialType` defaults to NONE and `materialLevel` defaults to ADAPTIVE; the guide recommends ADAPTIVE for system-selected performance/visual quality (`ui-design-hdstabs.md:864-900`). The current IMMERSIVE/ADAPTIVE configuration is therefore the correct native-material path; removing it removes the requested capability.
- The official API does not expose a separate “material radius”, “disable material edge highlight”, or “clip the floating host to the custom builder radius” field. The documented floating knobs are width, side/bottom margins, gradient mask, light color, opacity, thermo control, and material effect (`ui-design-hdstabs.md:659-749`).

### Transparent custom bar: what it can and cannot do

Yes, the custom `tabBar` content can be transparent while `systemMaterialEffect` remains configured, because the builder content and the floating-style material are separate API inputs. The documented way to remove the visible native backdrop is to override the default floating `gradientMask` with a transparent mask and neutralize the implicit overlap blur. Explicit `barBackgroundColor(Color.Transparent)` is harmless but redundant because transparent is the documented default.

No, a transparent builder cannot guarantee that the native HdsTabs host has no visible boundary. The native material is applied to the HdsTabs floating bar, not to the builder’s inner Stack, and the public API has no host-radius/edge-highlight switch. If, after removing the default mask/blur/divider, the remaining artifact is only a thin rectangular/capsule edge highlight, it is part of the native IMMERSIVE material rather than a custom rectangle. Huawei’s official developer forum has a directly relevant no-border example that uses `gradientMask: { maskColor: Color.Transparent }`, `lightColor: Color.Transparent`, `barBackgroundColor(Color.Transparent)`, `barBackgroundBlurStyle(BlurStyle.NONE)`, and `divider({ mode: DividerMode.NONE })`; its accepted reply attributes the remaining “包边” to IMMERSIVE’s built-in edge highlight. Treat that forum reply as field evidence, not an API contract: <https://developer.huawei.com/consumer/cn/forum/topic/0208225739070961359?fid=0109140870620153026>.

### Full-size TabContent, zero-size TabContent, and nesting

- The official floating sample uses full-size content because HdsTabs is a content-and-tab-bar container; the HdsTabs API calls it a root view container generally used as a Page root (`ui-design-hdstabs.md:4-6`, `:25-35`).
- No local API text says that a full-size TabContent is required for `barFloatingStyle`, nor that a zero-size TabContent disables the floating mask. The mask’s documented default is tied to the floating style/tab-bar dimensions, not to the custom builder’s radius.
- A full-size transparent `Column().width('100%').height('100%')` is a reasonable layout-stability experiment because it matches the official sample and avoids relying on zero intrinsic content. It is not the minimal fix for the rectangle and should not be used as a substitute for explicit floating-mask/blur settings.
- The docs describe HdsTabs as generally page-root, but do not prohibit nesting. They provide no supported “one 50vp HdsTabs as a button” recipe. Therefore, changing HdsTabs nesting is an architectural fallback, not a documented fix for this visual artifact. A page-level HdsTabs redesign would be materially larger than this task.

### Concrete minimal fix recommendation (implemented after this research)

Keep the current HdsTabs nesting, custom builder, fixed width ranges, `barOverlap(true)`, `barMode(BarMode.Fixed)`, and native `systemMaterialEffect`. In the shared helper, make every host visual that is currently defaulted explicit:

```typescript
.barBackgroundColor(Color.Transparent)
.barBackgroundBlurStyle(BlurStyle.NONE)
.divider({ mode: DividerMode.NONE })
.barFloatingStyle({
  barWidth: {
    smallWidth: this.resolvedBarWidth(),
    mediumWidth: this.resolvedBarWidth(),
    largeWidth: this.resolvedBarWidth()
  },
  barSideMargin: 0,
  barBottomMargin: 0,
  // Omission restores the documented opaque default mask; do not omit it.
  gradientMask: { maskColor: Color.Transparent },
  // Optional if a residual light halo is the only artifact.
  lightColor: Color.Transparent,
  systemMaterialEffect: {
    materialType: hdsMaterial.MaterialType.IMMERSIVE,
    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
  }
})
```

The first diagnostic change should be `gradientMask: { maskColor: Color.Transparent }` plus `barBackgroundBlurStyle(BlurStyle.NONE)`, because those correspond respectively to the documented default backplate and the `barOverlap(true)` implicit blur. Add the explicit transparent color and `DividerMode.NONE` in the same helper if the device still shows a line. Do not set `barOpacity: 0`: that hides the floating bar/material rather than making only its default mask transparent. Do not add `barBackgroundStyle` unless a deliberate gradient blur is wanted.

If the remaining boundary is confirmed to be IMMERSIVE’s native edge light, there is no documented HdsTabs knob to remove only that edge while retaining the exact IMMERSIVE preset. At that point the choices are to accept the native edge, try a supported `hdsMaterial.MaterialType`/level on target hardware, or replace the native material with a lower-level `backgroundEffect`; the last choice conflicts with this task’s native-HDS-material requirement.

## Code patterns

- `entry/src/main/ets/utils/Component.ets:61-63` — radius helper returns half-height on phone/tablet and 8 on other device types.
- `entry/src/main/ets/utils/Component.ets:128-137` — custom builder is full-size and rounded but has no custom surface/clip.
- `entry/src/main/ets/utils/Component.ets:140-169` — native HdsTabs host, zero-size TabContent, explicit dimensions, overlap, fixed mode, floating widths, and IMMERSIVE material.
- `entry/src/main/ets/utils/Component.ets:171-182` — measured primary width and event monopolization; unrelated to the visual rectangle.
- `entry/src/main/ets/pages/LibraryItemDetail.ets:1143-1264` — all three action controls use the helper and preserve callbacks/sheets/menu data.
- `entry/src/main/ets/pages/EpisodeDetail.ets:614-723` — all three episode action controls use the helper and preserve callbacks/sheets/menu data.

## External references

- Huawei HdsTabs API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs>
- Huawei HdsTabs floating-style guide: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating>
- Huawei HDS immersive-material guide: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-component-material>
- Huawei TabContent API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-tabcontent>
- Huawei ArkUI Tabs API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-tabs>
- Huawei immersive-light overview and scope limits: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-immersive-light-sense-overview>
- Huawei developer-forum no-border field report (non-normative): <https://developer.huawei.com/consumer/cn/forum/topic/0208225739070961359?fid=0109140870620153026>

## Related specs

- `.trellis/spec/frontend/component-guidelines.md` — requires `ImmersiveActionButton` to own one native HdsTabs instance, use `barFloatingStyle.systemMaterialEffect`, avoid a second background host, and keep menu binding inside the builder.
- `.trellis/spec/frontend/directory-structure.md` — shared UI helper belongs in `entry/src/main/ets/utils/Component.ets`; detail pages remain the callers.
- `.trellis/tasks/10-26-native-immersive-detail-actions/prd.md` and `design.md` — native HDS material is required; custom business-color backgrounds and a separate painted material are out of scope.

## Caveats / Not Found

- No official API declaration documents a way to round or disable only the HdsTabs floating host’s native material edge while retaining `systemMaterialEffect`.
- No emulator/device render test was run; this was intentionally research-only and no production file was changed. The exact remaining artifact should be classified after the transparent-mask/blur diagnostic: filled rectangle/backdrop, divider line, or native material edge light.
- The official floating sample uses full-size TabContent and multiple tabs, not a single 50vp nested action. Its layout is a comparison reference, not proof that zero-size TabContent is invalid.
- The developer-forum accepted answer is useful corroboration for native edge highlighting, but it is community content and should not override the local SDK/API contract.

## Immediate handoff / search stopped

- Official/local HdsTabs evidence: `barFloatingStyle.gradientMask` is the floating backplate and defaults to a non-transparent mask; `barOverlap(true)` also enables the default `BlurStyle.COMPONENT_THICK` background blur. `barBackgroundColor` defaults to transparent, so it is not the primary cause. The official floating sample keeps `systemMaterialEffect` separate from `gradientMask`.
- Root cause judgment: the visible filled rectangular boundary comes from the HdsTabs floating host created by the current `.barFloatingStyle(...)` at `entry/src/main/ets/utils/Component.ets:158-170`, specifically the omitted `gradientMask` default; `.barOverlap(true)` at line 153 adds a secondary blur surface. The rounded transparent custom `Stack` at lines 128-137 cannot reshape that ancestor host.
- Minimal recommendation: retain the current HdsTabs/custom-builder/native IMMERSIVE structure, explicitly set `gradientMask: { maskColor: Color.Transparent }`, `.barBackgroundBlurStyle(BlurStyle.NONE)`, and `divider({ mode: DividerMode.NONE })`; optionally set `barBackgroundColor(Color.Transparent)` and `lightColor: Color.Transparent` if a halo remains. Do not use `barOpacity: 0` because it hides the native material. A full-size `TabContent` or different nesting is not required by the docs and is not the minimal fix.
- Final caveat: if only a thin native IMMERSIVE edge highlight remains after those settings, the public HdsTabs API exposes no documented switch to remove that edge while retaining the exact native material preset.
