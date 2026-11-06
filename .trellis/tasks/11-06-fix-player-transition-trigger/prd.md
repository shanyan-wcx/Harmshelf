# 修复播放器转场未触发并调整非tab宽度

## Goal

将非 Tab 播放条内部宽度从 +24vp 调整为 +22vp，并修复从展开 minibar 或非 Tab 条进入全屏播放页时共享封面转场不触发的问题。

## Requirements

- 将非 Tab 播放条内容根节点宽度从 `calc(100% + 24vp)` 调整为
  `calc(100% + 22vp)`，保留其现有最大宽度、左右屏幕边距和整体定位。
- 从展开 minibar 或非 Tab 播放条点击进入全屏播放页时，显示共享封面从条内位置到
  全屏封面位置的转场，不再瞬间切换或无动画出现。
- 保留现有 minibar 展开/收起动画、播放条之间的几何转场、封面圆形裁切和所有点击
  行为；不要重新引入 minibar 在页面切换时闪到中间的问题。
- 只修改播放器相关实现，不新增依赖，不改变播放业务逻辑。

## Acceptance Criteria

- [ ] 非 Tab 条内容宽度比当前减少 2vp，条仍保持原有最大宽度和屏幕边距。
- [ ] 展开 minibar/非 Tab 条点击全屏播放时，封面共享转场可见，且没有默认的整页
      瞬间切换遮盖它。
- [ ] minibar 与非 Tab 条互相切换时封面不闪回、不参与错误的几何转场。
- [ ] 播放、快退、快进、关闭全屏页等既有交互保持不变。
- [ ] DevEco CLI debug 构建成功，工作区在提交和任务归档后保持干净。

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
