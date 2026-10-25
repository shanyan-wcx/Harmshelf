# Database Guidelines

## Not applicable

This project has no backend database. Persistent state is managed via:

1. **PersistenceV2** (`@kit.ArkUI`) — for user preferences (server config, playback settings, theme)
2. **Server-side state** — listening progress stored on the Audiobookshelf server via REST API (syncSession, closeSession)
3. **No local SQLite / ORM** — the app does not store data locally beyond preferences
