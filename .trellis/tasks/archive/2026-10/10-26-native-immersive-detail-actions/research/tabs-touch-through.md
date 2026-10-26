# Research: Tabs/HdsTabs lower-half touch-through

- Query: 只读对比当前仓库所有 `Tabs`/`HdsTabs` 用法，解释共享 `ImmersiveActionButton` 自定义 HdsTabs 在按钮视觉区域下半部触摸穿透而 Home/其他 Tabs 正常的原因，并评估 builder 固定高度与 `barHeight('auto')`。
- Scope: mixed — Harmshelf ArkTS 源码、Trellis 前端规范、随 DevEco CLI/SDK 安装的 HdsTabs/ArkUI 文档与声明。
- Date: 2026-10-26
- 状态：本文仅保留问题诊断记录；固定 builder 高度、`responseRegion` 等触摸实验已回退，当前运行时代码不采用这些方案，问题暂缓。

## Findings

### 结论

最可能的根因是共享 HDS 按钮的“可见 native bar 高度”和“自定义 tab-bar builder 的实际布局/命中节点高度”没有被同一个稳定约束锁定：

1. `ImmersiveActionButton` 的 HdsTabs root 与 HdsTabs `barHeight` 都是固定的 `barHeight`（通常 50），但 `buttonTabBarBuilder` 内部 `Stack` 使用 `.height('100%')`。
2. 该 builder 作为 `TabContent.tabBar(CustomBuilder)` 运行在 HdsTabs 的内部 tab-bar 布局上下文中；`100%` 依赖父级内部约束，而不是明确等于外层按钮高度。与此同时，native floating material 仍按固定 `barHeight` 绘制。
3. helper 的 `TabContent` 内容又被明确设为 `0 × 0`。这使“用固定 root 承载一个 custom tab bar”的布局依赖内部实现，进一步放大百分比高度解析不稳定的风险。
4. 因此可以出现视觉 plate 已覆盖 50vp，但 custom builder/TabBar 的实际可命中节点只覆盖上部或位置偏移；下半部没有命中的子节点时，祖先 detail `Scroll` 接管手势，看起来就是触摸穿透。

这不是代码中某个 `responseRegion` 直接写成半高：此前 Stack 与 HdsTabs root 曾设置 `height: this.barHeight` 的响应区，但该实验已回退。更准确的描述是：响应区设置不能修复 HdsTabs 内部 custom TabBar 节点本身的布局/裁剪边界，`monopolizeEvents(true)` 也只有在 HdsTabs 节点先赢得命中后才能阻止父级手势。

### 当前仓库全部运行时 Tabs 用法

源码扫描 `entry/src/main/ets/**/*.ets` 后只有以下三处容器实现：

| 位置 | 容器/内容 | 高度与布局 | 事件/父级差异 |
|---|---|---|---|
| `entry/src/main/ets/utils/Component.ets:153-205` | 共享单项 `HdsTabs`，被所有 `ImmersiveActionButton` 实例复用 | root `.height(this.barHeight)`；`.barHeight(this.barHeight)`；custom builder Stack `.height('100%')`；`TabContent` 内容 0×0 | root 与 builder 都有固定 `responseRegion`；交互按钮默认 `monopolizeEvents(true)`；进度摘要显式传 `false` |
| `entry/src/main/ets/utils/Component.ets:295-341` | 主导航普通 `Tabs`，4 个 `BottomTabBarStyle` | root `.height('100%')`；没有显式 `.barHeight`，使用 `.barHeight('auto')`；没有显式 `barMode` | 无 custom builder、无 `responseRegion`、无 `monopolizeEvents`；直接位于 `HdsNavigation`，不在 detail `Scroll` 中 |
| `entry/src/main/ets/pages/Home.ets:104-143` | Home 顶部普通 `Tabs`，动态文字 tab | root `.height(36)`；`.barHeight('auto')`；`BarMode.Scrollable` + `ALWAYS_AVERAGE_SPLIT`；custom label Stack `.height(36)` | `Tabs` 外层 Stack 和 `homeTitleBottomBuilder` 都 `.clip(false)`；builder 高度是固定值而非 `100%`；外层 Column 使用 `HitTestMode.Transparent` |

共享 HdsTabs 的调用点均保持 root/父 Row 的固定尺寸：detail 页的主要操作为 50vp，章节/音轨折叠操作为 64vp，播客 episode item 为 36/44vp；例如 `LibraryItemDetail.ets:1201-1270`、`:1273-1328`、`:1361-1395`、`:1785-1811`、`:1892-1915`、`:1985-2078`，`EpisodeDetail.ets:588-681`、`:683-740`，以及 `Component.ets:2329-2453`。这些调用点的 action Row 基本都显式设置了相同高度和 `.clip(false)`。

### 逐项对比

#### builder 高度

- 共享 helper：`Component.ets:129-149` 的 Stack 为 `.width(this.barWidth).height('100%')`，再设置固定 `responseRegion.height = this.barHeight`。
- Home：`Home.ets:74-100` 的 label Stack 明确 `.height(36)`，而容器 Tabs 用 `.barHeight('auto')`。
- 主导航：使用内建 `BottomTabBarStyle`，不存在 custom builder 高度问题。
- 本地 HdsTabs custom-builder 示例也用固定内容高度：`ui-design-hdstabs.md:1551-1577` 中 builder 内图片为 `48 × 48`，不是 `height('100%')`。

这使共享 helper 的 `100%` 成为当前唯一且最直接的结构差异。将 builder Stack 的高度改为 `.height(this.barHeight)` 是最小、低风险的修复建议：它同时对齐 native bar、高度型 `responseRegion` 与 custom builder 的实际布局盒；不改变宽度、`layoutWeight`、回调、菜单或视觉内容。对当前 36/44/50/64vp 的所有调用均有明确目标高度。

#### root height 与 `barHeight`

- 共享 helper：`Component.ets:163-167` 明确 root 高度和 bar 高度相等。
- Home：`Home.ets:107-116` root 是 36vp，但 bar 高度由内容自适应。
- 主导航：`Component.ets:316-324` root 撑满父级，bar 高度自适应。

所以“root 比 bar 少半高”不是源码中的常规配置错误；共享 helper 的问题更像是 custom builder 内部百分比高度在固定 bar host 下没有稳定解析。detail action Row 也大多与 root 同高：例如 `LibraryItemDetail.ets:1268-1270`、`EpisodeDetail.ets:679-681`。Episode 的进度摘要外层有上下各 5vp padding（`EpisodeDetail.ets:615-620`），但它显式传 `monopolizeActionEvents: false`（`:589-593`），允许父 Scroll 拖动，这是设计行为，不应拿它作为交互按钮命中区的对照。

#### `barOverlap`

三类 Tabs 都使用 `barOverlap(true)`（共享 helper `Component.ets:168`，Home `Home.ets:110`，主导航 `Component.ets:319`）。HdsTabs 文档说明它让 TabBar 叠加在 TabContent 上并启用默认背景模糊（`ui-design-hdstabs.md:388-413`），它解释视觉叠加/模糊，不解释只在下半部丢失触摸。共享 helper 已显式关闭普通 bar blur、divider，并将 floating gradient mask 设透明（`Component.ets:169-190`）；这些是视觉面设置，不是命中区修复。

不要为了该问题先改成 `barOverlap(false)`：这会改变 native immersive 的叠加语义，并使 floating style 不再满足官方要求的组合条件。

#### `barPosition`

所有运行时 Tabs 均为底部 `BarPosition.End`（共享 `Component.ets:172`，Home `Home.ets:104`，主导航 `Component.ets:295`）。它是 floating style 的正常配置，没有形成对照差异，也不是下半部穿透的首要嫌疑。

#### `barMode`

- 共享 HdsTabs 是单 tab、`.barMode(BarMode.Fixed)`（`Component.ets:174-175`）。这只需要给一个 tab 分配确定宽度。
- Home 是 `BarMode.Scrollable`，不溢出时使用 `ALWAYS_AVERAGE_SPLIT`（`Home.ets:112-115`）。
- 主导航未显式设置 barMode，使用普通 Tabs 默认行为。

HdsTabs 文档把 barMode 定义为 TabBar 的布局/滚动模式，横向 Scrollable 超出 barWidth 时才滚动（`ui-design-hdstabs.md:483-515`）。它主要影响横向宽度和滚动，不会把一个固定高度的 tab-bar 命中区变成半高。保持单项按钮为 Fixed 是正确的最小配置。

#### `responseRegion`

共享 helper 是唯一主动设置响应区的 Tabs：builder Stack 与 root 都用 `x/y = 0`、`height = this.barHeight`（`Component.ets:138-143`、`:193-198`）。ArkUI 文档说明未设置时默认整个组件，百分比相对于组件自身宽高（`ts-universal-attributes-touch-target.md:13-44`、`:180-184`）。因此当前数值响应区本身没有半高常量。

但响应区不是布局约束：如果 HdsTabs 内部先按 custom builder 的实际布局盒做 TabBar 命中/事件分发，root 的扩大响应区未必能让 custom TabBar 子节点覆盖其外部区域。文档还说明父组件 `clip(true)` 会限制子组件响应区（`ts-universal-attributes-touch-target.md:186-187`）。这支持“先修 builder 实际高度，再看响应区”的顺序，而不是继续扩大 region。

#### `monopolizeEvents`

共享 helper 在 `Component.ets:205` 使用 `this.monopolizeActionEvents`；交互操作默认 true，detail 进度摘要在 `LibraryItemDetail.ets:1363-1367` 与 `EpisodeDetail.ets:589-593` 传 false。ArkUI 文档说明 true 是组件独占事件，尤其会阻止父手势，但前提是该组件已经成为首个响应者（`ts-universal-attributes-monopolize-events.md:15-38`）。

因此：

- 交互按钮下半部穿透不是因为默认值为 false；默认值是 true。
- 将 true 再改成 true 没有修复作用；将 false 改成 true 只会改变进度摘要的预期滚动行为。
- 如果 custom builder/TabBar 的下半部没有命中，事件会先落到 detail `Scroll`，此时 monopolize 无法“凭空”补出命中节点。

#### 父级 Row / Scroll / clip

- detail 页面结构是 `HdsNavDestination → Stack → Scroll → GridRow/Column → action Row`：`LibraryItemDetail.ets:1173-1176`，`EpisodeDetail.ets:543-547`。
- action 链中的 HdsTabs root、builder Stack、TabContent 和相关 Row 已大量使用 `.clip(false)`，例如 helper `Component.ets:137`、`:158-160`、`:192`，以及 detail `LibraryItemDetail.ets:1258-1270`、`:1298`、`:1328`、`EpisodeDetail.ets:669-681`、`:708`、`:737-740`。
- 外层 detail `Scroll` 没有显式 `.clip(false)`；ArkUI/SDK 文档说明 `TabContent` 默认 clip 为 true（`tab_content.d.ts:870-876`），并且 `Scroll` 组件的 clip 默认也为 true。现有 helper 已对 TabContent 显式关闭 clip，且受影响的按钮是在 Scroll 内容范围内，因此外层 Scroll clip 更可能影响超出按钮边界的 native 阴影/材质，而不是造成按钮内部恰好下半部穿透。
- Home 的 Tabs 及外层 `Stack`/title bottom builder 都是 36vp 并 `.clip(false)`（`Home.ets:95-99`、`:107-143`；`Component.ets:417-429`），没有 detail Scroll 这一层事件竞争。

父级 Scroll 是穿透现象的接收者，不是首要几何根因：它能说明“为什么看起来穿透”，但不能说明“为什么只少一半”。若固定 builder 高度后仍复现，才应在目标设备上检查 outer Scroll 的实际触摸热区和 native HdsTabs 的 area-change，而不是先改所有父级 clip。

### 两个候选改动的影响评估

#### A. `buttonTabBarBuilder`：`height('100%')` → `height(this.barHeight)`

建议作为第一步、最小修复。它把 custom builder 从依赖 HdsTabs 内部百分比约束改为与 root/barHeight 同一固定尺寸；对当前固定尺寸调用点没有设计上的尺寸变化。它也使 Stack 的圆角、`responseRegion.height` 与 native bar 的可见区域使用同一几何基准。

风险较小：若当前 SDK 实际已经将 `100%` 正确解析为 barHeight，运行效果应等价；若问题正由百分比解析/内部 TabBar host 造成，则应消除下半部命中缺口。无需同时改 `barMode`、`barPosition`、`monopolizeEvents` 或父级 Row。

#### B. HdsTabs：固定 `.barHeight(this.barHeight)` → `.barHeight('auto')`

不建议作为第一步。HdsTabs 文档明确 `auto` 表示根据子组件高度自适应，且只对横向 Tabs 有效；固定值小于 0 或超过 Tabs 高度时还会回退默认值（`ui-design-hdstabs.md:318-351`）。当前 builder 恰好是 `height('100%')`，先把 barHeight 改 auto 会形成“TabBar 高度依赖 builder，builder 高度依赖 TabBar”的循环/欠约束关系，可能出现：

- bar 高度退回 HdsTabs floating 默认高度（文档给出的 floating 默认值为 56vp），与外层 50vp root 不一致；
- 以 icon/text 的 intrinsic height 收缩，native material 仍与按钮 Row 的固定高度不一致；
- 触摸问题从“下半部缺口”变成整体 bar 高度/位置漂移。

如果先把 builder 固定为 `this.barHeight`，再把 HdsTabs 设为 auto，理论上可能测得同一个固定高度，但这只是重复指定，增加了对 HdsTabs 测量顺序和不同 builder 内容的依赖；当前没有收益。保持 HdsTabs barHeight 固定更符合该 helper 的“按钮尺寸就是 bar 尺寸”契约。

### 最小修复建议（已回退）

1. 固定 builder 高度和 `responseRegion` 实验已回退；root `.height(this.barHeight)`、`.barHeight(this.barHeight)`、`barOverlap(true)`、`barPosition(End)`、`BarMode.Fixed`、native 材质和交互按钮的 `monopolizeEvents(true)` 保持原状。
2. 问题暂缓。后续若恢复调查，应在真实设备/模拟器上验证 play/download/more 的上半部和下半部点击，以及 press-drag 是否仍由 Scroll 接管；单独排除 `monopolizeActionEvents:false` 的进度摘要，因为它按规范应该让父 Scroll 接收拖动。
3. 若固定 builder 后仍只在部分区域穿透，再做只读/诊断性 area-change 记录，确认 HdsTabs root、TabBar builder 与外层 Row 的实际高度；届时再考虑 outer Scroll 的 `.clip(false)`，不要先把 `barHeight` 改 auto。

## Files found

- `entry/src/main/ets/utils/Component.ets` — 唯一共享 `HdsTabs` helper、主导航普通 Tabs、所有可复用 episode action 调用点。
- `entry/src/main/ets/pages/Home.ets` — Home 顶部普通 Tabs；固定 36vp custom label builder 与 `barHeight('auto')`。
- `entry/src/main/ets/pages/LibraryItemDetail.ets` — detail Scroll 内的 50/64/36vp immersive actions 及 action Row/clip 链。
- `entry/src/main/ets/pages/EpisodeDetail.ets` — detail Scroll 内的进度摘要、50vp play/download/more actions。
- `.trellis/spec/frontend/component-guidelines.md` — shared HdsTabs、clip、事件独占与进度摘要事件策略。
- `.trellis/spec/frontend/directory-structure.md` — shared helper 与页面目录归属。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\UI_Design_Kit_UI设计套件\ArkTS组件\HdsTabs\ui-design-hdstabs.md` — HdsTabs barHeight/barMode/barOverlap/floating/custom-builder API，DevEco CLI 本地 API metadata V189。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\导航与切换\TabContent\ts-container-tabcontent.md` — custom tabBar 内容裁剪契约，DevEco CLI 本地文档 metadata V214。
- `C:\command-line-tools\sdk\default\openharmony\ets\component\tab_content.d.ts` — TabContent 默认 `clip(true)` 的 SDK 声明。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\通用属性\交互属性\触摸交互控制\触摸热区设置\ts-universal-attributes-touch-target.md` — responseRegion 默认范围、百分比基准和父 clip 影响。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\通用属性\交互属性\触摸交互控制\事件独占控制\ts-universal-attributes-monopolize-events.md` — monopolizeEvents 仅在组件先成为响应者后阻断父手势的说明。

## Code patterns

- `entry/src/main/ets/utils/Component.ets:129-149` — custom builder 使用 `height('100%')`，同时设置固定高度 responseRegion 和 click/menu。
- `entry/src/main/ets/utils/Component.ets:153-205` — shared HdsTabs 使用 0×0 TabContent、固定 root/barHeight、End/Fixed、两层 responseRegion 与可配置 monopolizeEvents。
- `entry/src/main/ets/utils/Component.ets:293-341` — bottom navigation 普通 Tabs 使用 100% root、auto barHeight、内建 BottomTabBarStyle、无 custom builder/responseRegion。
- `entry/src/main/ets/pages/Home.ets:74-143` — Home 普通 Tabs 的 custom label builder 固定 36vp，Tabs barHeight auto，父级 clip false。
- `entry/src/main/ets/pages/LibraryItemDetail.ets:1173-1176` — detail action 所在 `HdsNavDestination → Stack → Scroll` 链。
- `entry/src/main/ets/pages/LibraryItemDetail.ets:1201-1270` — 50vp flexible play action 与固定下载/更多 Row，action chain 显式 clip false。
- `entry/src/main/ets/pages/EpisodeDetail.ets:543-547` — episode detail 的 Scroll 链。
- `entry/src/main/ets/pages/EpisodeDetail.ets:588-681` — 进度摘要（monopolize false）与 50vp interactive play action 的对比。
- `entry/src/main/ets/pages/EpisodeDetail.ets:683-740` — 50vp fixed download/more action 与父 Row/clip/bindSheet。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\UI_Design_Kit_UI设计套件\ArkTS组件\HdsTabs\ui-design-hdstabs.md:318-351` — `barHeight('auto')` 只对横向 Tabs 生效，并根据子组件高度自适应；floating 默认高度为 56vp。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\UI_Design_Kit_UI设计套件\ArkTS组件\HdsTabs\ui-design-hdstabs.md:483-515` — barMode 控制 TabBar 布局/滚动，不是垂直触摸热区开关。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\UI_Design_Kit_UI设计套件\ArkTS组件\HdsTabs\ui-design-hdstabs.md:1551-1577` — 官方 custom tab-bar 示例使用固定 48vp 子组件高度。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\通用属性\交互属性\触摸交互控制\触摸热区设置\ts-universal-attributes-touch-target.md:32-44,180-187` — 默认响应区为整个组件，百分比相对组件自身；父 clip true 会限制子响应区。
- `C:\Users\21633\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\通用属性\交互属性\触摸交互控制\事件独占控制\ts-universal-attributes-monopolize-events.md:15-38` — monopolizeEvents 的事件独占和父手势关系。

## External references

- Huawei HdsTabs API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs>
- Huawei HdsTabs floating-style guide: <https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating>
- Huawei TabContent API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-tabcontent>
- Huawei responseRegion API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-touch-target>
- Huawei monopolizeEvents API: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-monopolize-events>

## Related specs

- `.trellis/spec/frontend/component-guidelines.md:30-56` — native HdsTabs material、固定 action 尺寸、clip false、交互/非交互 monopolize 策略。
- `.trellis/spec/frontend/component-guidelines.md:76-77` — TabContent 默认裁剪可能造成边界，action layer 与 detail Row 应保持 clip false。
- `.trellis/tasks/10-26-native-immersive-detail-actions/prd.md` — 任务要求 native HDS material、50vp operation controls 和原有回调/布局行为。
- `.trellis/tasks/10-26-native-immersive-detail-actions/design.md` — shared helper 单一 HdsTabs、无第二背景层、原有详情页 callback 保持不变。

## Caveats / Not Found

- 没有设备/模拟器触摸录制或 `onAreaChange` 高度日志，因此“builder 的 100% 在 HdsTabs 内部被解析为不足/偏移高度”是基于源码差异、官方 custom-builder 示例和症状的最可能推断，不是已由运行时数值直接证明的事实。
- 仓库源码没有第二个 `HdsTabs` 实现；所有 shared action 实例都共享同一 helper，所以若所有交互按钮都呈现同样的下半部穿透，应优先改/验证 helper，而不是逐页修 Row。
- `barHeight('auto')` 在固定 builder 高度之后可能偶然表现正常，但会把尺寸契约交给 HdsTabs 测量顺序，不能作为当前问题的最小稳定修复。
- 外层 detail `Scroll` 未显式 `.clip(false)`，可能影响超出边界的 native 阴影/材质；当前源码不足以证明它会裁掉按钮内部下半部命中区，且 action Rows 已在内容范围内显式 `.clip(false)`。
- 本研究未修改任何生产代码、规范或 task manifest；只写入本 research 文件。
