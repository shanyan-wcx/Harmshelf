# 修复非 Tab 播放条进度环位置

## Goal

让非 Tab 播放条的进度环覆盖封面，同时保持封面尺寸不变。

## Requirements

- 非 Tab 播放条的封面图片尺寸保持现状。
- 进度环覆盖在封面图片上，不再显示为封面外圈。
- minibar 现有封面和进度环样式不受影响。

## Acceptance Criteria

- [ ] 非 Tab 播放条进度环与封面同心并覆盖封面。
- [ ] 封面尺寸、播放条布局和点击逻辑不变。
- [ ] `git diff --check` 通过，工作区无未预期修改。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
