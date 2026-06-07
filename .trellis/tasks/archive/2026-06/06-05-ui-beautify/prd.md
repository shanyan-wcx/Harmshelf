# 提升UI美观度 — 玻璃质感 + API升级

## Goal

全面提升 Harmshelf 的 UI 视觉品质，统一采用玻璃质感（Frosted Glass / Glassmorphism）设计语言，并将 API 版本从 20 升级到 23。

## Requirements

### 1. API 版本升级 (20 → 23)
- **文件**: `build-profile.json5`
- `compatibleSdkVersion`: 保持 `"6.0.0(20)"`（兼容旧设备）
- `targetSdkVersion`: 升级到 `"6.1.0(23)"`
- 检查 API 23 的兼容性变更，确保现有代码无编译错误

### 2. 封面图片 → 玻璃质感卡片
所有封面图片改为玻璃卡片样式：

**Component.ets**
- `LibraryItemComponent` / `LibraryItemComponent1` — 图书/播客封面
- `SeriesItemComponent` — 系列封面
- `CollectionItemComponent` — 收藏封面
- `PlaylistItemComponent` — 播放列表封面
- `RecentEpisodeComponent` — 最新剧集封面
- `EpisodeComponent` / `EpisodeComponent1` — 剧集条目中的封面缩略图

**详情页**
- `EpisodeDetail.ets` — 剧集详情封面
- `PlaylistDetail.ets` — 播放列表详情封面
- `CollectionDetail.ets` — 收藏详情封面
- `LibraryItemDetail.ets` — 媒体详情封面
- `Search.ets` — 搜索结果封面缩略图

### 3. 人物头像 → 玻璃质感卡片
- `AuthorComponent` / `AuthorComponent1`（Component.ets）
- 与封面卡片使用相同的玻璃质感样式

### 4. 首页标题栏选择服务器 → 玻璃质感
- `Component.ets` 中 `titleBarBuilder()` 的 Select 组件

### 5. 回到顶部按钮 → 悬浮玻璃质感（增强）
现有这些按钮已初步具备 blur 和 shadow，需增强模糊半径、阴影深度、悬浮动效：

- `tabs/Library.ets`
- `tabs/Collection.ets`
- `tabs/Author.ets`
- `tabs/Series.ets`
- `tabs/Playlist.ets`
- `tabs/RecentEpisodes.ets`
- `FilterItems.ets`
- `LibraryItemDetail.ets`

### 6. 日志页底部按钮 → 悬浮玻璃质感
- `Log.ets` — filter Select、copy Button、share Button

### 7. 页面左右翻页按钮 (pageUpDown) → 玻璃质感
- `Component.ets` — `pageUpDown` 组件中的两个箭头按钮

### 8. 播放页控制按钮 → 玻璃质感背景
- `Play.ets` — 播放/暂停、快进、快退、进度条等控制按钮添加毛玻璃背景

### 9. Sheet 弹出面板 → 玻璃质感
- 所有使用 `bindSheet` 或 `CustomDialog` 的弹出面板
- `EpisodeComponent.ets` 中的播放列表/创建播放列表/确认下载
- `EpisodeDetail.ets` 中的对应面板
- `PlaylistDetail.ets` / `CollectionDetail.ets` 中的编辑面板
- `Setting.ets` 中的关于/添加服务器/编辑服务器面板
- `LibraryItemDetail.ets` 中的各种面板

### 10. 二维码 → 圆角
- `Setting.ets` 618、627: `Image($rawfile('wx_qr.png'))` 和 `Image($rawfile('alipay_qr.png'))`
- 添加 `.borderRadius(8)`

### 11. 标题栏 → 沉浸光感
所有 `HdsNavigation` / `HdsNavDestination` 的 titleBar `scrollEffectOpts` 增强沉浸模糊效果
- `Component.ets`（MyNavigation）
- `Search.ets`
- `EpisodeDetail.ets`
- `PlaylistDetail.ets`
- `CollectionDetail.ets`
- `LibraryItemDetail.ets`

### 12. 其他可美化的圆角矩形组件
逐一检查项目中所有使用 `borderRadius` 的组件，添加玻璃质感效果：
- 设置页卡片组（服务器设置、外观设置、播放设置、下载设置、其他设置）→ 玻璃背景替代纯色
- Sheet 中的按钮组
- 进度条颜色统一优化

## Acceptance Criteria

- [ ] API 23 编译通过，无兼容性错误
- [ ] 所有封面/头像组件呈现玻璃卡片质感（blur + 半透明背景 + shadow + borderRadius）
- [ ] 回到顶部按钮悬浮玻璃效果增强
- [ ] 日志页底部按钮悬浮玻璃效果
- [ ] pageUpDown 按钮玻璃质感
- [ ] 播放页控制按钮玻璃背景
- [ ] Sheet 弹出面板玻璃效果
- [ ] 二维码 borderRadius(8)
- [ ] 标题栏沉浸光感
- [ ] 首页 Select 选择器玻璃质感
- [ ] 整体 UI 视觉统一、无突兀

## Out of Scope

- 后台/服务端样式修改
- 新增功能（非 UI 美化）
- 动画/过渡效果（除非必须）
