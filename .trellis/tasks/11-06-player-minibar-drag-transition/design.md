# 技术设计

## 边界与根因

交互源在 `entry/src/main/ets/pages/Play.ets` 的 `PlaybackMiniBar`，全屏目标在同文件
的 `Play.playBuilder()`；HdsTabs 样式回调在 `entry/src/main/ets/utils/Component.ets`
的 `MyNavigation`。上一轮修复把 `animating` 作为全屏点击禁用条件，和本次要求相反；
同时，`bindContentCover` 的目标 Builder 只在状态切换时出现，单靠条件式
`geometryTransition` 绑定无法提供可拖拽的中间进度，因此点击时会直接显示最终页面。

## 方案

1. 保留 `MiniBarState.targetStyle` 用于丢弃过期 HdsTabs 结束回调，但移除
   `canOpenPlayer()` 对 `animating` 的限制。`expanded` 在 start 回调中已经写成目标样式，
   因而展开开始即允许展开态的点击；收起开始即交给折叠态/HdsTabs 的交互。
2. 新增一个由 `Index` 提供、同时被 `PlaybackMiniBar` 和 `Play` 消费的轻量
   `PlayerTransitionState`，只保存 `active`、`opening` 和 `progress`。它不承载播放
   业务状态，只负责两端共享转场进度。
3. 在播放条上注册竖直向上 `PanGesture`。普通点击继续走现有 `openPlayer()`；手势更新
   将向上位移归一化到 `progress`，先显示 `bindContentCover` 的全屏 Builder，再以
   `scale/translate` 和底部播放条中心作为变换锚点，使全屏内容从条位置跟手展开。
   松手后使用 `animateTo` 将进度补到 1，再清除转场态。折叠 minibar 的手势层使用
   透明命中并不处理普通点击，让 HdsTabs 继续负责折叠条点击展开。
4. 点击打开和拖拽完成共用同一个 `startPlayerTransition()`；全屏左上角按钮调用
   `closePlayerTransition()`，先把共享进度反向动画到 0，结束后再将 `showPlay` 置为
   false。这样 `bindContentCover` 继续保持 `ModalTransition.NONE`，不会插入默认模态
   动画，也不会出现先关闭再显示播放条的闪烁。
5. 移除仅服务于全屏封面的一组 `playerCoverTransition` 绑定和源节点临时 id；可见的
   连续性由共享进度作用于播放页根节点保证。保留播放条根节点的
   `geometryTransition("miniBar")`，因为它仍用于 HdsTabs minibar 与非 Tab 播放条之间
   的条级切换。打开/关闭结束时清理 `active` 与进度，避免下一次切换复用旧状态。

## 数据流

`PanGesture/点击` → `PlayerTransitionState.progress` → `PlaybackMiniBar` 源条保持在
底部、`Play.playBuilder` 目标根节点按进度变换 → `animateTo` 完成 → `showPlay` 最终状态。
HdsTabs 的 `expanded/targetStyle` 状态链与上述播放页转场状态分离，避免两个动画互相
覆盖。

## 兼容与风险

- 使用 API 26 已有的 `PanGesture`、`animateTo`、`bindContentCover` 和通用变换属性，
  不引入 API 27+ 接口。
- 全屏根节点在进度小于 1 时需要临时裁切成条形态，进度完成后恢复原有不裁切布局；
  封面自身继续保留原有圆形裁切。
- HdsTabs 折叠态手势与自定义向上 PanGesture 存在命中竞争，采用透明命中和仅向上
  方向识别，需重点通过构建与真机手势验证。
- 真机验证仍是视觉验收的必要条件，尤其是平板、PC/2in1 非 Tab 条的起始锚点。
