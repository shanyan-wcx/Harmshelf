# Implementation plan

1. Inspect the current git state and the local `HdsTabs` API/material
   declarations.
2. Implement one shared single-item `HdsTabs` action surface and use it in
   both detail pages, preserving callbacks, menus, sheets, dimensions, and
   spacing without a custom action background.
3. Keep HdsTabs' native pressed feedback; do not add a local pressed-state
   animation.
4. Set all immersive operation controls to `50vp` by `50vp` and inspect both
   detail pages for missed 40vp action dimensions.
5. Bind the more menu through the shared HdsTabs bar builder instead of the
   event-monopolized outer row.
6. Run DevEco CLI compile/build checks and fix only errors caused by this task.
7. Run the Trellis quality check and update specs only if this task reveals a
   reusable project convention.
