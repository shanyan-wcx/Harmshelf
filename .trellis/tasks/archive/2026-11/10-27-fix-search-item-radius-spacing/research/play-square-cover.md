# Research: Preserve the player's full square cover

- Query: Inspect Play.ets image fitting and Stack geometry; recommend exact modifiers that preserve the full cover.
- Scope: internal + local HarmonyOS documentation / SDK
- Date: 2026-11-05

## Findings

### Files found and code patterns

- `entry/src/main/ets/pages/Play.ets:823`: full-screen player builder; three source branches for remote, local and fallback cover.
- `Play.ets:828-849`: all three primary images already use `.width('100%').aspectRatio(1)` with `ImageFit.Cover`.
- `Play.ets:852-864`: a second copy uses width 100%, height 160vp, rotation 180 degrees and gradient blur. It is a cropped decorative copy, not a full square image.
- `Play.ets:890-896`: that 160vp layer is a later child of a bottom-aligned square Stack; it overlays the lower part of the primary cover. `.clip(false)` cannot prevent this occlusion.
- `Play.ets:898-912`: the lower controls background is another rotated cover, stretched with `ImageSize.FILL`.
- `Play.ets:1291-1330`: mini-player circular image and the content-cover entry point; preserve its existing geometry transition and behavior.
- `entry/src/main/ets/pages/Index.ets:1058-1072`: supplied display dimensions track the window; they are not necessarily the actual cover container's available width.

### Exact recommendation

For the primary image in **each of the three branches**, use:

```typescript
.objectFit(ImageFit.Contain)
.width('100%')
.aspectRatio(1)
.draggable(false)
.geometryTransition("cover")
```

Keep the primary cover host explicitly square: `.width('100%').aspectRatio(1)`. Do not give that image or its host `.height(160)` or `.layoutWeight(1)`. `Contain` keeps all source pixels for rectangular artwork too; for square artwork in a square box, `Cover` and `Contain` have the same fit. `Fill` distorts non-square artwork.

If "full square cover" also means **the entire square must remain unobscured**, place the 160vp decorative band after the square host as a sibling in the existing outer Column. Keep title/author on the band, rather than layering a second opaque image over the square. Merely changing objectFit does not remove the existing overlay. The band can keep `.width('100%').height(160)` and a decorative `ImageFit.Cover`; its crop is intentional and independent of the primary artwork. A band added as a sibling consumes 160vp of vertical layout space: verify control fit before adopting this structure.

Keep square sizing on the image and host, and constrain the band separately. Stack children overlap; adding another child does not reserve more vertical space. If limited height should reduce cover size, choose a smaller **square side**, rather than reducing image height alone. No new display-width calculation is needed for the existing width-based square.

### External references / versions

Read through `devecocli docs read`:

- `API参考/ArkUI_方舟UI框架/ArkTS组件/图片与视频/Image/ts-basic-components-image` — objectFit defaults to Cover; [official Image reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-image).
- `开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/层叠布局_Stack/arkts-layout-development-stack-layout` — later Stack children cover earlier children; [official Stack guide](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-layout-development-stack-layout).
- Local SDK `C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/component/enums.d.ts:256-301` — Contain retains the entire image; Cover fills bounds; Fill ignores aspect ratio.
- Local SDK `ets/oh-uni-package.json`: API 26, platform 26.0.0, SDK 26.0.0.105. Project target and minimum compatible SDK are 26.0.0.

### Related specs

- `.trellis/spec/frontend/directory-structure.md`: Play owns the full-screen player UI.
- `.trellis/spec/frontend/state-management.md:22-30`: Index provides window dimensions and player state; keep existing Provider/Consumer flow.
- `.trellis/spec/frontend/component-guidelines.md`: preserve existing action components; this research does not require an action-button redesign.

## Caveats / Not Found

- Static source and local documentation inspection only; no build, screenshots or device verification. Short / landscape windows may not have enough space for square cover + separate band + controls.
- ObjectFit fixes image cropping, not an opaque sibling covering the image. Rotation 180 degrees flips both axes; it is not a vertical-only reflection.
- Browser access to the official Image page returned no readable body; local CLI documentation and installed SDK declarations supplied the evidence.
- No production source changed and no Git operations performed.
