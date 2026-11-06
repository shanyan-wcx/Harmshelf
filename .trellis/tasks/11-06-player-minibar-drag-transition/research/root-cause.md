# 根因研究：minibar 可交互拖拽与全屏转场

## 代码证据

- `entry/src/main/ets/pages/Play.ets:59-64` 的 `canOpenPlayer()` 当前同时检查
  `miniBarState.animating` 与 `showPlay`。HdsTabs start 回调在
  `entry/src/main/ets/utils/Component.ets:329-334` 已把 `expanded` 写成目标样式，
  因此再次用 `animating` 禁用点击会与“动画开始即采用目标操作”冲突。
- `PlaybackMiniBar` 当前用 `bindContentCover(this.showPlay, this.playBuilder(), ...)`，
  全屏页面只在 `showPlay` 为真时创建；`openPlayer()` 只切换布尔状态，无法提供手指
  位移对应的中间进度。
- 全屏用的 `playerCoverTransition` 共享 id 只绑定封面 Image，且源节点的 id 只在
  `playerCoverTransition` 为真时建立。它适合 `animateTo` 的一次性状态变化，不提供
  PanGesture 的连续进度；在当前 `bindContentCover` 条件创建场景中，目标页可能直接
  以最终布局出现。
- `Play.playBuilder()` 根节点已是唯一的全屏 Stack，适合增加共享进度驱动的
  `scale/translate/borderRadius`；全屏左上角收起按钮目前直接写 `showPlay = false`，
  必须改为先反向动画、结束后关闭。

## SDK/文档证据

- API 26 SDK 的 `PanGesture` 支持 `PanDirection.Up`、`onActionStart`、
  `onActionUpdate`、`onActionEnd`，`GestureEvent.offsetY` 为相对起点的 vp 位移，
  可直接归一化为拖拽进度。
- `bindContentCover` 支持 `ModalTransition.NONE` 和自定义 `transition`；保留 NONE
  可去除默认上下滑入，但它本身没有交互式进度回调。
- 鸿蒙 geometryTransition 文档要求两个节点共享 id、配合 `animateTo` 和
  `transition`，并建议结束时清空 id；它是一次性共享元素转场，不足以单独驱动跟手
  拖拽。因此本任务把共享进度变换作为可见转场的稳定机制，geometryTransition 只作
  封面节点生命周期/兼容绑定，不再依赖它产生全部视觉结果。

## 结论

采用 `PlayerTransitionState` 在播放条和全屏 Builder 之间传递 `progress`，播放条注册
仅向上的 PanGesture，目标根节点以播放条底部中心为锚点做非透明度的缩放、位移和圆角
变化。普通点击和拖拽松手共用补全动画；全屏收起按钮反向补全后再关闭 modal。折叠
minibar 的普通点击保持透明命中并交给 HdsTabs，避免自定义 gesture 吞掉原生展开。
播放条根节点的 `geometryTransition("miniBar")` 与全屏封面转场无关，继续保留用于
Tab minibar 与非 Tab 条之间的条级过渡；仅删除 `playerCoverTransition` 那一组封面绑定。
