# Component Guidelines

## Library immersive action controls

Use the shared `ImmersiveActionButton` from `utils/Component.ets` for
content-area actions that need the native HDS immersive material. It wraps one
native `HdsTabs` instance from `@kit.UIDesignKit`; do not replace it with a
painted blur, a second background button, or `hds_button`.

Apply the same helper to every podcast episode action row, including the
`EpisodeComponent` used by the RecentEpisodes tab. Keep the four actions
(play, completion state, playlist, and download) on the shared 38vp sizing and
event/clipping pattern instead of leaving ordinary `Button` instances in one
episode list.

The official system `immersive-light` effect is reserved for title bars and
Tab bars in this project. Do not use direct content-area `systemMaterial` for
these actions; use the shared HDS helper instead.

```typescript
Row() {
  ImmersiveActionButton({
    barWidth: 50,
    barHeight: 50,
    menuItems: this.moreMenus,
    onButtonClick: () => this.openMenu()
  }) {
    SymbolGlyph($r('sys.symbol.more'))
  }
}
.margin({ left: 16 })
.width(50)
.height(50)
```

The shared `HdsTabs` uses `barFloatingStyle.systemMaterialEffect` with the
native immersive material. Its single custom tab bar is the visible button;
the shared helper sets the requested size, radius, and the same width in all
three `barFloatingStyle.barWidth` ranges, plus `monopolizeEvents(true)`, so a
press-and-drag on an action does not scroll the parent detail page. Keep the
floating `gradientMask` explicitly transparent, disable the default tab-bar
blur and divider, and do not add a second painted surface. Use
`barWidth: '100%'` for a flexible primary action and `barWidth: 50` for
standard fixed icon actions; use an explicit compact width only where the
layout calls for it (the podcast feed search action is 32vp). Keep the
containing action row on `layoutWeight(1)` plus fixed controls so narrow
screens do not overflow.

`TabContent` clips by default. The HdsTabs root, its TabContent and child
content, the custom tab-bar `Stack`, and every detail-page Row in the action
chain must use `.clip(false)` so the native material edge/shadow is not cut by
an ancestor. Do not remove unrelated `.clip(true)` modifiers used to mask
media thumbnails or content rows.

Pass `menuItems` for menus that belong to an immersive action. The shared
helper binds the array on the custom HdsTabs bar builder; do not put
`bindMenu` on the outer `Row`, because `monopolizeEvents(true)` prevents that
parent from receiving the click. Native HdsTabs supplies the press feedback;
do not add a parallel custom pressed-state animation.

For non-interactive immersive surfaces such as the detail-page progress
summary, pass `monopolizeActionEvents: false`. This keeps the HdsTabs material
but lets the parent `Scroll` receive drag gestures; interactive action buttons
leave the default `true`.

When a custom-builder component needs `.bindSheet`, `.margin`, or `.clip`, wrap
it in an outer `Row` and put those modifiers on that Row; ArkTS does not accept
continuing a modifier chain directly after the trailing builder block.

Keep action icon and label colors inside the builder content when the existing
design requires them; do not add a custom background host. Put layout modifiers
such as `.margin`, `.width`, and
`.bindSheet` on the outer `Row`, not after the trailing builder block. Pass
menu arrays through `menuItems`; the helper binds them to the inner button.

## Avoid

- Replacing `ImmersiveActionButton` with an ordinary button and a manually
  painted material approximation.
- Adding a second background button behind the native HDS bar.
- Adding a custom gesture animation solely to imitate the native HdsTabs
  pressed state.
- Hardcoding the primary action width by subtracting fixed controls.
- Omitting `.clip(false)` from a HdsTabs action layer or its detail-page action
  Row; `TabContent`'s default clipping can create a rectangular boundary.

