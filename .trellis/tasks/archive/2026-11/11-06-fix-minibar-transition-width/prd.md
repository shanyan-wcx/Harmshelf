# 修复minibar切换闪烁与非tab宽度

## Goal

修复从底部 Tab minibar 切换到非 Tab 播放胶囊时封面瞬间跳到条中间的闪烁，并进一步收窄非 Tab 条内容左右视觉边距。

## Requirements

- 保留现有 HdsTabs 原生展开/收起动画和播放逻辑，不新增第二套动画。
- 切换到非 Tab 条时，封面和内容应沿现有 `geometryTransition("miniBar")` 平滑过渡，不出现先居中再回位的闪烁。
- 非 Tab 条外层两侧 `20vp`、最大宽度 `600vp` 和当前右侧对齐保持不变，内部内容宽度在现有基础上再增加 `8vp`。
- 仅修改 minibar 过渡几何与宽度相关代码，并保持 Tab minibar 布局不变。

## Acceptance Criteria

- [ ] Tab minibar 切换到非 Tab 条时封面无中间跳闪，过渡连续。
- [ ] 非 Tab 条右侧位置不回退，左侧边距再缩小约 8vp。
- [ ] 展开/收起、点击打开全屏播放、播放控制和跑马灯行为保持正常。
- [ ] DevEco API 26 debug 构建通过，产品代码已提交，任务已归档。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
