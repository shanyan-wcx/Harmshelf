# 恢复 minibar 原生展开收起与全屏默认动画

## Goal

恢复播放 minibar 的原生展开/收起交互与全屏播放页默认系统动画。

## Requirements

- 修复当前 minibar 无法正常展开/收起的问题，恢复 HdsTabs 原生状态切换。
- 删除 minibar/非 Tab 播放条向上拖拽渐进打开全屏的逻辑及共享进度转场。
- 播放条点击打开全屏播放页，点击全屏左上角关闭按钮关闭全屏。
- 全屏打开和关闭使用 `bindContentCover` 的系统默认动画，不保留自定义缩放、圆角或拖拽动画。
- 保留 Tab minibar 与非 Tab 播放条之间已有的 `geometryTransition("miniBar")`。
- 不改变播放控制按钮、标题、副标题和播放逻辑。

## Acceptance Criteria

- [ ] 手机/平板 HdsTabs minibar 可以正常点击展开与收起。
- [ ] 展开状态和非 Tab 播放条点击后能打开全屏播放页。
- [ ] 全屏左上角按钮可以关闭全屏并回到播放条。
- [ ] 播放条不存在向上拖拽渐进打开全屏的行为。
- [ ] API 26 Debug 构建通过，工作区无未预期改动。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
