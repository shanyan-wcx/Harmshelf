# 首页仅使用标题栏分段按钮切换

## Goal

移除首页内容区原有的 `HdsTabs`，由标题栏底部的 `TabSegmentButtonV2` 作为唯一首页分段导航，并保持页面内容、动态选项和共享切换状态一致。

## Background and confirmed facts

- `entry/src/main/ets/pages/Home.ets` 当前使用 `HdsTabs` 展示书籍/播客首页内容，索引来自根组件提供的 `topTabIndex`。
- `entry/src/main/ets/utils/Component.ets` 的 `MyNavigation.titleBarBottomBuilder()` 已使用同一 `topTabIndex` 和 `needUpdate` 驱动 `TabSegmentButtonV2`；标题栏底部区域仅在 `pageIndex === 0` 且首页已连接媒体库时显示。
- `getHomeTabLabels()` 已集中定义媒体类型、用户权限和播放列表条件下的首页选项顺序，标题栏按钮与原首页 tabs 使用同一数据源。
- 原首页 `HdsTabs` 的 tab 内容映射为：书籍 `首页/媒体库/系列/[收藏]/作者/[播放列表]`，播客 `首页/最新/媒体库/[添加]/[播放列表]`。
- 原 tabs 使用 `barPosition(BarPosition.Start)`、`barHeight(36)`；标题栏底部自定义区域高度为 56，当前按钮容器保留左右 16 padding。
- 鸿蒙 `TabSegmentButtonV2` 文档支持 `selectedIndex` 与 `$selectedIndex`，`HdsNavigation.titleBar.content.bottomBuilder` 支持标题栏下方自定义区域。

## Requirements

1. 删除 `Home.ets` 中的 `HdsTabs`、`HdsTabsController` 及其 tabBar 配置，不再在首页内容区显示原 tabs。
2. 使用 `topTabIndex` 选择并渲染当前首页内容，保持书籍/播客、管理员权限和播放列表条件下的原有内容顺序与页面组件。
3. 继续由标题栏 `TabSegmentButtonV2` 更新 `topTabIndex` 并翻转 `needUpdate`，保证切换时既更新显示内容又触发现有数据加载逻辑。
4. 保持 `getHomeTabLabels()` 为标题栏选项的唯一文案/顺序来源；首页首次进入、切换媒体库和动态播放列表场景下不得出现索引错位。
5. 让 `TabSegmentButtonV2` 的顶部与原 `HdsTabs` 的起始边对齐：保留底部区域高度和左右 16 padding，在按钮容器中使用顶部交叉轴对齐，同时保留水平居中。
6. 仅首页显示标题栏分段按钮；统计、本地、日志、设置等其他页面不显示，也不改变其标题栏布局。
7. 不改变标题栏主内容、菜单、沉浸材质、选中背景色、字体和其他页面行为。

## Acceptance Criteria

- [x] 首页不再创建或显示 `HdsTabs`，且只显示一个由 `TabSegmentButtonV2` 控制的首页内容。
- [x] 书籍库各选项及播客库各选项均渲染原对应页面；管理员/普通用户及有无播放列表时数量、顺序和索引一致。
- [x] 点击标题栏任一分段按钮后，`topTabIndex`、页面内容和现有数据刷新逻辑保持同步。
- [x] 标题栏分段按钮顶部与原 tabs 的起始位置对齐，左右 16 padding 保留。
- [x] 离开首页后分段按钮及其空间消失，返回首页后恢复。
- [x] `devecocli build` 成功，无新增 ArkTS 编译错误；`git diff --check` 通过。

## Out of scope

- 不调整首页 tab 文案、顺序、权限规则、数据接口或各子页面内部布局。
- 不新增第二套首页状态，也不保留隐藏的 `HdsTabs` 作为同步中间层。
- 不修改其他一级页面的标题栏或导航方式。

## Open questions

- None.
