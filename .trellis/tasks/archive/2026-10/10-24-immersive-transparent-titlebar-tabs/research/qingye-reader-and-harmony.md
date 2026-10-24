# 研究记录：参考项目与鸿蒙 API

## 参考项目

来源：[wip3l/qingye-reader](https://github.com/wip3l/qingye-reader)

README 明确描述了该项目在书架、发现、搜索等页面使用系统沉浸光感材质，并将页面脚手架、首页内容区和沉浸材质表面拆开。用户本次明确要求标题栏不滚动隐藏，因此只采用透明沉浸材质和首页 Tabs 的布局方向，不复制其隐藏标题栏行为。

已通过只读拉取仓库当前源码核对 `entry/src/main/ets/pages/Index.ets`。其底部主导航使用 HDS Tabs；qingye-reader 的顶部内容区另有自定义标题/分类控件，不能把底部主导航的位置套给 Harmshelf 的首页内容 Tabs。本项目内容 Tabs 仍在 `Home.ets` 根 `Stack`、标题栏下方渲染，改用标准 ArkUI `Tabs` 的原生悬浮圆角。

## 官方 API 依据

- `HdsNavigation` 标题栏文档：`ScrollEffectType.IMMERSIVE_GRADIENT_BLUR` 适用于沉浸式图片/文字场景；`systemMaterialEffect` 从 API 23 起提供系统材质效果；`enableScrollEffect` 控制视觉样式过渡，不等同于隐藏标题栏。媒体详情页本任务使用 `ScrollEffectType.GRADIENT_BLUR` 作为唯一例外。
- 标准 Tabs：使用 `barOverlap(true)`、`barPosition(BarPosition.End)`、`barFloatingStyle` 与 `fadingEdge(true)`，适合将 Tabs 叠放在内容上方并提示横向溢出；本次保留 `uiMaterial.ImmersiveMaterial`，但关闭默认渐变蒙层。
- 本次首页内容 Tabs 使用 36vp 高的标准 Tabs 承载 `End` 页签栏，并由每个 `TabContent` 的自定义 builder 绘制文字和 indicator，再放置到标题栏下方，不改变底部主导航。标准悬浮栏自带圆角，不增加外层裁切。
- `expandSafeArea` 文档：可让组件绘制扩展到系统安全区，但不改变子组件布局；配合滚动容器处理首页内容穿透。

官方文档入口：

- https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsnavigation
- https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs
- https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-expand-safe-area
- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating

## 本项目影响面

- 共享主导航：`entry/src/main/ets/utils/Component.ets`
- 首页 Tabs/顶部安全区：`entry/src/main/ets/pages/Home.ets`
- 二级标题栏：`entry/src/main/ets/pages/CollectionDetail.ets`、`Download.ets`、`EpisodeDetail.ets`、`FilterItems.ets`、`LibraryItemDetail.ets`、`Search.ets`、`PlaylistDetail.ets`
- 状态契约：`topTabIndex`、`needUpdate` 由 `Index.ets` 提供，首页和主导航共享。
- 选择器裁切：`MyNavigation.titleBarBuilder` 的内层 Row 不得使用 `clip(true)`，否则 Select 底部阴影会被父容器边界裁切。
