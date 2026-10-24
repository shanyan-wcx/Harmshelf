# 首页标题栏沉浸光感分段按钮

## Goal

在首页标题栏底部提供与首页内容 tabs 同步的沉浸光感分段按钮，让用户无需回到内容区即可切换首页 tab；进入统计、本地、日志或设置等其他一级页面时不显示该控件。

## Background and confirmed facts

- `entry/src/main/ets/pages/Home.ets` 使用 `HdsTabs` 渲染首页 tabs，并通过根组件提供的 `topTabIndex` 保存当前选中索引。
- `Home.ets` 的 tab 列表会随媒体类型、用户权限和播放列表是否存在而变化：书籍与播客的 tab 名称及顺序不同，管理员可见额外 tab，播放列表只在有数据时显示。
- `entry/src/main/ets/utils/Component.ets` 的 `MyNavigation` 统一承载所有一级页面，并配置 `HdsNavigation.titleBar`，因此可用 `pageIndex === 0` 限制首页标题栏底部区域。
- 鸿蒙文档规定 `HdsNavigation.titleBar.content.bottomBuilder` 用于标题栏下方自定义区域；`TabSegmentButtonV2` 支持 `selectedIndex` 与 `$selectedIndex` 双向同步；`backgroundSystemMaterial` 可配置 `uiMaterial.ImmersiveMaterial`。
- 工程目标 SDK 为 26.0.0，兼容 SDK 为 6.0.0(20)，满足上述 API 的版本要求。

## Requirements

1. 在 `MyNavigation` 的 `HdsNavigation.titleBar.content` 中使用 `bottomBuilder` 添加 `TabSegmentButtonV2`。
2. 分段按钮启用沉浸光感材质，使用 ArkUI 的 `uiMaterial.ImmersiveMaterial` 配置，不新增依赖或资源。
3. 分段按钮选项必须与当前首页实际显示的 tabs 一致，包括书籍/播客差异、管理员权限差异和播放列表条件；选项顺序与 `Home.ets` 相同。
4. 点击分段按钮时更新共享的 `topTabIndex`，并触发现有首页数据刷新机制，使 `HdsTabs` 切换到对应内容。
5. 点击首页原有 `HdsTabs` 时，分段按钮的选中项同步更新。
6. 仅 `pageIndex === 0` 的首页显示标题栏底部区域；其他一级页面不显示，也不保留空白底部区域。
7. 保持现有标题栏主内容、菜单、返回按钮策略和其他页面行为不变。

## Acceptance Criteria

- [x] 首页书籍库中，分段按钮选项与当前可见的首页 tabs 逐项一致；播客库同样一致。
- [x] 管理员/普通用户及有无播放列表时，分段按钮数量、名称和顺序随首页 tabs 一致变化。
- [x] 点击任一分段按钮后，首页 `HdsTabs` 切换到同一索引；点击原有 tab 后，分段按钮高亮同一选项。
- [x] 从首页切换到统计、本地、日志或设置后，标题栏底部的分段按钮及其占用空间消失；返回首页后恢复。
- [x] 通过 `devecocli build` 编译检查，无新增 ArkTS 编译错误；API 26 沉浸材质调用已用 `deviceInfo.apiAvailable('26.0.0')` 保护。

## Out of scope

- 不重构现有 `HdsTabs` 的 tab 定义或数据加载逻辑。
- 不调整首页 tab 的文案、顺序、权限规则或现有视觉样式。
- 不新增持久化配置、用户自定义 tab 或其他页面的分段导航。

## Open questions

- None. `TabSegmentButtonV2` is selected because the requested options are page tabs; existing repository state and the HarmonyOS documentation determine the dynamic option set and synchronization source.
