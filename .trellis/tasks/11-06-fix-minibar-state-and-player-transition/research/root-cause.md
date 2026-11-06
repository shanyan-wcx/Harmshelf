# 根因研究：minibar 状态与全屏共享元素转场

## 证据

### HdsTabs 回调语义

- 官方 HdsTabs API 将 `onMiniBarAnimationStart(style, width)` 定义为动效开始时
  minibar 的状态；`onMiniBarAnimationEnd(style)` 定义为动效结束时的状态。
- 当前 `Component.ets` 用普通字段 `miniBarAnimationActive` 协调回调，但只把
  `MiniBarState.expanded` 传给 `PlaybackMiniBar`。播放器组件无法观察动画是否仍在
  进行，也无法在收起过程中关闭 `openPlayer()` 的命中区域。
- 当前 `onMiniBarAnimationStart` 会把 start 的旧状态推导为目标状态，逻辑方向是对的；
  但反复操作时若 `expanded` 的值没有变化，Builder 缺少一个新的可观察变化来保证
  内容树及时刷新。
- 回调没有动画序号。若用户在第一段展开/收起尚未结束时反向操作，旧 end 回调可能
  在新 start 之后到达；当前 `onMiniBarAnimationEnd` 不检查目标样式，会把状态机
  写回旧样式。这是“多数时候正常，反复多次偶发一次”的更强解释。

### Builder 与点击链

- `Play.ets` 的 `barBuilder()` 在 `expanded` 改变时从 `collapsedBarBuilder()` 替换
  为 `expandedBarBuilder()`，两个根节点分别是 `collapsedMiniBar` 和
  `expandedMiniBar`。这会让 HdsTabs 原生宽度动画和自定义根节点替换同时发生；偶发
  只看到中心封面、文字和按钮延迟出现，符合节点替换/重建时序竞争的表现。
- `coverBuilder()`、expanded 标题列和 expanded 根节点都可能调用 `openPlayer()`，
  当前条件只检查 `isExpanded()`，所以收起动画开始后仍有一段时间满足条件。

### geometryTransition 与视觉效果

- 官方 geometryTransition 文档要求源/目标节点配合 `animateTo`，并设置 `transition`
  以延迟析构；共享元素会同步绑定节点的 frame、position 和圆角。
- 当前源/目标封面使用 `TransitionEffect.OPACITY.animation(...)`。它满足节点保留，
  但也显式加入了透明度淡入淡出，因此用户看到的是虚化/淡入而不是条到全屏封面的
  几何变形。
- `bindContentCover` 当前已经使用 `ModalTransition.NONE`，不应再叠加默认模态动画。

## 结论

根因属于变更传播失败（动画态没有进入共享状态链）、回调乱序未校验目标样式，以及
节点生命周期与原生动画并发（两个根 Builder 交替重建）。最小设计是：把 `animating`
和期望目标作为 `@Trace` 状态传入播放器，丢弃过期 end 回调并统一保护点击；用稳定的
单一 minibar 根节点承载 collapsed/expanded 内容；把源/目标封面的 opacity transition
换成无视觉变化的 `TransitionEffect.IDENTITY`，让 `geometryTransition + animateTo`
单独负责空间变形。

## 参考文档

- HdsTabs minibar API：
  https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs/
- geometryTransition：
  https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-transition-animation-geometrytransition/
- bindContentCover 模态转场：
  https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V14/arkts-modal-transition-V14/
