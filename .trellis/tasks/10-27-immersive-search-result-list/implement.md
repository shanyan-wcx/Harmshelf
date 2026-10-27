# Implementation Plan

1. Add an optional fixed-radius parameter to `ImmersiveActionButton`, using it only when supplied.
2. Replace the book result row in `Search.ets` with a 64vp `ImmersiveActionButton`, preserving content and navigation behavior.
3. Apply the same structure to the podcast result row.
4. Remove the search result `List.divider`; preserve item margins and safe-area insets.
5. Read the final diff, run `git diff --check`, validate task context, and run `devecocli build --product default --build-mode debug`.
6. Review that all pre-existing `ImmersiveActionButton` call sites keep their previous default radius and behavior.
