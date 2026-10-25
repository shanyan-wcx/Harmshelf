# Type Safety

## Type organization

- All shared interfaces and types go in `utils/Interface.ets`
- Import with named imports: `import { PlayItem, Track, Chapter } from '../utils/Interface'`
- HarmonyOS SDK types imported from `@kit.*` modules

## Naming conventions

- Interfaces: PascalCase (e.g. `PlayItem`, `UpdateSession`, `SkipSettings`)
- Type aliases: PascalCase when complex, inline when simple
- Export all shared types from `Interface.ets`

## Key types

```typescript
// API response types
interface LoginInfo { name: string; server: string; username: string; password: string }
interface PlayItem { id: string; libraryItemId: string; ... audioTracks: Track[]; chapters?: Chapter[] }
interface Track { index: number; startOffset: number; duration: number; contentUrl: string; ... }
interface UpdateSession { deviceInfo: DeviceInfo; mediaPlayer: string; currentTime: number; timeListened: number }
```

## State classes

- Decorated with `@ObservedV2` and `@Trace`
- Use `@Type()` decorator for nested observable objects
- Default constructors provide initial values (no undefined fields)

## Best practices

- Mark all `@Consumer()` and `@Provider()` fields with `| undefined` and check with `?.`
- Use `!` non-null assertion sparingly (only when known to be set, e.g., in callbacks)
- Prefer `import type` for type-only imports (though ArkTS presently requires runtime imports for @ObservedV2 classes)
- `BusinessError` type from `@kit.BasicServicesKit` for HarmonyOS API errors
