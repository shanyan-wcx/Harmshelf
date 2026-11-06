# 实现计划

1. 复核 `Component.ets` 的 HdsTabs 三个 minibar 回调和 `Play.ets` 的所有打开全屏
   入口，确认没有遗漏调用方。
2. 在 `MiniBarState` 中增加可观察动画态和期望目标样式；修正 start/end 回调的
   状态时序，丢弃快速反向操作产生的过期回调，并加入全屏点击命中保护。
3. 将 `PlaybackMiniBar` 的展开/收起根节点合并为稳定根，保持 collapsed/expanded
   的视觉尺寸和非 Tab `+22vp` 布局；所有打开全屏入口统一经过保护函数。
4. 将共享封面的透明度 transition 替换为 `TransitionEffect.IDENTITY`，并在
   `animateTo` 完成后清空源 geometry id；保留目标分支稳定 id 与 ContentCover 配置。
5. 搜索 `MiniBarState`、`miniBarBuilder`、`openPlayer`、`playerCoverTransition` 和
   `+22vp` 的全部调用点，执行 `git diff --check`。
6. 使用 DevEco CLI 执行 API 26 debug 构建；如构建通过，运行 Trellis check，检查
   状态链、触摸穿透和原生 HdsTabs 宽度没有回归。
7. 更新前端组件规范记录本次“动画态必须进入共享状态、geometryTransition 使用
   identity 保持节点但不做 opacity 淡入”的约束，提交、归档任务并记录会话。

## 风险检查

- 稳定根节点可能影响 HdsTabs 原生根尺寸插值，需重点检查 tab minibar 展开/收起和
  非 Tab 条宽度。
- 真实设备才能确认 HdsTabs 在动画中是否把命中区域交给原生容器；无设备时至少以
  API 26 构建和代码状态链检查作为验证，并在交付时明确该限制。
