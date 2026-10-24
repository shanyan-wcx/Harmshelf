# 实施计划：全局透明沉浸标题栏与首页 Tabs

## 1. 基线与规范

- [x] 阅读并遵守 `.trellis/spec/frontend/state-management.md`、`.trellis/spec/frontend/type-safety.md`。
- [x] 确认当前工作区已有改动不被覆盖，记录实现前的构建基线。

## 2. 共享标题栏样式

- [x] 在 `entry/src/main/ets/utils/Component.ets` 增加共享标题栏样式方法，直接使用 API 23 沉浸光感材质。
- [x] 将 `MyNavigation` 和普通二级页面标题栏改为复用透明样式；媒体详情页改用 `ScrollEffectType.GRADIENT_BLUR`。
- [x] 保留现有标题、菜单、`enableComponentSafeArea` 和滚动绑定；统一保留 `avoidLayoutSafeArea: true`，由页面根节点负责内容 edge-to-edge。
- [x] 确认不添加 `dynamicHideTitleBar`；仅媒体详情页使用渐变模糊，其余主导航和二级页面保持透明沉浸。

## 3. 首页 Tabs 迁移

- [x] 从 `MyNavigation` 删除首页 Tabs 专用 builder、相关 HDS Tabs imports/字段和 `bottomBuilder`。
- [x] 在 `Home.ets` 根 `Stack` 增加唯一的首页内容 tabs，复用动态标签、当前颜色和状态同步逻辑；标准 ArkUI `Tabs` 只作为沉浸材质底板。
- [x] 首页可见层恢复为 36vp 自定义 tab builder：未溢出时使用 `layoutWeight(1)` 填满，溢出时使用内容安全宽度交给原生 `BarMode.Scrollable`，播放列表文字保持完整。
- [x] 使用标准 `Tabs.barFloatingStyle` 的原生悬浮栏圆角和 `uiMaterial.ImmersiveMaterial` 作为底板；关闭阴影，将 `maskColor`、`maskHeight`、`barBottomMargin` 设为 0/透明，不让默认 tab bar 样式渲染文字或下划线。
- [x] 使用每个 tab item 自带的 20x3vp indicator，直接居中在文字容器内，避免标签数量变化时整栏坐标推算偏移；使用 `Curve.Friction` 动画，文字状态使用约 180ms Friction 动画。
- [x] 首页 tab 外层 Row/Stack 显式关闭裁切，避免上下移动时裁切材质和指示条。
- [x] 将首页内容 tabs 保持在标题栏下方的顶部位置，并保留动态标签同步；未修改底部主导航。
- [x] 作者网格保留 `rowsGap(20)`，仅将其顶部避让在统一值基础上减 5vp；主导航直接承载的 Local/Log/Setting/Stats 在原有顶部基准上追加 `statusBarHeight`，SubHome（包含“继续收听”）的顶部避让同样减 5vp。
- [x] 保留 `.padding({left: 16, right: 16})`，确保首页以外不渲染该 Tabs。
- [x] 删除首页旧的全局固定顶部外边距；不在 Home 内容分发外层移动滚动视口，改为在各首页 Scroll/Grid 的原有 `padding.top` 上增加 `statusBarHeight + 56vp`，避免首屏被标题栏和内容 Tabs 覆盖并保留顶部 edge-to-edge 滚动。
- [x] MyNavigation 与 7 个 HdsNavDestination 统一加入顶部 edge-to-edge 安全区设置。
- [x] 保留现有具体首页滚动容器间距，未做未经验证的批量调整。
- [x] 移除媒体库选择器父 Row 的裁切，保留选择器底部阴影。
- [x] 将 `compatibleSdkVersion` 调整为 `6.1.0(23)`，保留 `targetSdkVersion=26.0.0` 和现有 module metadata。

## 4. 验证与收尾

- [x] 用最终 `compatibleSdkVersion=6.1.0(23)` 配置执行 `devecocli build`，构建成功；仅有项目既有警告及沉浸材质底板 API 26 高于兼容基线的提示。
- [x] 用 `git diff --check` 和 `rg` 检查重复 Tabs、标题栏隐藏 API、未使用 imports。
- [ ] 若有可用设备/模拟器，运行首页和全部二级页面，检查透明材质、滚动时标题栏仍在、首页内容可到状态栏、标签同步。（当前无可用设备）
- [x] 更新受影响的状态管理 spec 与任务文档，改为 36vp 自定义等宽 Row/单一 indicator 描述，移除低版本 fallback、全页面透明和 `titleBar.bottomBuilder` 的过时描述。
- [ ] 归档检查结果并提交最小变更。（等待提交确认）

## 约束

- 不新增依赖。
- 不重写二级页面数据或播放逻辑。
- 不在未验证的情况下批量改动二级页面顶部 padding。
