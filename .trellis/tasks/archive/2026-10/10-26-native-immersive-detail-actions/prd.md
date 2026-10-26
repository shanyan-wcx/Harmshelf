# Use immersive buttons on detail pages

## Goal

Use the native HDS `HdsTabs` immersive material for operation controls on the
library item detail and episode detail pages.

## Requirements

- Treat the official system immersive-light effect as a title-bar and Tab-bar
  capability in this project; do not use direct content-area `systemMaterial`.
- Remove/avoid the `hds_button` implementation and use the native
  `@kit.UIDesignKit` `HdsTabs` API through the shared action helper instead.
- Update the operation controls in `LibraryItemDetail.ets` and
  `EpisodeDetail.ets`: play/next, download, and more.
- Set all three immersive operation controls to `50vp` height; fixed icon
  controls are `50vp` wide as well so phone/tablet controls stay circular.
- Use the native HDS immersive material for play/next without a custom
  business-color background; fixed icon controls remain transparent.
- Treat press-and-drag elastic deformation as unsupported by the native HDS
  API; do not add a separate gesture animation here.
- Keep the control sizes, spacing, icons, and labels visually equivalent unless
  the package requires the native component's supported layout API.
- Keep the change scoped to the two detail pages and their shared visual helper.

## Acceptance Criteria

- [x] Both detail pages use the shared `ImmersiveActionButton` helper.
- [x] The rendered controls use the native HDS `HdsTabs` immersive material.
- [x] Play/next and fixed icon controls use the native HDS material without a
      custom business-color background.
- [x] Play/next, download, and more are rendered at `50vp` by `50vp`.
- [x] The package limitation on press/drag elastic deformation is verified;
      no custom gesture animation is added.
- [ ] Download permission handling, download confirmation, more menu, and
      playlist sheet still work through the same callbacks/modifiers.
- [x] The project compiles with DevEco CLI without new ArkTS errors.
