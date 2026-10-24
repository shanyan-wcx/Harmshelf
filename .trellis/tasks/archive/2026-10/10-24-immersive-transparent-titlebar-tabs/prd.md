# 全局透明沉浸标题栏与首页 Tabs

## Goal

参考 qingye-reader 的分层布局，把 Harmshelf 的主导航和普通二级页面标题栏统一为 API 23 的透明沉浸光感效果；媒体详情页保留渐变模糊例外。首页自定义内容 tabs 保持在标题栏下方的内容区顶部，并保持现有页面切换与本项目配色。底部已有主导航 Tabs 不属于本次修改范围。

## Requirements

1. 主导航及普通二级页面的 `HdsNavigation` / `HdsNavDestination` 标题栏使用统一的 API 23 透明沉浸样式；`LibraryItemDetail.ets` 使用 `ScrollEffectType.GRADIENT_BLUR`，保留标题栏工具的沉浸光感材质。
2. 标题栏始终显示，不因页面滚动自动隐藏；保留现有标题、返回/菜单与页面滚动绑定行为。
3. 首页不再通过标题栏 `bottomBuilder` 放置 Tabs。首页只保留一组位于标题栏下方的自定义内容 tabs；标准 ArkUI `Tabs` 如保留，仅作为沉浸材质底板，底部主导航保持独立，标签仍由当前媒体类型、用户权限和播放列表动态决定。
4. 首页 Tabs 与既有 `topTabIndex`、`needUpdate` 状态同步，点击 Tabs 仍切换现有首页内容，不能产生重复导航或第二组 Tabs。
5. 首页自定义 tabs 使用本项目现有配色，保留用户要求的左右 16vp 内边距；使用标准 `Tabs.barFloatingStyle` 的原生悬浮栏圆角和 `uiMaterial.ImmersiveMaterial` 作为底板，同时将 `maskColor` 设为透明、`maskHeight` 和 `barBottomMargin` 设为 0 并关闭阴影；可见标签使用 36vp 自定义等宽文本 Row，选中态使用单独的 20x3vp 指示条，不让标准 tab bar 样式渲染文字或下划线。
6. 首页内容区可以绘制并滚动到顶部状态栏区域，透明标题栏下可看到内容；首屏内容不能被标题栏和顶部内容 Tabs 遮挡。
7. 左上角媒体库选择器所在容器不得裁切 Select 的底部阴影。
8. 不改变媒体数据加载、分页、播放列表、导航菜单和其他页面的业务行为；所有页面内容背景扩展到顶部状态栏区域，标题栏工具仍避让状态栏。

## Acceptance Criteria

- [x] `devecocli build` 以最终 API 23 配置通过，无新增 ArkTS 编译错误；构建仅保留项目现有及 API 版本相关提示。
- [x] 普通标题栏调用统一 API 23 透明沉浸样式，媒体详情页使用渐变模糊例外；源码中没有为本需求新增 `dynamicHideTitleBar` 或其他标题栏滚动隐藏逻辑。
- [x] `bottomBuilder` 不再承载首页 Tabs；只有首页渲染悬浮 Tabs，其他页面不显示。
- [x] 首页标签数量/文字与原有逻辑一致，点击与 `topTabIndex` 双向同步，已有内容页面仍正确切换。
- [ ] 首页首屏内容不被标题栏/顶部内容 Tabs 覆盖，并能滚动到状态栏下方；各 Scroll/Grid 保持 edge-to-edge，仅在原有 top padding 上增加 `statusBarHeight + 56`；标题栏不会随滚动隐藏。（无可用设备，未完成视觉验证）
- [x] 首页内容 tabs 保留 `targetSdkVersion=26.0.0` 与 `compatibleSdkVersion=6.1.0(23)` 的配置关系；使用 36vp 自定义 tab builder，标签未溢出时通过 `layoutWeight(1)` 等宽填满，溢出时使用内容安全宽度交给原生 `BarMode.Scrollable`，播放列表文字完整可见；20x3vp 指示条和文字状态使用 `Curve.Friction` 组件动画；沉浸材质底板的渐变蒙层和阴影已关闭，不使用标准 tab bar 的默认文字/下划线样式，不引入新依赖。
- [x] `git diff --check` 通过，且未覆盖用户已有的 `.padding({left: 16, right: 16})` 代码。
- [x] 媒体库选择器父容器不再启用裁切。

## API 版本说明

项目的 `targetSdkVersion` 保持 26.0.0，`compatibleSdkVersion` 按当前任务固定为 6.1.0(23)，表示兼容基线；它不应被降回旧的 6.0.0(23)。标准 `Tabs` 仅使用 `barFloatingStyle` 提供原生圆角和沉浸材质底板，透明蒙层用于去除周围渐变模糊；文字、点击和指示条由 36vp 自定义 Row 控制。

## Out of Scope

- 不重做标题栏按钮、菜单内容、页面数据请求或播放业务。
- 不为了“看起来一致”改动所有二级页面已有的内容顶部间距；只处理首页为沉浸滚动必须处理的安全区。
- 不添加第三方依赖，也不复制 qingye-reader 的业务代码。

## Notes

- Created: 2026-10-24
- Status: in progress, pending final build and commit confirmation
- Reference: https://github.com/wip3l/qingye-reader
