# Quality Guidelines

## Code style

- No comments unless explicitly asked (system convention)
- ArkTS strict typing: no `any` unless unavoidable
- Prefer `@Local` for component-private state
- Match existing code patterns rather than introducing new ones

## Error handling

- AVPlayer errors: handled via `on('error')` callback; guard consecutive errors to prevent reset loops
- Network errors: caught in API layer via try/catch on axios calls; show toasts for user-visible failures
- BusinessError: always log `code` and `message` for debugging
- Optional chaining: use `?.` for all `@Consumer()` and `@Provider()` optional fields

## Performance

- Clean up `setInterval`/`setTimeout` in `aboutToDisappear`
- Clear old intervals before creating new ones (prevent accumulation)
- Use `@Trace` sparingly — only on fields that need reactive updates
- `@Local` fields do not trigger UI re-render on change; use for non-reactive bookkeeping

## Glass effect patterns

- `backgroundBlurStyle` and `backgroundColor(Color.Transparent)` are a mandatory pair — NEVER use `backgroundBlurStyle` with an opaque background
- `borderRadius` on a glass/blur container requires `.clip(true)` — fog/overflow artifacts appear at corners without it
- `BlurStyle.COMPONENT_ULTRA_THICK` for cards/panels; `BlurStyle.COMPONENT_THICK` for interactive buttons
- `BlurStyle.Thin` is older-style but NOT deprecated in API 23 — however prefer `COMPONENT_THICK` for consistency
- Validate glass effect by checking visually: if the blur doesn't appear, the background color is likely opaque

## State management

- Do NOT manually toggle `@Provider` flags in child components when the parent's stateChange callback also manages them (e.g., `isPlaying` is managed by Index.ets stateChange)
- Use `avPlayer.state` only as a safety guard, NOT as the primary decision driver for UI actions
- `syncProgress` is guarded by `isSyncing` flag to prevent concurrent API calls

## AVPlayer state guard reference

Valid operations by player state:

| Operation | Valid states |
|-----------|-------------|
| `seek()` | prepared, playing, paused, completed |
| `play()` | prepared, paused, completed |
| `pause()` | playing |
| `reset()` | initialized, prepared, playing, paused, completed, stopped, error |
| `stop()` | prepared, playing, paused, completed |
