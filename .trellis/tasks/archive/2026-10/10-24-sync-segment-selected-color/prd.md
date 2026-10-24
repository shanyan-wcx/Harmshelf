# 同步分段按钮选中背景色

## Goal

让首页标题栏中的 `TabSegmentButtonV2` 选中项背景色与首页 `HdsTabs` 当前选中指示色保持一致。

## Confirmed facts

- `entry/src/main/ets/pages/Home.ets` 的所有首页 `HdsTabs` 使用 `sys.color.comp_emphasize_secondary` 作为聚焦时的选中指示色，失焦时使用 `sys.color.ohos_id_color_hover`。
- `entry/src/main/ets/utils/Component.ets` 的标题栏分段按钮使用 `TabSegmentButtonV2`，当前未显式设置选中项背景色。
- 鸿蒙 `TabSegmentButtonV2` 文档对应属性为 `itemSelectedBackgroundColor`。

## Requirements

1. 在现有 `TabSegmentButtonV2` 配置中设置 `itemSelectedBackgroundColor`。
2. 复用首页 tabs 的同一套聚焦/失焦颜色表达式：聚焦时 `sys.color.comp_emphasize_secondary`，失焦时 `sys.color.ohos_id_color_hover`。
3. 不改变 tab 选项、状态同步、沉浸材质、标题栏显示条件或其他页面行为。

## Acceptance Criteria

- [x] 首页标题栏分段按钮的选中项背景色与首页 tabs 的选中指示色一致。
- [x] 页面失去焦点时，分段按钮与首页 tabs 使用相同的失焦颜色。
- [x] `devecocli build` 成功，无新增 ArkTS 编译错误。

## Out of scope

- 不修改 `topTabIndex` 同步逻辑或动态 tab 选项。
- 不调整未选中项背景、字体、圆角或沉浸材质。
- 不改动其他页面的标题栏。

## Open questions

- None.
