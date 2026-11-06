# 修复非 Tab 进度环与封面外圈重合

## Goal

让非 Tab 播放条展开态进度环外圈与封面外圈完全重合。

## Requirements

- 非 Tab 展开态封面保持 `44vp` 尺寸不变。
- 非 Tab 展开态进度环改为与封面相同的 `44vp`，外圈完全重合。
- minibar 收起态仍保持原有 `56vp` 封面与进度环尺寸。

## Acceptance Criteria

- [ ] 非 Tab 播放条进度环外圈与封面外圈完全重合。
- [ ] 收起态 minibar、播放条布局和交互不受影响。
- [ ] `git diff --check` 通过，工作区无未预期修改。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
