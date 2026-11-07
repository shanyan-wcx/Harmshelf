# Implementation Plan

1. Re-read all `bindSheet` declarations and classify them as intrinsic-content, intentionally MEDIUM list, or fixed-height form/report.
2. Update the Add confirm builder and sheet option to use intrinsic content measurement.
3. Update add/edit server builders and sheet options, preserving loading behavior without percentage-height roots.
4. Update the shared report builder and both report sheet bindings.
5. Search for remaining fixed content-sheet heights and percentage-height FIT_CONTENT roots.
6. Build with DevEco CLI and inspect failures/warnings.
7. Review the diff, verify the task acceptance criteria, and commit the code changes.

## Validation

- `rg -n "bindSheet|height: [0-9]+|SheetSize.FIT_CONTENT|height\('100%'\)" entry/src/main/ets/pages entry/src/main/ets/utils/Component.ets`
- DevEco debug build for product `default`.
- Manual diff review focused on sheet builder roots, `top: 8`, bottom padding, and callback preservation.

## Rollback Points

- Add confirm sheet changes are isolated to `pages/tabs/Add.ets`.
- Server sheet changes are isolated to `pages/Setting.ets`.
- Report changes are shared through `utils/Component.ets` and two height options; revert the single commit if the overlay or sheet measurement regresses.
