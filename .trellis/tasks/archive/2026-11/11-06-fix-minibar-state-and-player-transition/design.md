# 技术设计

## 根因与边界

播放器 minibar 的可见内容由 `Component.ets` 的 HdsTabs 回调驱动，实际渲染和点击
逻辑在 `Play.ets`。当前回调只把 `expanded` 传给播放器，动画是否进行中没有进入
同一条反应式状态链；因此播放器无法在收起动画阶段禁用打开全屏的命中区域。
此外，HdsTabs 回调没有动画序号，快速反向操作时旧 end 回调可能晚到，当前代码会
无条件写回旧样式；这解释了“多次操作后偶发一次”的非确定性。最后，`barBuilder()`
在展开/收起时切换两个不同的根节点，状态被旧回调覆盖时会进一步放大为只绘制封面、
文本和控制稍后才补齐。

全屏封面共享元素绑定已经正确使用 `animateTo` 和 `ModalTransition.NONE`，但源/目标
封面使用 `TransitionEffect.OPACITY.animation(...)`，所以用户看到的是透明度淡入而非
几何变形。官方 `geometryTransition` 要求参与转场的节点设置 `transition` 以延迟析构；
这里改用无视觉变化的 `TransitionEffect.IDENTITY`，保留节点生命周期，同时让共享几何
动画承担位置、尺寸和圆角变化。

## 方案

1. 扩展 `MiniBarState`，增加 `@Trace animating` 和当前期望的 `targetStyle`。
   HdsTabs start 回调根据 start 的旧样式计算目标并记录；end 回调只接受与
   `targetStyle` 一致的样式，旧动画回调直接丢弃。`onBarStyleChange` 在动画期间
   不覆盖目标，动画结束后再同步普通样式。
2. 让 `PlaybackMiniBar` 读取同一个状态引用：动画中将 cover、标题区域和稳定的
   minibar 根节点设为不可命中，`openPlayer()` 也做同样的状态保护。collapsed 状态
   不注册会吞掉 HdsTabs 手势的自定义点击，仍由原生 HdsTabs 负责展开。
3. 将 expanded/collapsed 两个根 Builder 合并为一个稳定的 `Row` 根节点，只按状态
   增减标题和控制内容，保留原有封面、尺寸、间距、`miniBar` 几何转场和非 Tab
   `+22vp` 宽度校正，避免反复切换时替换整个根节点。
4. 保留 `playerCoverTransition` 仅用于打开全屏的 `animateTo` 事务；将 minibar 源
   封面与全屏三个封面分支的 transition 改为 `TransitionEffect.IDENTITY`，保持同一
   `geometryTransition` id、稳定分支 id 和 `ModalTransition.NONE`。动画完成后清除源
   绑定，避免后续 minibar 状态切换误用共享元素。

## 影响与回滚

- 预计只修改 `entry/src/main/ets/utils/Component.ets`、
  `entry/src/main/ets/pages/Play.ets` 及对应规范/任务记录。
- 不改变播放数据、AVPlayer/AVSession 回调、全屏 sheet、底部 tab 原生宽度或非 Tab
  容器外边距。
- 若 API 26 构建不接受 `TransitionEffect.IDENTITY`，回退为官方要求的非动画
  transition 表达并保留 geometry 绑定；代码提交前以 DevEco 构建结果为准。
