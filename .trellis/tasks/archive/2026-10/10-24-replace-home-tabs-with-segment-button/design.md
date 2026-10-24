# 技术设计：首页仅使用标题栏分段按钮切换

## 目标边界

保留 `Index.ets` 中的 `topTabIndex` 和 `needUpdate` 作为跨组件状态源。`MyNavigation` 继续负责标题栏 `TabSegmentButtonV2`，`Home` 改为根据同一索引直接渲染一个首页内容组件，不再通过 `HdsTabs` 承载内容切换。

## 数据流

```text
Index.ets Provider
  ├─ MyNavigation Consumer: TabSegmentButtonV2 selectedIndex
  └─ Home Consumer: 当前内容索引

TabSegmentButtonV2 点击
  → topTabIndex = index
  → needUpdate 翻转
  → Home 监视器加载对应数据
  → Home 根据 topTabIndex 渲染对应内容组件
```

不增加新的状态字段，也不修改 API 数据加载协议。

## 内容映射

| 媒体类型 | 索引 | 内容 |
| --- | ---: | --- |
| book | 0 | `SubHome` |
| book | 1 | `MediaLibrary` |
| book | 2 | `AllSeries` |
| book | 3（管理员） | `AllCollections` |
| book | 3（普通用户）或 4（管理员） | `AllAuthors` |
| book | `getHomeTabLabels(...).length - 1`（有播放列表） | `AllPlaylists` |
| podcast | 0 | `SubHome` |
| podcast | 1 | `RecentEpisodes` |
| podcast | 2 | `MediaLibrary` |
| podcast | 3（管理员） | `Add` |
| podcast | `getHomeTabLabels(...).length - 1`（有播放列表） | `AllPlaylists` |

用 `@Builder` 的小型内容分支承载映射，避免在 `build()` 中保留两套重复的 HdsTabs/TabContent 声明；每次只构建当前索引对应的页面。

## 顶部对齐

保留 `HdsNavigation` bottomBuilder 的 56 高度和 `Row` 的左右 16 padding。将按钮容器的垂直交叉轴设置为 `VerticalAlign.Top`，继续用 `justifyContent(FlexAlign.Center)` 控制水平方向，使按钮顶部落在原 `HdsTabs` `BarPosition.Start` 的起始边上。

## 兼容与回滚

- 保留首页标题栏显示条件、沉浸材质和已验证的选中背景色资源。
- 如构建或 UI 验证发现内容索引问题，回滚点为 `Home.ets` 的内容分支替换；`Component.ets` 的标题栏控件状态接口不需改动。
