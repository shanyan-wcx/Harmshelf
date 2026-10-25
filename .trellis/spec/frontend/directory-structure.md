# Directory Structure

## Project layout

```
entry/src/main/ets/
├── entryability/          — UIAbility entry point (lifecycle, window config)
├── entrybackupability/    — Backup extension ability
├── pages/                 — Main pages (@Entry components)
│   ├── Index.ets          — Root component, global state, AVPlayer orchestration
│   ├── Play.ets           — Full-screen player UI
│   ├── Setting.ets        — Settings page (server, playback, download)
│   ├── Home.ets           — Home container with tab controller
│   ├── LibraryItemDetail.ets — Audiobook/podcast detail page
│   ├── EpisodeDetail.ets  — Episode detail page
│   ├── Search.ets         — Full-text search
│   ├── Stat.ets           — Listening statistics
│   ├── Log.ets            — Debug log viewer
│   ├── Local.ets          — Local media browser
│   ├── Download.ets       — Download task list
│   ├── PlaylistDetail.ets — Playlist detail
│   ├── CollectionDetail.ets — Collection detail
│   └── FilterItems.ets    — Filtered item list
│   └── tabs/              — Tab sub-pages (Home, Library, Series, etc.)
└── utils/                 — Utility modules
    ├── Interface.ets      — All TS interfaces/types
    ├── Api.ets            — HTTP API client
    ├── Class.ets          — Data classes (Env, DownloadManager)
    ├── Component.ets      — Reusable UI components (MyNavigation, cards, etc.)
    └── Logger.ets         — In-app logging
```

## Conventions

- One file per page component, named PascalCase matching the struct name
- Utilities go under `utils/`, grouped by concern
- Tab sub-pages go under `pages/tabs/`
- Tests mirror source under `src/ohosTest/` and `src/test/`

## Notes

- `Play.ets` exports a `Play` struct (shared via `@Provider`/`@Consumer` from `Index.ets`)
- `Index.ets` is both the @Entry component and the global state hub
- `Setting.ets` imports state classes from `Index.ets`, not from separate module
