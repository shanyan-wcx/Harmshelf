# 统一最新页面剧集按钮样式

## Goal

让首页“最新”页面每个剧集卡片的播放、完成状态、播放列表和下载按钮，与项目详情页剧集列表使用同一套沉浸光感按钮样式。

## Background

- “最新”页面 `pages/tabs/RecentEpisodes.ets` 使用 `EpisodeComponent`。
- 项目详情页使用 `EpisodeComponent1`，其四个剧集操作按钮已经通过共享的 `ImmersiveActionButton` 实现，按钮尺寸为 38vp。
- `EpisodeComponent` 当前仍使用普通 `Button`，因此两处视觉、圆角和原生按压反馈不一致。

## Requirements

- 仅修改最新页面使用的 `EpisodeComponent` 中四个剧集操作按钮。
- 复用 `ImmersiveActionButton`，与 `EpisodeComponent1` 保持相同的 38vp 尺寸、图标居中、事件拦截和裁切策略。
- 保留现有播放、完成状态切换、播放列表弹层和下载弹层行为。
- 保留最新页面现有剧集卡片、封面、文字内容、间距和列表布局。
- 不新增依赖，不修改项目详情页已有按钮样式。

## Acceptance Criteria

- [ ] 最新页面每个剧集的四个操作按钮均显示为原生沉浸光感样式。
- [ ] 主播放按钮与三个图标按钮的尺寸、圆角规则、图标颜色和布局与项目详情页剧集列表一致。
- [ ] 四个按钮原有点击行为和弹层行为不变，点击卡片其他区域仍可进入剧集详情。
- [ ] 最新页面卡片其他内容和布局无非必要变化。
- [ ] ArkTS 类型检查/项目构建或等价静态检查通过，且 `git diff --check` 无错误。

## Out of Scope

- 不调整项目详情页、剧集详情页或首页其他剧集组件。
- 不改变按钮高度、间距、卡片结构或业务逻辑。
