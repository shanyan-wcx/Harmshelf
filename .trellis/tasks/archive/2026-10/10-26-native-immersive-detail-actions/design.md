# Technical design

## Scope and behavior gap

The two detail pages contain content-area operation controls. They need the
native HDS pressed state and immersive material while preserving the existing
action layout and callbacks.

## Approach

1. Inspect the local `HdsTabs` API and native material configuration.
2. Add one shared `ImmersiveActionButton` helper around a single-item
   `HdsTabs` instance.
3. Replace only the three operation-control surfaces in each target page with
   the shared library button/content API.
4. Keep each existing callback and sheet/menu modifier on the corresponding
   control. Do not add a custom background to the play/next or fixed icon
   controls; let the native HDS material provide the action surface.
5. Use HdsTabs' native pressed feedback; do not add a parallel custom pressed
   state or gesture animation.
6. Use `50vp` for the shared action height and fixed icon width so all three
   operation controls have a consistent 50-by-50 layout.
7. Bind the more menu through the shared helper's HdsTabs bar builder, because
   the helper monopolizes events and the outer row cannot trigger the menu
   reliably.

## Files expected to change

- `entry/src/main/ets/pages/LibraryItemDetail.ets`: project/media detail
  operation controls.
- `entry/src/main/ets/pages/EpisodeDetail.ets`: episode detail operation
  controls.
- `.trellis/spec/frontend/index.md` and
  `.trellis/spec/frontend/component-guidelines.md`: record the component
  library and the title-bar/Tab-bar system-material boundary.

`entry/src/main/ets/utils/Component.ets` owns the shared visual helper; the
two pages keep their existing callback state and behavior.

## Compatibility and risks

- The project minimum API is 26, so the native HDS APIs are available without
  lower-version guards.
- `hds_button` is not retained; the shared helper uses the native `HdsTabs`
  API directly.
- The custom HdsTabs bar builder owns the visible action content. The shared
  helper configures its size, radius, native immersive material, and touch
  exclusivity without a separate background host or floating gradient mask.
