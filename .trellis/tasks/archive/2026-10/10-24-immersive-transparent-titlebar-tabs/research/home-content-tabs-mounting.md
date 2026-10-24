# Research: 首页内容 Tabs 挂载层级与 qingye-reader 对照

- Query: 核对 Harmshelf 首页内容 Tabs 的正确挂载层级/位置，区分 qingye-reader 的标题栏下内容区域与底部主导航，并确定本地最小修改文件。
- Scope: mixed
- Date: 2026-10-24

## Findings

### 1. Harmshelf 当前首页内容 Tabs 的正确挂载层级和位置

- `entry/src/main/ets/pages/Index.ets:132-133` 是 `topTabIndex` 与 `needUpdate` 的 Provider 源头；`Home.ets` 通过 Consumer 接收它们（`entry/src/main/ets/pages/Home.ets:61-68`）。因此首页内容 Tabs 的状态归属仍是 Index，但渲染归属应是 Home。
- `entry/src/main/ets/pages/Home.ets:107-114` 只为动态标签生成空 `TabContent` 和标签样式；真实首页内容仍由 `bookContentBuilder` / `podcastContentBuilder` 根据 `topTabIndex` 分发（`Home.ets:261-290`）。这说明 Tabs 是内容区控制器，不是主导航目的地。
- `entry/src/main/ets/pages/Home.ets` 的 `homeTabsBuilder()` 创建唯一的首页内容标准 ArkUI `Tabs`，使用 `BarPosition.End`、36vp 高度、`BarMode.Scrollable` + `LayoutStyle.ALWAYS_AVERAGE_SPLIT` 和 `fadingEdge(true)`，由顶部 Row 放在标题栏下方；每个 `TabContent` 使用自定义 tab builder 以避免默认 tab bar 的高度/绘制限制，标准悬浮栏仍提供原生圆角，并通过 `barFloatingStyle` 配置 `uiMaterial.ImmersiveMaterial`，同时关闭渐变蒙层与阴影。
- `Home.ets` 根 `Stack` 先绘制首页内容，再在同一 Stack 中绘制 Tabs；Tabs 通过 `Row` 覆盖在内容上方，并保留左右 16vp 内边距。底部主导航由 `Index.ets` 独立管理，不属于此组内容 Tabs。
- 点击同步写回 `topTabIndex` 并翻转 `needUpdate`；因此不应复制一套新的索引或再添加第二个内容导航控件。
- `entry/src/main/ets/utils/Component.ets` 显示主导航壳：`HdsNavigation` 包含 `Home()`，标题栏只承载选择器/菜单内容；该文件不承载首页内容 Tabs，把 Tabs 放入这里会重新混淆两层 Tabs。

### 2. qingye-reader 对应实现及与底部主导航的区别

- 本地参考快照 `.tmp-qingye-reader2/entry/src/main/ets/pages/Index.ets:483-493` 在根 `Stack` 中直接选择 `immersiveTabs()` 或兼容版 `compatTabs()`；这是一整个首页/应用级主导航，不是标题栏 builder 的子内容。
- `immersiveTabs()` 从 `.tmp-qingye-reader2/entry/src/main/ets/pages/Index.ets:704-723` 开始，`HdsTabs` 的每个 `TabContent` 直接装载 `BookshelfPage`、`ExplorePage` 等页面，并在 723、744、760、777 行用 `bottomTabBar(...)` 配置“书架/发现/搜索/我的”主导航项。
- 同一组主导航的浮动样式在 `.tmp-qingye-reader2/entry/src/main/ets/pages/Index.ets:779-810`：`barMode(Fixed)`、`barHeight(56)`、`barOverlap(true)`、圆角、`barFloatingStyle`、系统沉浸材质/渐变遮罩、底部 margin，且根 Tabs 扩展到底部安全区。它对应的是底部主导航外观与行为，不能直接套给 Harmshelf 的首页媒体内容标签。
- qingye-reader 的顶栏由自定义 `PageScaffold` 绘制：`.tmp-qingye-reader2/entry/src/main/ets/components/common/PageScaffold.ets:49-114` 将内容与 `titleBar()` 放在同一根 Stack；标题栏本身在 122-135 行定义。该文件没有 HdsTabs，也没有标题栏下方的第二组内容 Tabs。
- `PageScaffold` 的注释/实现（`PageScaffold.ets:16-18`, `80-114`）只处理内容是否 edge-to-edge、标题栏安全区、透明顶栏和滚动收起；这与 `Index.ets` 的底部主导航是两条独立层级。基于本地快照搜索，qingye-reader 没有 `HdsNavigation` / `HdsNavDestination` 用法，因此不能据此推断存在“标题栏下方内容 Tabs”。

### 3. 本地最小修改文件

- 针对用户本次纠正的“首页内容 Tabs 挂载位置”问题，最小产品文件是 `entry/src/main/ets/pages/Home.ets`：保留/调整 `homeTabsBuilder()` 及根 `Stack` 内的唯一渲染点，不要修改 `Index.ets` 的底部主导航，也不要把 Tabs 放入 `Component.ets` 的标题栏 content。
- 如果当前基线仍存在旧实现，则只需从 `entry/src/main/ets/utils/Component.ets` 删除首页 Tabs 专用的 `bottomBuilder`/相关 Tabs 代码；当前工作树源码已不存在这些项，现状无需再改该文件来解决 Tabs 层级。
- `entry/src/main/ets/pages/Index.ets` 只需继续提供 `topTabIndex` / `needUpdate`（132-133），本次不应新增 UI 修改。
- qingye-reader 快照 `.tmp-qingye-reader2/**` 是参考代码，不是 Harmshelf 产品文件，不应修改或复制业务实现。
- 若同时完成任务中“全局透明标题栏”这一独立目标，影响面另包括共享主导航 `Component.ets` 以及七个 `HdsNavDestination` 页面：`CollectionDetail.ets:252,539`、`Download.ets:30,98`、`EpisodeDetail.ets:543,802`、`FilterItems.ets:107,182`、`LibraryItemDetail.ets:1113,2135`、`PlaylistDetail.ets:266,606`、`Search.ets:72,198`。这属于标题栏样式变更，不是首页内容 Tabs 挂载修正本身。

## External references

### 4. Grid 顶部消失问题的官方文档结论

- DevEco 本地 API 文档 `API参考/ArkUI_方舟UI框架/ArkTS组件/滚动与滑动/Grid/ts-container-grid` 明确说明：Grid 的通用 `clip` 默认值为 `true`；设置 Grid 的 `padding` 后，子组件如果部分位于内容区、部分位于 padding 区会显示，但如果完全位于 padding 区则不会显示。
- 因此把标题栏避让直接放进 `Grid.padding.top` 会让顶部行进入 Grid 的特殊 padding 区，出现“刚碰到顶部就整行消失”；单纯给 Grid 或父容器设置 `.clip(false)` 不能改变 Grid 对 padding 区的布局可见性规则。
- 本次修复将顶部避让改成可滚动 Grid 内容中的全列 `GridItem` 空白占位，并移除 Grid 的 `padding.top`；占位随 Grid 一起滚动，真实行只在完全越过 Grid 视口顶部后消失。`GridItem.columnStart/columnEnd` 用于跨满当前动态列数，API version 11 起可用。

### 5. Tabs indicator 对齐结论

- 标准 `Tabs` 的实际 tab item 宽度由原生 TabBar、`barWidth`、`BarMode.Scrollable` 和动态标签共同决定；使用 `displayWidth / labelCount` 计算外置 indicator 会与原生 item 的实际宽度产生偏差。
- 每个 `TabContent.tabBar` 自定义 builder 内部直接居中绘制 20x3vp indicator，未溢出时跟随 `layoutWeight(1)`，溢出时跟随固定 item 宽度；标签数量增减时不需要重新推算整栏坐标。

- Project reference named by the task: <https://github.com/wip3l/qingye-reader>. The conclusions above use the local `.tmp-qingye-reader2` source snapshot available in this workspace; no external code was modified.
- Related local API notes: `.trellis/tasks/10-24-immersive-transparent-titlebar-tabs/research/qingye-reader-and-harmony.md`.

## Related specs

- `.trellis/spec/frontend/state-management.md`: home tab control belongs in `Home.ets`, shares `topTabIndex`, and must not be duplicated through `HdsNavigation.titleBar.content.bottomBuilder`.
- `.trellis/spec/frontend/directory-structure.md`: `Index.ets` is the global state hub and `Home.ets` is the home container with tab controller.
- `.trellis/tasks/10-24-immersive-transparent-titlebar-tabs/prd.md`: requirement 3 explicitly separates the home floating content Tabs from the title bar and bottom main navigation.

## Caveats / Not Found

- This is a read-only source inspection; no device visual validation was run.
- The qingye-reader snapshot contains an immersive bottom main navigation and custom transparent title bars, but no separate titlebar-under-content HDS Tabs implementation was found. Any design that claims otherwise needs new source evidence.
- `rtk` was not available in the current PowerShell environment, so equivalent native read-only PowerShell commands were used.
