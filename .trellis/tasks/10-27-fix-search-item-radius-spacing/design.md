# 技术设计

## 边界

修改 `Search.ets` 中书籍/播客两处结果项、`tabs/Add.ets` 中播客添加结果项，以及 `LibraryItemDetail.ets` 中章节/音轨列表的布局和点击容器。共享 `ImmersiveActionButton` 保留给其他页面使用，不改其公共接口。

## 组件设计

搜索结果不再使用 `ImmersiveActionButton`，直接用一个普通 `Row` 作为卡片容器：

1. 使用 `.backgroundBlurStyle(BlurStyle.COMPONENT_THICK)`，叠加系统主题自适应的 `sys.color.ohos_id_color_card_bg` 背景资源；页面底色为 `background_secondary`，卡片使用系统卡片层级背景增强区分度。
2. 通过 `.border({ width: 0.5, radius: 12, color: $r('sys.color.ohos_id_color_focused_outline_transparent') })` 提供主题自适应的细高亮边界，并使用系统 `ShadowStyle.OUTER_DEFAULT_XS` 提供轻柔悬浮阴影。
3. 使用 `.borderRadius(12)` 控制内容边界，但不在卡片上设置 `.clip(true)`，避免裁切阴影；封面自身继续保留独立圆角。
4. 将原有点击回调直接绑定到卡片 Row，保持进入媒体详情页的行为。

## 搜索结果布局

搜索页书籍和播客分支保持现有外层 `ListItem` 左右 20vp 页面边距；卡片 Row 高度统一为 80vp，圆角为 12vp，并在卡片内部设置左右 8vp 内边距，与 64vp 封面的上下留白一致。播客添加页结果项同样使用 80vp 高、12vp 圆角、8vp 内边距和 64vp 封面，卡片视觉边缘继续保持 20vp 页面边距；文字列使用 `layoutWeight(1)` 约束在卡片剩余宽度内并保留单行省略。外层 Stack 使用 16vp、Scroll 使用 4vp 水平内边距，为阴影预留空间，避免滚动视口裁切左右阴影。边框使用主题自适应透明细高亮，背景使用系统主题自适应的 `ohos_id_color_card_bg`，阴影使用系统默认微小阴影预设；标题、作者和剧集数量沿用原有文字颜色。搜索页非首项顶部和非末项底部边距统一为 8vp；添加页结果项之间也使用 8vp 间距，末项底部安全区计算原样保留。

项目详情页章节和音轨列表保留表头 36vp、数据行原有 9.5vp 上下内边距、列表高度和 20vp 列表底部间距。每组列表外层使用一个 30vp 圆角大卡片，圆角为上方 60vp 操作按钮高度的一半，应用 `ohos_id_color_card_bg`、0.5vp 主题自适应边框和 `ShadowStyle.OUTER_DEFAULT_XS`；外层保留 `clip(false)` 以显示阴影，内层使用同样 30vp 圆角的 Stack 裁切容器包裹 List，并由 List 自身配合 `clip(true)`，确保滚动项始终限制在大卡片范围内。表头和数据行不再单独绘制圆角、边框或阴影，全部使用透明背景露出外层卡片的 `ohos_id_color_card_bg`。

## 风险与回滚

- 风险：普通卡片不再提供原生 HDS 沉浸材质或其按压反馈；这是本次明确接受的取舍。背景模糊和阴影效果会受设备性能策略影响。
- 回滚：恢复两处 `ImmersiveActionButton` builder 和原有 `barHeight`/`barRadius` 参数即可；不涉及数据或持久化。
