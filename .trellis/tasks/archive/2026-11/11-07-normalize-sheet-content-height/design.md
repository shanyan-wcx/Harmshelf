# Technical Design

## Boundary

Only sheet sizing and the minimum layout wrappers required for content measurement change. Existing builders, callbacks, button handlers, top `8vp` padding, bottom padding, and list-sheet sizing remain otherwise unchanged. The project targets API 26, so the API 23+ FIT_CONTENT rule uses the measured height even when it is below the historical `320vp` center-sheet minimum.

## Changes

### Content-sized form sheets

- `pages/tabs/Add.ets`: change the confirm-add sheet from fixed `457` to `SheetSize.FIT_CONTENT`; keep the form in a vertical `Scroll`, but remove the root percentage height and put the form padding on the content `Column` so the builder root has an intrinsic height.
- `pages/Setting.ets`: change add/edit server sheets from fixed `388` to `SheetSize.FIT_CONTENT`; remove `height('100%')` from the sheet root/scroll path. Keep the loading layer as a fixed-height centered overlay so it does not participate in a circular percentage-height measurement.
- `utils/Component.ets`: change the shared `ReportPanel` from percentage-height layers to an intrinsic-height content column plus a fixed-height centered loading overlay.
- `pages/EpisodeDetail.ets` and `pages/LibraryItemDetail.ets`: use `SheetSize.FIT_CONTENT` for their report sheets; the shared `ReportPanel` supplies the measured content.

### Intentionally fixed/scrollable sheets

Keep `SheetSize.MEDIUM` for playlist, collection, feed episode, bookmark, and chapter sheets. Their builders contain full-height lists and bottom actions; replacing them with FIT_CONTENT would either remove the bounded scrolling viewport or create a percentage-height measurement cycle.

Keep existing FIT_CONTENT builders that already have intrinsic roots (`Column`, or a non-percentage `Scroll`) unchanged apart from verification.

## Layout Invariants

- Every affected content root keeps `padding({ top: 8, ... })`.
- No affected FIT_CONTENT builder root uses `height('100%')`.
- The fixed-height loading overlay is not used to size the sheet.
- No business callback or visibility state is changed.

## Risk and Rollback

The risk is that an ArkUI sheet may clamp a long intrinsic form at the window maximum; the preserved `Scroll` allows the form to remain usable. Rollback is a single commit revert if a device shows incorrect sheet measurement.
