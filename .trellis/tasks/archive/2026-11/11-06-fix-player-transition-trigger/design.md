# 技术设计

## 根因

当前实现已经把 minibar 封面和全屏播放器封面绑定到同一个
`geometryTransition('playerCoverTransition')`，并在 `animateTo` 事务中设置
`showPlay`。但 `bindContentCover` 使用 `ModalTransition.NONE`，几何绑定节点没有
配套的可见 `transition`，因此内容覆盖层插入后可能直接显示最终布局，用户看不到
封面转场。

## 最小修复

1. 在 minibar 的共享封面节点和全屏播放器三个互斥封面分支上增加同一套透明度
   transition，让 `geometryTransition` 在内容覆盖层出现时拥有可见的动画事务。
2. 保持 `playerCoverTransition` 只在打开播放器的 `animateTo` 事务中为真，关闭后
   清空；不把 geometry id 恢复为常驻值。
3. 将独立（非 Tab）播放条根节点宽度的 `+24vp` 改成 `+22vp`。

## 不做的事情

- 不新增自定义手势、定时器、第二层封面或背景动画。
- 不改变 HdsTabs 的 `barWidth`/`miniBarWidth`，不改变 minibar 展开收起动画。
- 不修改全屏播放页的封面比例、控件布局和播放状态。

## 风险与验证

ArkUI 的共享元素动画必须在真实设备上确认视觉效果；静态构建只能验证 API 和
ArkTS 语法。先做代码级状态/节点配对检查，再执行 DevEco CLI 构建。
