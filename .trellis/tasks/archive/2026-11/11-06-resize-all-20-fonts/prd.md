# 全项目20号字体调整为18号

## Goal

将应用源代码中所有非 symbol 的 20 号字体配置统一调整为 18 号，消除页面、弹窗、输入框和设置项之间的字号不一致。

## Confirmed Scope

- 扫描范围为 `entry/src/main/ets` 源代码，不修改 `entry/build` 下的构建缓存或生成文件。
- 当前源代码共发现 38 个 20 号字号配置：28 个直接 `.fontSize(20)`，10 个 `placeholderFont` / `Select.font` 的 `size: 20`。
- `LibraryItemDetail.ets:315` 是 `SymbolGlyph` 的字号，沿用此前约定不修改；实际修改 37 个文本字号配置。
- `Play.ets:1597` 的播放页标题、`Setting.ets` 的服务器表单、服务器设置区块、设置项、按钮、关于区域以及相关 placeholder/select 字体均在本次范围内。

## Requirements

- 将源代码中所有非 `SymbolGlyph` 的 `.fontSize(20)` 调整为 `.fontSize(18)`。
- 将源代码中所有作为字体配置的 `size: 20` 调整为 `size: 18`。
- 保持 `LibraryItemDetail.ets:315` 的 `SymbolGlyph` 字号 20 不变。
- 不修改字号不是 20 的配置、不修改布局、颜色、交互和业务逻辑。

## Acceptance Criteria

- [x] `entry/src/main/ets` 中除 `LibraryItemDetail.ets:315` 外不再存在 20 号字体配置。
- [x] 所有 37 个目标配置均为 18。
- [x] 不产生构建缓存或生成文件的代码改动。
- [x] `git diff --check` 通过，改动仅限字号值。

## Notes

- 这是机械性的轻量任务，使用 PRD-only 流程。
- 构建产物中的旧字号不作为源代码修改目标，后续构建会重新生成。
