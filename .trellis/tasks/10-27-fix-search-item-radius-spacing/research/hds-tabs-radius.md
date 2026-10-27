# HdsTabs 原生沉浸材质圆角研究

## 来源

- 本机 DevEco SDK：`default/hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`
- 鸿蒙 HDS 文档：`HdsTabs` 的悬浮样式 `barFloatingStyle`

## 结论

`HdsTabsFloatingStyle` 在 API 6.1.0(23) 仅提供以下字段：

- `barWidth`
- `barSideMargin`
- `barBottomMargin`
- `gradientMask`
- `miniBar`
- `adaptToHandedness`
- `lightColor`
- `systemMaterialEffect`
- `thermoCtrl`
- `barOpacity`

没有 `barRadius` 或 `cornerRadius`。`SystemMaterialParams` 也只有 `materialType` 和 `materialLevel`。因此不能通过给 `barFloatingStyle` 传入额外字段修改原生悬浮材质形状。

当前共享组件的 `barRadius` 是本地 `ImmersiveActionButton` 参数，只作用于自定义 tab builder 的 `Stack`；原生材质挂在外层 `HdsTabs`，两层形状不一致时会继续显示系统默认胶囊。

## 本任务决策

实际验证表明，继续通过 `ImmersiveActionButton` 的参数控制搜索项，仍无法可靠改变原生 HdsTabs 的胶囊形状、高度和内边距。搜索结果因此放弃沉浸光感按钮方案，改用普通 `Row` 卡片；使用项目已有的 `backgroundBlurStyle`、`border`、`borderRadius`、`clip` 和 `onClick`，让视觉和几何尺寸完全由页面代码控制。

该取舍只作用于搜索结果，不影响其他页面继续使用 `ImmersiveActionButton`。

## 手动卡片视觉实现

项目现有代码和 ArkUI SDK 支持以下组合：

- `backgroundBlurStyle(BlurStyle.COMPONENT_THICK)` 提供组件级毛玻璃；卡片背景改用系统主题自适应的 `sys.color.ohos_id_color_card_bg`，使用系统语义化卡片层级。
- `border({ width: 0.5, radius: 12, color: $r('sys.color.ohos_id_color_focused_outline_transparent') })` 提供主题自适应的细高亮边界，避免深色模式下固定白框过粗。
- `shadow(ShadowStyle.OUTER_DEFAULT_XS)` 使用 ArkUI 系统微小阴影预设，减少沉积感并保持轻微悬浮层次。
- 卡片不设置 `clip(true)`，否则阴影可能被自身边界裁掉；封面图片独立设置圆角即可。
- 搜索卡片使用系统层级背景和主题自适应细边框，阴影使用系统微小阴影预设；文字颜色不改。

## 关联代码

- `entry/src/main/ets/utils/Component.ets`：共享 HDS 按钮
- `entry/src/main/ets/pages/Search.ets`：书籍和播客搜索结果调用点
- `entry/src/main/ets/pages/tabs/Add.ets`：播客添加结果项调用点
- `entry/src/main/ets/pages/LibraryItemDetail.ets`：章节和音轨列表调用点
