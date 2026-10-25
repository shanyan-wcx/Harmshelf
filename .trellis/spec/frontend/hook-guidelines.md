# Hook Guidelines

This project does not use React hooks or custom hooks.

## No hooks pattern

The app uses ArkUI's `@ComponentV2` / `@ObservedV2` lifecycle model:

- `aboutToAppear()` — initialization (replaces `useEffect`/`onMount`)
- `aboutToDisappear()` — cleanup (replaces `useEffect` cleanup)
- `@Monitor('field')` — react to specific state changes (replaces `useEffect` with dep array)

## Alternative: setTimeout / setInterval patterns

For delayed or periodic work:

```typescript
// Store interval ID for cleanup
@Local timerId: number = -1

startTimer() {
  this.timerId = setInterval(() => { ... }, step)
}

aboutToDisappear() {
  if (this.timerId !== -1) clearInterval(this.timerId)
}
```

For async callbacks from AVPlayer/AVSession, use `Promise` / `async/await` directly in the callback.
