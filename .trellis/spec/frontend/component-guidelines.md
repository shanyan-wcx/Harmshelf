# Component Guidelines

## Component types

### Page components (@Entry)

- Root level: `Index.ets` — the single `@Entry` component
- Navigation pages: `Play.ets`, `Setting.ets`, `Home.ets`, etc. — pushed via `NavPathStack`
- Each page is a `@ComponentV2` struct, imported and pushed via `pageInfos.pushPath()`

### Reusable components

- Live in `utils/Component.ets` unless they're page-specific
- Examples: `MyNavigation`, `LibraryItemComponent`, `SeriesItemComponent`, etc.
- Named with descriptive PascalCase, exported for use across pages
- Accept inputs via `@Prop` or `@Consumer` shared state

### Tab sub-pages

- Live in `pages/tabs/` as separate files
- Hosted by `Home.ets` which owns the `Tabs` controller
- Each tab is a minimal `@ComponentV2` that reads from `@Provider` state via `@Consumer`

## Patterns

### @ComponentV2 + @ObservedV2

```typescript
@ObservedV2
export class MyModel {
  @Trace field: string = ''
}

@ComponentV2
export struct MyComponent {
  @Consumer() sharedState: MyModel | undefined
  @Local localState: number = 0
}
```

### Builders

- `@Builder` annotated methods for section-specific UI
- Placed inline in the struct (not in separate files)
- Example: `SideBarPanelBuilder()`, `ContentPanelBuilder()` in Index.ets

### Lifecycle hooks

- `aboutToAppear()` — initialization, resource setup
- `aboutToDisappear()` — cleanup (intervals, subscriptions)
- `@Monitor('fieldName')` — react to state changes

## Best practices

- Prefer `@Consumer` over prop drilling for cross-component state
- Use `@Local` for UI-only state that doesn't leave the component
- Clean up `setInterval`/`setTimeout` in `aboutToDisappear`
- Store interval IDs as `@Local number = -1` for cleanup

## Common UI patterns

### Glassmorphism (frosted glass)

The project uses a consistent glassmorphism pattern across all UI layers:

**Card-level glass** (covers, avatars, panels):
```typescript
.backgroundColor(Color.Transparent)
.backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
.borderRadius(10)
.clip(true)
.shadow({ radius: 8, color: $r('sys.color.ohos_id_shadow_default_lg_dark') })
```

**Button-level glass** (back-to-top, pageUpDown, action buttons):
```typescript
.backgroundColor(Color.Transparent)
.backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
.borderRadius(12)
.shadow({ radius: 12, color: $r('sys.color.font') })
```

**Critical rules**:
- `backgroundBlurStyle` MUST be paired with `backgroundColor(Color.Transparent)` — opaque backgrounds hide the blur
- Every `borderRadius` on a glass container MUST be paired with `.clip(true)` to prevent visual overflow
- Use `BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE` with an `inactiveColor` when blur follows window focus
