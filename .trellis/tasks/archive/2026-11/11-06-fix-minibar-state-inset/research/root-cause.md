# 根因研究：minibar 切换延迟与非 tab 左边距

## 证据

- 当前 `Component.ets` 同时注册 `onBarStyleChange`、`onMiniBarAnimationStart`、`onMiniBarAnimationEnd`，三个回调都直接调用同一个 `onMiniBarStyleChange(style)`。
- API 26 SDK 和官方 HdsTabs 文档明确：
  - `onMiniBarAnimationStart` 的 `style` 是“动效开始时迷你栏的状态”；
  - `onMiniBarAnimationEnd` 的 `style` 是“动效结束时迷你栏的状态”；
  - `onBarStyleChange` 的第一个参数是样式更新后的 `miniBarStyle`。
- 因此当前展开操作收到 `COLLAPSE` 的 start 回调时，会把 `expanded` 写回 false；自定义 Builder 只能继续渲染折叠内容，直到后续回调写入 EXPAND。
- `@ObservedV2`/`@Trace` 和 `@Param` 的引用传播本身是正确方向，但它不能修正错误的回调写入时序；这解释了上一个提交后问题仍存在。
- Standalone 父 Row 已是 `calc(100% - 40vp)`。当前 expanded 内容是 `width('100%') + offset(8vp)`，所以内容起点整体右移 8vp。右端通过偏移后刚好对齐，但左端多出 8vp；使用 `width(calc(100% + 8vp)) + offset(0)` 可以保持右端相同、消除这 8vp 左侧偏移。

## 失败修复复盘

1. 用普通 boolean 作为 Builder 参数：解决了部分构建刷新，但普通值在自定义 Builder 生命周期中是快照，不能保证动画过程内更新。
2. 换成 `@ObservedV2` 引用：解决了引用观察问题，但仍把 start 回调的旧状态直接写回，属于“状态传播正确、状态含义错误”。
3. 用负偏移和宽度扩展校正非 tab：改变了两端同时受影响的几何关系，后来反向偏移又把左端推远；应固定右端，用宽度扩展而不是位置偏移。

## 结论

根因类别：C（变更传播失败）+ E（隐含的回调状态语义假设）。本次修复必须同时处理回调状态时序和 standalone 的锚定方式，不能继续只调整 `@Param` 或单独改变 offset。
