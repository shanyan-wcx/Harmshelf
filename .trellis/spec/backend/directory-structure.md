# Backend Development Guidelines

## Not applicable

This project is a **pure frontend HarmonyOS/ArkTS application**. It communicates with an external Audiobookshelf server via REST API, but contains no server-side code.

The code under `entry/src/main/ets/` is all frontend:
- UI pages (ArkTS + HDS design system)
- API client (`utils/Api.ets`) for communicating with the Audiobookshelf server
- Local audio playback via `@kit.MediaKit`

## API client conventions (for reference)

- Base URL: configured via LoginInfo.server
- Auth: Bearer token (apiToken), refreshed on login
- Axios instance: `@ohos/axios` with configurable timeout (default 5000ms)
- Session sync: POST to `api/session/{id}/sync` every ~10s during playback
- Error handling: catch axios errors, log, show toast to user
