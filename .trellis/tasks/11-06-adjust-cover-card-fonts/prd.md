# 调整封面卡片标题作者字号与圆角

## Goal

统一封面卡片标题/作者字号，并将收藏与播放列表详情封面圆角对齐搜索项。

## Requirements

- 收藏详情页与播放列表详情页列表项封面圆角改为与搜索结果封面一致的 10vp。
- 系列、收藏、播放列表卡片的沉浸光感标题字号统一为 16vp。
- 首页媒体卡片、首页继续收听/最新剧集卡片、搜索结果卡片、添加页面结果卡片、收藏详情列表项、播放列表详情列表项：标题字号统一为 16vp，作者/副标题字号统一为 13vp。
- 作者卡片作者名自适应字号范围改为 12vp–16vp。
- 保留现有布局、交互、颜色和其他字号不变。

## Acceptance Criteria

- [x] 目标组件的源码字号和圆角均符合上述要求。
- [x] 未修改目标之外的布局、交互和样式。
- [x] 完成源码检查并提交修改。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
