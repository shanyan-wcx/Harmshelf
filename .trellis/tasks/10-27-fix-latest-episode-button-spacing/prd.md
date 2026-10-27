# 修复最新页面剧集按钮间距

## Goal

让最新页面每个剧集卡片的四个操作按钮，与项目详情页剧集列表保持一致的 `16vp` 横向间距。

## Requirements

- 仅修改 `entry/src/main/ets/utils/Component.ets` 中 `EpisodeComponent` 的操作按钮行。
- 将按钮行的子项间距设置为 `16vp`，保持现有按钮尺寸、顺序、业务事件、弹层和卡片其他布局不变。
- 不修改项目详情页 `EpisodeComponent1` 或其他页面组件。

## Acceptance Criteria

- [ ] 最新页面播放、完成状态、播放列表、下载四个按钮之间均为 `16vp` 间距。
- [ ] 按钮行的主按钮仍使用剩余宽度，右侧三个固定按钮不变形、不溢出。
- [ ] 原有点击行为和弹层行为保持不变。
- [ ] `git diff --check` 通过。

## Out of Scope

- 不调整按钮高度、圆角、图标、沉浸光感实现或页面整体间距。
