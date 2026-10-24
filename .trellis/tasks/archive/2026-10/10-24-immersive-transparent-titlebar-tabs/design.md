# 设计：全局透明沉浸标题栏与首页 Tabs

## 当前结构

- `entry/src/main/ets/utils/Component.ets` 的 `MyNavigation` 是主导航壳，只包含主页面标题栏；首页内容 Tabs 由 `Home.ets` 自己渲染。
- `entry/src/main/ets/pages/Home.ets` 负责首页内容分发，`topTabIndex` 与 `needUpdate` 由 `Index.ets` 提供并由各首页内容使用。
- 二级页面在 `CollectionDetail.ets`、`Download.ets`、`EpisodeDetail.ets`、`FilterItems.ets`、`LibraryItemDetail.ets`、`Search.ets`、`PlaylistDetail.ets` 中各自配置 `HdsNavDestination` 标题栏。
- 当前首页 Tabs 已从 `SegmentButtonV2` 迁移到 `Home.ets` 根 `Stack` 的内容区顶部；可见标签由自定义 36vp Row 和单独 indicator 绘制，标准 `Tabs`（如保留）只提供沉浸材质底板；底部主导航由 `Index.ets` 独立管理。

## 目标结构

```text
MyNavigation
└── HdsNavigation
    ├── transparent immersive title bar (always visible)
    └── Home
        ├── full-screen/edge-to-edge home content
        └── top content custom tab row + indicator (home only, below the title bar)
```

首页 tabs 从 `MyNavigation.titleBar.content.bottomBuilder` 移到 `Home` 的根 `Stack` 中。标准 `Tabs` 负责索引同步、原生溢出滚动和 API 26 沉浸材质底板；每个 `TabContent` 的自定义 tab builder 负责可见文字和选中态，首页内容仍由 Home 现有的条件分发负责；这样不复制页面内容，也不改变索引状态流。

## 标题栏样式

在 `Component.ets` 提供共享的标题栏样式构造方法，主导航和普通二级页面复用透明沉浸样式，媒体详情页复用同一套材质配置但使用渐变模糊滚动效果：

- `transparentTitleBarStyle()` 将 `scrollEffectOpts.enableScrollEffect` 固定为 `false`，并直接设置 API 23 的 `systemMaterialEffect`；不保留低版本 `apiAvailable(23)` guard 或毛玻璃回退。
- `gradientBlurTitleBarStyle()` 设置 `scrollEffectOpts.scrollEffectType` 为 `ScrollEffectType.GRADIENT_BLUR`，供 `LibraryItemDetail.ets` 的媒体详情标题栏使用；其余页面继续使用透明沉浸样式。
- 不增加 `dynamicHideTitleBar`，因此标题栏不会因滚动消失。
- 各页面统一使用 `avoidLayoutSafeArea: true` 保持标题栏工具避让状态栏；页面根节点通过安全区扩展实现背景和内容 edge-to-edge，保留标题内容、菜单和 `bindToScrollable`。

## 首页 Tabs

`Home.ets` 复用当前标签生成逻辑（`getHomeTabLabels`）和当前选中颜色/指示器颜色。内容 tabs 保持在标题栏下方；qingye-reader 的底部 HDS Tabs 是另一组主导航，不能套用到这里：

- 标准 `Tabs` 使用 `barOverlap(true)`、`barPosition(BarPosition.End)`、`vertical(false)`、`barWidth('100%')`、`barHeight(36)` 和 `BarMode.Scrollable`，承载 API 26 `barFloatingStyle` 的 `uiMaterial.ImmersiveMaterial`；透明 `barBackgroundColor`、`maskColor: Color.Transparent`、`maskHeight: 0`、`barBottomMargin: 0` 与 `applyShadow: false` 保留当前材质观感，不让默认 tab bar 样式渲染文字或下划线；
- 可见层使用 36vp 自定义 tab builder，标签未溢出时 `layoutWeight(1)` 等宽填满，标签溢出时使用内容安全的固定 item 宽度，由原生 `BarMode.Scrollable` 处理横向滚动，保证“播放列表”等长文字完整。每个 tab item 内部居中绘制 20x3vp indicator，避免用整栏坐标推算导致标签数量变化时偏移；indicator 使用约 280ms `Curve.Friction`，文字颜色/字重变化使用约 180ms `Curve.Friction`；
- 既有 `.padding({left: 16, right: 16})`；
- 以 `topTabIndex` 作为索引，并在点击时更新 `topTabIndex` 与 `needUpdate`；
- 空的 `TabContent` 只作为材质底板的承载，实际首页内容继续由 Home 原有 builder 渲染；
- 渲染顺序为内容在下、自定义 tabs 在上，并以状态栏高度加 56vp 标题栏避让定位 36vp Row，避免落入状态栏或被标题栏覆盖。

项目 `targetSdkVersion` 保持 26.0.0；`compatibleSdkVersion` 固定为 6.1.0(23) 作为兼容基线，不再使用旧的 6.0.0(23) 描述或 HDS Tabs 实现。首页标准 `Tabs` 仅使用沉浸材质悬浮栏圆角，通过透明蒙层去除周围渐变模糊；文字、点击和 indicator 均由自定义 Row 控制。

## 首页沉浸与顶部避让

- 删除首页根节点当前固定的 `margin({ top: 56 })`，只在 Tabs 行保留状态栏高度加 56vp 标题栏避让。
- 首页内容分发不再给外层包装 Stack 增加顶部 padding；包装层不得把滚动视口整体下移。各首页 Scroll/Grid 保持从顶部 edge-to-edge 开始，只在原有 `padding.top` 上增加 `statusBarHeight + 56vp` 标题栏避让：RecentEpisodes 和非作者网格页使用 `statusBarHeight + 56 + 36`，SubHome（包含“继续收听”）和作者网格使用 `statusBarHeight + 56 + 31`，比其他首页子页少 5vp；作者网格保留独立的 `rowsGap(20)`，其他网格页使用 `rowsGap(15)`；Add 保留 `statusBarHeight + 56 + 36 + 80`。直接渲染在主导航内容中的 Local/Log/Setting/Stats 则在各自原有标题栏基准上追加 `statusBarHeight`。这样首屏仍避开标题栏和 36vp 内容 Tabs，滚动顶部可以进入状态栏区域；Tabs 行本身仍保持 `statusBarHeight + 56` 位置。
- `MyNavigation` 与 7 个 `HdsNavDestination` 根节点统一扩展到系统顶部安全区；首页根容器继续关闭裁剪，让滚动内容可以视觉上进入标题栏/状态栏区域。
- 继续保留各首页子页面已有的首屏顶部间距作为内容避让基线；实现后仅在确有重叠时把最小修正加到对应滚动容器，不能恢复一个全局固定外边距。
- `MyNavigation` 对所有主页面移除状态栏顶部布局 padding，二级页面使用相同的顶部 edge-to-edge 设置。
- `titleBarBuilder` 内层 Row 不启用 `clip(true)`，保证媒体库 Select 的底部阴影可以绘制出来。

## 风险与取舍

1. qingye-reader 的 GitHub 页面源码已通过只读快照核对：`Index.ets` 的 `HdsTabs` 是底部主导航；本项目只借鉴其自定义等宽 Row、独立 indicator 和透明顶栏方向，不把底部主导航样式/位置套到首页内容 tabs。
2. 首页现有子页面各自有 36/56/更高的顶部 padding，移动自定义 tabs 后可能出现个别页面留白或重叠。实现阶段先保留这些值，使用构建和可用设备验证定位，再做最小调整。
3. 首页标准 `Tabs` 仅使用文档中的 `ImmersiveMaterial` 悬浮栏作为底板，关闭默认渐变蒙层；可见 tabs 不依赖默认 tab bar 样式，target 26 与 compatible 6.1.0(23) 的版本关系保持清晰。

## 回滚边界

如果视觉验证发现某个页面的安全区回归，可单独回滚首页根安全区/对应滚动容器的改动；标题栏共享样式和首页 Tabs 迁移保持为独立修改，便于定位。
