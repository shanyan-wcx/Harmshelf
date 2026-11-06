# 去除minibar封面过渡并增加非tab宽度

## Goal

去除播放 minibar 封面自身的几何转场，避免从 Tab minibar 切换到非 Tab 条时封面闪到中间；同时继续扩大非 Tab 条内部内容宽度。

## Requirements

- 保留 minibar 条根节点的 `geometryTransition("miniBar")`，只移除封面图片自身的 `geometryTransition("cover")`。
- 非 Tab 条内容宽度在当前 `calc(100% + 16vp)` 基础上再增加 8vp，改为 `calc(100% + 24vp)`。
- 保持外层两侧 `20vp`、最大宽度 `600vp`、Tab 模式布局、按钮交互和播放逻辑不变。

## Acceptance Criteria

- [ ] Tab minibar 到非 Tab 条切换时，封面不再独立闪到中间。
- [ ] minibar 条整体过渡仍然保留。
- [ ] 非 Tab 内容宽度增加 8vp，右侧和外层布局不被意外改变。
- [ ] DevEco API 26 debug 构建通过，产品代码已提交，任务已归档。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
