# 技术设计：minibar 状态时序与非 tab 内部对齐

## 根因判断

这是一个 HdsTabs 回调语义与 UI 状态传播叠加导致的变更传播问题：

1. `onMiniBarAnimationStart(style, width)` 的 `style` 是动画开始时的旧状态。当前代码把它直接写成目标状态，展开时会先继续保持折叠，直到 `onBarStyleChange`/`onMiniBarAnimationEnd` 后才可能变为展开。
2. 三个回调都写同一个状态，回调顺序一旦交错，就会出现目标状态被旧状态覆盖或在动画末尾才稳定。单纯把 boolean 换成可观察对象只能解决“组件是否能观察到变化”，不能解决“写入了错误时序的状态”。
3. 非 tab 胶囊的父容器已经通过 `calc(100% - 40vp)` 提供外边距；当前内容使用 `100% + x=8vp` 的组合，右侧对齐但把左侧整体推远。改为子内容宽度向右扩展 8vp、位置不偏移，可以保持右端不变并收窄左端。

## 设计

### 状态同步

- 在 `MyNavigation` 保留现有 `MiniBarState` 引用，继续通过 `BuilderParam` 传入 `PlaybackMiniBar`。
- 增加一个仅用于回调协调的 `miniBarAnimationActive` 状态。
- `onMiniBarAnimationStart` 按官方语义取反旧状态：开始时是 `COLLAPSE` 则目标为 `EXPAND`，开始时是 `EXPAND` 则目标为 `COLLAPSE`；先更新 `MiniBarState`，再标记动画进行中。
- 动画进行中忽略可能重复到达的 `onBarStyleChange` 旧状态，避免覆盖目标布局。
- `onMiniBarAnimationEnd` 使用结束回调给出的最终状态，并清除动画标志。
- 未发生动画的初始创建、窗口尺寸变化或其他普通样式更新仍由 `onBarStyleChange` 同步；若该回调在动画开始前触发，开始回调会再次写入同一目标状态，不产生闪回。
- 不把 `miniBarStyle` 作为受控输入传回 HdsTabs，避免重建原生动画。

### 非 tab 布局

- 保持 `desktopMiniBarBuilder` 的外层 `calc(100% - 40vp)` 和 `maxWidth: 600`。
- `PlaybackMiniBar.expandedBarBuilder` 在 standalone 模式使用 `width('calc(100% + 8vp)')`、`offset({ x: 0 })`。
- 带 tab 模式继续保留原有右侧 `-8vp` 边距；两种宿主不共用同一套校正值。

## 数据流与边界

```
HdsTabs callback
  -> MyNavigation callback coordinator
  -> MiniBarState.expanded (@ObservedV2/@Trace)
  -> PlaybackMiniBar @Param reference
  -> expandedBarBuilder / collapsedBarBuilder
```

- 播放状态仍由 Index 的 Provider/Play 的 Consumer 提供，不复制播放状态。
- HdsTabs 仍负责原生胶囊和折叠/展开动画；自定义内容只响应状态，不增加 opacity 或 geometry 动画。
- `forceExpanded=true` 的 PC/无 tab 胶囊不受 tab 回调状态影响。

## 回滚

- 代码修改限定在 `Component.ets`、`Play.ets`，必要时 `Index.ets` 不需要变更。
- 若真机验证发现 HdsTabs 在某些设备不触发开始回调，回退本次提交即可恢复当前稳定行为；不改变播放状态或持久化数据。
