# 优化首页标题栏悬浮 Tabs

## Goal

将首页标题栏底部的 `TabSegmentButtonV2` 替换为鸿蒙 HDS 普通 Tabs 悬浮样式，保留现有首页页面切换状态，并让长标签由 Tabs 自己处理超出滚动和沉浸光感。

## Background and confirmed facts

- `entry/src/main/ets/utils/Component.ets` 的 `titleBarBottomBuilder()` 已提供动态首页选项、共享 `topTabIndex`、16 左右 padding 和首页限定显示条件。
- `getHomeTabLabels()` 会在存在播放列表时追加最后一项“播放列表”，HDS Tabs 的 `HdsBarMode.Scrollable` 可在 TabBar 超出宽度时自动滚动。
- HDS `HdsTabs` 支持 `barFloatingStyle`，其中可配置 `systemMaterialEffect`，适合标题栏底部的悬浮沉浸光感样式。
- `TabSegmentButtonV2` 和 `ScrollDirection.Horizontal` 不再作为本次方案的一部分；`DividerShowType.OFF` 也不使用。

## Requirements

1. 在首页 `bottomBuilder` 中使用 HDS `HdsTabs` 悬浮样式，不再使用 `TabSegmentButtonV2` 或横向 `Scroll` 包裹。
2. 使用 `HdsBarMode.Scrollable`，保证“播放列表”等长选项完整显示，并允许用户横向滚动 TabBar。
3. 使用 `barFloatingStyle` 的沉浸系统材质，去掉当前分段按钮材质背景导致的底部阴影观感；不添加 `DividerShowType.OFF`。
4. TabBar 选项继续来自 `getHomeTabLabels()`，点击后更新共享 `topTabIndex` 并触发现有 `needUpdate` 数据刷新和首页内容切换。
5. 仅在首页且已连接到媒体库时显示；其他页面不显示。保留现有 16 左右 padding、顶部对齐和标题栏布局。

## Acceptance Criteria

- [x] 首页标题栏底部显示 HDS 普通 Tabs 悬浮样式，不再生成 `TabSegmentButtonV2`。
- [x] 播放列表文字完整显示；标签超过可视宽度时可在 TabBar 内横向滚动。
- [x] API 23+ TabBar 启用沉浸系统材质，旧设备回退到已有模糊样式；代码中不存在 `DividerShowType.OFF`。
- [x] 点击 TabBar 后，首页内容、`topTabIndex` 和 `needUpdate` 仍保持同步。
- [x] 其他页面不显示该 bottomBuilder；原有 padding、对齐和动态选项保持不变。
- [x] `devecocli build` 成功，无新增 ArkTS 编译错误；`git diff --check` 通过。

## Out of scope

- 不修改首页 tab 文案、顺序、内容映射或共享状态。
- 不调整其他页面的标题栏样式、滚动方向或导航行为。
- 不新增依赖、资源或持久化配置。

## Open questions

- None.
