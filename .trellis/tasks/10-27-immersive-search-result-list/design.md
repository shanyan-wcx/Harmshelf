# Technical Design

## Boundaries

- `entry/src/main/ets/pages/Search.ets`: owns result-item composition, list margins, content padding, and navigation click handlers.
- `entry/src/main/ets/utils/Component.ets`: owns the shared native HDS immersive action wrapper and its default radius policy.
- No API, state, or data-model changes.

## Component Contract

Extend `ImmersiveActionButton` with an optional fixed corner-radius parameter:

- omitted: preserve `getImmersiveActionRadius(barHeight)` for existing callers;
- search results: pass `8` so all devices render a rounded rectangle;
- keep native `HdsTabs`, transparent gradient mask, clipping rules, and event monopolization unchanged.

Each Search result `ListItem` will contain one `ImmersiveActionButton` with:

- `barWidth: '100%'`;
- `barHeight: 64` to match the existing cover-driven row height;
- fixed radius `8`;
- the existing cover/title/author content in a full-size centered builder row;
- the existing navigation action moved to `onButtonClick`.

The `ListItem` retains its current top and bottom margins and gains horizontal `20vp` padding around the button. The `List` divider is removed.

## Compatibility / Rollback

- Existing callers do not pass the new parameter and therefore retain their current appearance.
- Rollback is limited to reverting the shared optional parameter and the two Search result branches; no data migration or persisted state is involved.
