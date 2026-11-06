# 修复播放器minibar状态与全屏转场

## Goal

修复minibar反复展开偶发内容延迟、收起动画期间误触打开全屏，以及从minibar/非Tab条进入全屏时应使用条变形为页面的共享元素转场。

## Background

- `MyNavigation` 在 `Component.ets` 中通过 `onMiniBarAnimationStart`、
  `onMiniBarAnimationEnd` 和 `onBarStyleChange` 同步 `MiniBarState.expanded`。
  官方文档定义 start 回调的 `style` 是动画开始时的状态，end 回调的 `style` 是
  动画结束时的状态。
- HdsTabs 回调没有向业务层提供动画序号；快速反向操作时，旧动画的 end 回调可能
  晚于新动画 start 回调到达。当前实现无条件接受 end 状态，因此偶发把最终状态
  覆盖成旧状态。
- `PlaybackMiniBar` 当前只根据 `expanded` 判断封面、标题和根节点的交互，动画
  进行状态没有传入播放器组件；因此收起过程中仍可能命中 `openPlayer()`。
- 全屏封面与 minibar 封面已经使用同一个 `geometryTransition` id，并在
  `animateTo` 中打开 `bindContentCover`，但当前还叠加了 `Opacity` transition，
  视觉上会先虚化/淡入，而不是条到页面的几何变形。

## Requirements

- 反复展开/收起 minibar 后，展开态必须稳定显示完整的封面、标题、副标题和三个
  播放控制，不得出现只剩中间封面、随后延迟补齐内容的状态。
- 对快速反向操作建立期望目标样式，过期的 start/end 回调不得覆盖当前目标；只有
  与当前目标一致的结束回调才能结束动画态并提交最终 Builder 状态。
- minibar 的展开/收起动画期间禁止打开全屏播放页；动画结束后恢复对应状态下的
  正常点击行为。快退、播放、快进按钮的点击逻辑保持不变。
- 从展开 minibar 或非 Tab 播放条进入全屏播放页时，使用当前条内封面与全屏封面的
  共享元素几何转场，让播放条内容自然变形到全屏页面；去掉造成虚化/淡入观感的
  额外透明度动画，不叠加默认 ContentCover 模态动画。
- 保留 HdsTabs 原生 minibar 展开/收起动画、非 Tab 条当前宽度（`+22vp`）、播放
  状态源、全屏关闭逻辑和既有页面布局；不新增依赖。

## Acceptance Criteria

- [ ] 连续快速执行多次展开/收起后，每次展开都在动画结束时显示完整 expanded 内容，
      无只显示封面或延迟补齐。
- [ ] 在展开变收起的动画任意时刻点击封面、标题或播放条空白区域，都不会打开
      全屏播放页；动画结束后 expanded 状态点击仍可打开全屏，collapsed 状态仍由
      HdsTabs 处理展开。
- [ ] 从 minibar/非 Tab 条打开全屏时，封面沿条的当前位置、尺寸和圆角几何变化到
      全屏封面；不出现以透明度为主的虚化淡入效果。
- [ ] 快退、播放、快进、关闭全屏播放器、minibar 到非 Tab 条切换等既有行为不回归。
- [ ] DevEco CLI API 26 debug 构建成功，任务提交、归档后工作区干净。

## Out of Scope

- 不改变 HdsTabs 的原生 `barWidth`/`miniBarWidth`、bottom tab 布局或非 Tab 条的
  左右边距。
- 不重写全屏播放页的控件、背景、sheet 和播放业务状态。
- 不增加自定义定时器或第二套 minibar 动画；真机视觉差异记录为验证风险。

