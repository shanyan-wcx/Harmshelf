# 技术设计

## 变更边界

产品代码只涉及 `entry/src/main/ets/pages/Play.ets`。当前页面已有 `playColorPalette`，由封面主色亮度选择主色、次级色、进度条颜色；本任务直接复用该状态，不改变 `coverColor` 的提取和切换逻辑。

## 面板覆盖范围

`playBuilder()` 中的五个 `bindSheet`：

1. 书签
2. 倍速
3. 睡眠定时
4. 章节
5. 编辑书签

## 标题实现

本地 SDK 的 `SheetTitleOptions` 只有 `title` 和 `subtitle`，没有字体颜色字段；`SheetOptions.title` 同时支持 `CustomBuilder`。在 `Play.ets` 增加一个最小的标题 builder，标题文本使用 `playColorPalette.primary`，并沿用系统标题字号/布局所需的资源和宽度约束。五个面板统一传入该 builder，避免重复实现和固定默认色。

`CustomBuilder` 只替换标题内容，不会取消系统标题栏、修改标题栏与内容区的布局，也没有关闭内容裁切的选项。因此各面板内容 builder 现有的 `top: 8` 安全间距继续保留，不能用标题 builder 代替。

## 内容颜色映射

- 主标题、选项、章节/书签标题、输入框已输入内容：`playColorPalette.primary`。
- 时间、章节时间、输入框占位文本等辅助信息：`playColorPalette.secondary`。
- 选中项继续使用现有沉浸光感按钮，仅给其内部文字补充明确的主色；未选中项保持普通胶囊按钮，仅补充相同文字颜色。
- HdsListItem 的主/次文本通过现有 `TextModifier` 设置颜色。

不改变按钮的 native material、回调、滚动容器和面板高度；不把颜色逻辑扩展到全屏播放页以外。

## 状态与刷新

颜色直接从组件的 `@Local coverColor` 计算属性读取。面板 builder 和标题 builder 不缓存颜色，避免封面主色更新后仍显示旧颜色；实现后重点验证播放页初次打开、封面主色更新后再打开面板两种路径。

## 风险与回滚

- 自定义标题 builder 可能与系统默认标题的字号或内边距存在细微差异；实现时只补充必要的文本颜色和系统字号，不重做标题栏。
- 若 ArkTS 对标题 builder 的动态调用或 `TextInput.placeholderColor` 报错，回退到 SDK 支持的同等属性写法，不改变产品范围。
- 回滚只需还原 `Play.ets` 本次颜色和标题 builder改动，保留现有播放逻辑。
