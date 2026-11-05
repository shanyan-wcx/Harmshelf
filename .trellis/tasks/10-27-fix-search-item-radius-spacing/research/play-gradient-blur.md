# Research: Player linearGradientBlur semantics

- Query: Verify direction, fractionStops and a predictable sharp-to-blurred transition for the cover-derived band.
- Scope: internal + local HarmonyOS documentation / SDK
- Date: 2026-11-05

## Findings

### Files found and code patterns

- `entry/src/main/ets/pages/Play.ets:857-864`: 160vp-high image, `.rotate({ angle: 180 })`, radius 80, stops `[[1, 0], [1, 0.72], [1, 0.88], [0.15, 0.96], [0, 1]]`, direction Top.
- SDK root: `C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/`.
- `component/common.d.ts:22938`: FractionStop tuple declaration; `:23786-23811`: LinearGradientBlurOptions and required fields.
- `component/enums.d.ts:2492-2523`: Top means bottom-to-top; Bottom means top-to-bottom.

### Semantics

- Each tuple is **[blur strength, position]**, both clamped to [0, 1]. It is not [position, strength]. There must be at least two stops; positions must strictly increase.
- Strength 0 means no blur at that location; strength 1 means full specified blur. The FractionStop table also calls this an opacity fraction: it controls the blur mask, not image opacity. Use an opacity/mask/gradient separately if a true transparent fade is needed.
- Radius is in [0, 1000]; 80 is valid. The cited local reference does not explicitly specify a radius unit, so do not assume it is vp.
- With Bottom, position 0 is the top and position 1 is the bottom. Top reverses those positions.
- The existing Top stops have full blur from the untransformed bottom through position .88, then fade toward clear at the untransformed top. Rotation of that same image makes screen-space interpretation harder. Reordering `.rotate()` and `.linearGradientBlur()` in the source is not a reliable way to define coordinate spaces.

### Exact recommendation

For a decorative band whose **visible top is clear and bottom fully blurred**, apply this to an **unrotated host containing the decorative image only**:

```typescript
.linearGradientBlur(80, {
  fractionStops: [[0, 0], [0.15, 0.04], [1, 0.12], [1, 1]],
  direction: GradientDirection.Bottom
})
```

These stops preserve the existing rapid transition: at a 160vp band height the transition occupies the top 19.2vp. They reverse the existing Top profile into explicit top-to-bottom coordinates and remove redundant full-blur stops. This is a design recommendation, not a platform-required profile. For a longer transition, choose `[[0, 0], [0, 0.12], [1, 0.45], [1, 1]]` (clear for 19.2vp, fully blurred by 72vp).

If keeping the reflected/rotated artwork, rotate the **child image**, leaving the host receiving linearGradientBlur unrotated. Render title/author as a later sibling outside that blurred host; applying blur to their shared Stack would blur the text too. Host/band size remains `.width('100%').height(160)`. Keep the primary square artwork out of this effect.

### External references / versions

- `devecocli docs read API参考/ArkUI_方舟UI框架/ArkTS组件/通用属性/视效与模糊/图像效果/ts-universal-attributes-image-effect`, sections linearGradientBlur12+, LinearGradientBlurOptions12+, FractionStop12+.
- [Official image-effects reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-image-effect): API 12 introduced the effect; API 18 adds Optional arguments.
- [Official enums reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-appendix-enums#gradientdirection); installed API 26 SDK 26.0.0.105 supplies precise direction declarations.

### Related specs

- `.trellis/spec/frontend/component-guidelines.md`: this is an image effect, not a replacement for native material action components; no action-style change is needed.

## Caveats / Not Found

- No device rendering or performance check. Rotation/effect compositing of the current single node was not experimentally verified; using separate transform/effect nodes makes the intended coordinate system explicit.
- Decorative ImageFit.Cover in a 160vp rectangle intentionally crops; preserving the full primary cover is a separate layout requirement.
- Official web image-effects fetch timed out; local documentation and SDK were readable. No source changes or commits.
