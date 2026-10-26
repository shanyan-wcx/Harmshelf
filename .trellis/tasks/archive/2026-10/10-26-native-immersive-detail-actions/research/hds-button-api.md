# Immersive action API research

- The detail action helper uses the native `HdsTabs` API from
  `@kit.UIDesignKit`.
- Each helper instance has one zero-size `TabContent` and a custom tab-bar
  builder containing the action icon/content. `barWidth`/`barHeight`,
  `barOverlap`, and `barFloatingStyle` make that tab bar occupy the original
  button rectangle.
- Floating HdsTabs uses `barFloatingStyle.barWidth` rather than the regular
  `barWidth` value for its actual floating plate. The helper sets
  `smallWidth`, `mediumWidth`, and `largeWidth` to the requested button width;
  otherwise HdsTabs falls back to its compact single-tab width and clips a
  flexible play/next action.
- `barFloatingStyle.systemMaterialEffect` uses
  `hdsMaterial.MaterialType.IMMERSIVE` and `MaterialLevel.ADAPTIVE`, so the
  native HDS pressed feedback is retained without a custom state animation.
- HarmonyOS menu documentation allows `bindMenu(Array<MenuElement>)` on the
  custom tab-bar builder. The detail more menu therefore binds inside the
  shared builder; binding only on the outer row is ineffective when
  `monopolizeEvents(true)` consumes the child click.

Source checked from the installed SDK declaration and local HarmonyOS docs:

- `C:\command-line-tools\sdk\default\hms\ets\api\@hms.hds.hdsBaseComponent.d.ets`
- `C:\command-line-tools\sdk\default\openharmony\ets\component\tab_content.d.ts`
