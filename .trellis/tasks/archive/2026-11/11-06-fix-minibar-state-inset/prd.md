# 修复minibar切换延迟与非tab边距

## Goal

修复播放 minibar 在 HdsTabs 折叠/展开动画期间内容切换滞后的问题，并让无底部 tab 页面播放胶囊的内容左右视觉边距一致。用户应在动画开始时看到对应布局，非 tab 胶囊应保持既定的 20vp 外边距和正确的内部对齐。

## Confirmed Facts

- 当前实现使用 `HdsTabsMiniBar.onBarStyleChange`、`onMiniBarAnimationStart` 和 `onMiniBarAnimationEnd` 同时更新同一个状态。
- 官方 API 文档规定 `onMiniBarAnimationStart` 的 `style` 是“动效开始时”的状态，`onMiniBarAnimationEnd` 的 `style` 是“动效结束时”的状态；开始回调的值不是目标状态。
- 当前 `PlaybackMiniBar` 已通过 `@ObservedV2` 状态对象接收展开状态，但用户实测仍然在动画结束后才看到正确内容，说明剩余问题集中在 HdsTabs 回调时序/状态覆盖，而不是普通 boolean 传值。
- 非 tab 胶囊外层宽度为 `calc(100% - 40vp)`、最大 600vp；当前内部内容宽度为 `100%` 并向右偏移 8vp，右侧已对齐但左侧视觉留白过大。

## Requirements

1. minibar 从折叠切换到展开或从展开切换到折叠时，内容布局必须在原生动画开始阶段切换，不得等待动画结束或额外延迟。
2. 非 tab 胶囊保留外层 20vp 左右边距、最大宽度 600vp；内部封面、标题、副标题和右侧按钮整体左右视觉边距应平衡，且右侧当前对齐不能回退。
3. 保留 HdsTabs 原生折叠/展开动画、点击语义、现有播放按钮逻辑和 tab minibar 宽度策略；不引入第二套动画或固定宽度。
4. 只修改本问题相关的 minibar 状态与布局代码，保留现有跑马灯、裁切和沉浸光感行为。

## Acceptance Criteria

- [ ] 折叠 minibar 点击展开时，展开内容在原生展开动画开始后立即显示；收起时同样立即显示圆形封面态。
- [ ] 内容切换不会出现先显示旧布局、等待一段时间后再切换的现象，也不会在展开/收起之间闪回。
- [ ] 非 tab 胶囊右边距保持当前正确值，左边距明显收窄并与右侧视觉平衡；外层 20vp 边距和 600vp 最大宽度不变。
- [ ] 播放、快退、快进、展开条点击全屏等现有交互保持有效。
- [ ] DevEco API 26 debug 构建通过，工作树无未提交产品代码。

## Out of Scope

- 不重新设计 minibar 的视觉样式、按钮尺寸、跑马灯节奏或底部 tab 原生宽度。
- 不修改全屏播放页和其他页面的底部胶囊布局。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
