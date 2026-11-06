# Research: Bottom-tab and minibar playback bar

- Query: 参考官方 BottomTab/Minibar 文档，研究当前模拟播放条如何支持带/不带 bottom tab 的页面、折叠/展开布局、一次 marquee 后暂停再循环、无旋转但保留进度环，以及现有路由、安全区、sheet 和播放回调的约束。
- Scope: mixed（仓库代码、Trellis 规范、DevEco SDK 声明、官方 HarmonyOS 文档）
- Date: 2026-11-06

## Findings

### Official contract and SDK surface

- 官方 Bottom Tab UX 文档：<https://developer.huawei.com/consumer/cn/doc/doccenter-ux-design/bottomtab-0000001956787789/>。HarmonyOS 6.1 的 floating bottom tab 是胶囊容器；官方示例的浮动容器高度为 56vp，底部 tab 与 minibar 可以左右排列，minibar 支持折叠/展开。整体底部区域会考虑系统导航栏安全区，但 tab 自身的 touch region 与系统导航栏区域独立。
- 官方 HdsTabs floating style：<https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ui-design-hds-tabs-bar-floating/>。关键约束是 `barPosition: BarPosition.End`、`vertical(false)`、`barOverlap(true)`；`barFloatingStyle` 可配置 `barWidth`、`barBottomMargin`、`systemMaterialEffect` 以及 `miniBar`。官方说明 minibar 是与 tab bar 同高、横向排列、可展开/折叠的自定义区域。
- 官方 HdsTabs API：<https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs/>。本机 API 26 SDK `@hms.hds.hdsBaseComponent.d.ets` 对应声明如下：
  - `HdsBarStyle.COLLAPSE/EXPAND`：约 5124-5140 行。
  - `HdsTabsMiniBar`：约 5229-5320 行；必填 `miniBarBuilder`，可选 `miniBarWidth`、`miniBarStyle`、`enableMiniBarBackground`、`enableMiniBarClip`、`onBarStyleChange`、minibar/tabbar 动画回调和 `barLayoutMode`。
  - `HdsBarLayoutMode.HORIZONTAL/VERTICAL`：约 5329-5345 行；本项目 target API 26，满足 API 24+ 的 HORIZONTAL 能力。官方默认布局已经是 minibar/tabbar 左右排列，但建议显式指定 HORIZONTAL，减少版本默认值差异。
  - `HdsTabsFloatingStyle`：约 5380-5473 行；有 `barWidth`、`barSideMargin`、`barBottomMargin`、`gradientMask`、`miniBar`、`systemMaterialEffect` 等，没有独立 `barRadius` 字段。圆角应由官方 floating/material 容器提供，不要寻找不存在的半径属性。
  - `HdsTabsController.applyMiniBarStyle(style: HdsBarStyle)`：约 5829-5836 行；如需由播放状态或“点击封面打开全屏”驱动折叠状态，应通过 controller/官方回调协调，而不是再叠一层自定义动画。
- 官方 Marquee API：<https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-marquee>。本机 `openharmony/ets/component/marquee.d.ts`：`MarqueeOptions.loop` 为 `1` 时只滚动一轮，`<=0` 才是持续循环；`delay` 是轮次之间的等待时间，API 23+；`onStart`/`onBounce`/`onFinish` 可观察生命周期。`Text` 的 `marqueeOptions` 与 `onMarqueeStateChange` 在本机 `text.d.ts` 约 1076-1102、1671-1794 行，API 18+，target API 26 可用。
- Marquee 只在内容宽度超过组件宽度时滚动；本机声明建议限制同时滚动的 marquee 数量，且 `TextOverflow.MARQUEE`/`marqueeOptions` 对较短文本不会产生可见移动。标题和副标题应放进有明确剩余宽度的 `Row`/`Column`，并只在展开态创建。
- 官方 immersive-light/ImmersiveMaterial 文档（本机 DevEco docs 路径 `开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/arkts-immersive-light-sense`）说明 system `ImmersiveMaterial` 会影响背景、边框、阴影和材质滤镜；容器不要再叠加竞争性的背景、blur、shadow、border。仓库规范进一步把 system immersive-light 限定为标题栏/tab bar；内容区操作应优先使用共享 HDS `ImmersiveActionButton`。本需求明确要求“不带 bottom tab 的页面也使用 immersive-light capsule”，这需要在实现时确认/记录为有意的组件范围例外，不能悄悄用任意 `systemMaterial` 复制一套按钮。

### Current player/minibar implementation

- `entry/src/main/ets/pages/Play.ets:22-51`：`Play` 是 `@ComponentV2`，通过 `@Consumer` 读取 `isPlaying`、`showPlay`、`isStartPlaying`、`playingItem`、`localPlayItem`、`playingTitle`、`playingIndex`、`playedTime`、`playedPercent`、`currentTrackDuration`、`avPlayer` 和播放设置等全局状态。
- `Play.ets:1226-1735` 的 `playBuilder()` 是全屏播放器。主封面在约 1228-1254 行使用方形 `Image`、`ImageFit.Contain`、`aspectRatio(1)` 和 `geometryTransition("cover")`；标题/副标题在约 1285-1308 行使用普通 `Text` + 单行 Ellipsis；进度 slider 与时间显示在约 1310-1364 行；全屏 rewind/play/fast-forward 和上下曲控制在约 1370-1500 行。
- `Play.ets:1505-1645` 的全屏 controls 绑定 bookmark/speed/sleep/chapter/edit bookmark sheets，并读取 `windowAvoidArea.navigationIndicator.visible`/`bottomRect.height` 做底部安全区处理。这些 sheet 和全屏底部 padding 不应被复制到 minibar。
- `Play.ets:1646-1710` 的全屏底部菜单仍包含“关闭播放器”动作：它会停止 `avPlayer`、设置 `shouldClosePlayer` 并清掉 `showPlay`。这不是 minibar 的按钮；新 minibar 只保留 rewind/play/fast-forward，关闭动作继续留在全屏菜单即可。
- `Play.ets:1738-1779` 的 `primaryButtonBuilder()` 是当前折叠播放条封面。它使用约 65x65 的圆形 cover、外层 `Progress({ value: this.playedPercent, total: 100, type: ProgressType.Ring })` 约 71x71、透明/blur/shadow host，并把 `showPlay` 绑定到 `bindContentCover`。这里明确存在 `.rotate({ angle: this.rotateAngle })`、`.animation(...)` 和 `.onAppear(() => this.startRotate())`；这是应删除的旋转来源。Progress ring 应继续保留，并检查 host/官方 minibar clip 是否会裁剪 71x71 的环。
- `Play.ets:1796-1860` 已有可复用的播放动作：`goBackwardButton` 按 `playSetting.skipIntervals` 调 `avPlayer.seek`；`playPauseButton` 处理 pause/play、准备状态、渐变和 `isPlaying`；`goForwardButton` 同样按 skip interval seek。`stopButton` 是当前模拟条的关闭/停止按钮，新 minibar 不应再放入 `startButtons`。
- `Play.ets:1862-1885` 的 `build()` 是当前模拟条：`HdsActionBar` 使用 `startButtons: [goBackwardButton, stopButton]`、`endButtons: [playPauseButton, goForwardButton]`、`primaryButtonBuilder`、`primaryButtonBuilderWidth: 70vp`、`isExpand: true`、`BlurStrategy.ENABLE`，外层却 `.height(0)`、`.margin({ bottom: 108 })`，并通过 Transparent 外层 + `BLOCK_HIERARCHY` 内层接收触摸。这种 magic bottom margin 不能继续作为两类页面的布局基线。
- `Play.ets:52-55,106-135,423-438` 的 `rotateAngle`/`rotateTimer`、focus monitor、lifecycle timer 和 `startRotate()`/`stopRotate()` 都只服务封面旋转。删除旋转时需要一并移除这些 timer/focus/lifecycle 依赖，而不是只删 `.rotate()`，否则仍会有无意义的定时器和状态更新。

### Bottom-tab placement and route/layout detection

- `entry/src/main/ets/utils/Component.ets:201-340` 的 `MyNavigation` 是底部导航宿主。`isBottomTabDevice()`（约 254-256 行）只按 `phone || tablet` 判断设备能力；`bottomTabBarBuilder()`（约 293-340 行）创建 `Tabs`，配置 `barOverlap(true)`、`vertical(false)`、`barHeight('auto')`，并在 `barFloatingStyle` 中使用 `barSideMargin: 16`、`barBottomMargin: MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN` 和 `ImmersiveMaterial`。这里是带 bottom tab 页面接入官方 `miniBar` 的唯一现成宿主；当前没有 `miniBar` 字段。
- `MyNavigation.bottomTabBarBuilder()` 的 `Tabs` 已经是官方 HDS floating 风格的正确入口，最小方向是在现有 `barFloatingStyle` 增加 `miniBar: { miniBarBuilder: ... }`，并设置 `barLayoutMode: HdsBarLayoutMode.HORIZONTAL`、合适的 `miniBarWidth`/初始 `miniBarStyle`。不要在 `Play.build()` 再绘制第二个底部胶囊，否则会和 tab bar 重叠、重复占用触摸区。
- `Component.ets:431-573` 的 `MyNavigation.build()` 在 phone/tablet 走 `bottomTabBarBuilder()`，其他设备走 `HdsSideBar`/页面内容。`Component.ets:65-76` 的 `getMainNavigationItems()` 是 tab item 的单一来源。
- `entry/src/main/ets/pages/Index.ets:109-210` 提供所有播放状态，并在约 1166-1222 行的 `ContentPanelBuilder()` 用 `Stack { MyNavigation(); if (isStartPlaying) Play(); ... }` 把 `Play` 作为覆盖层放在导航上方。因此当前 `Play` 与具体路由没有布局分支；改造时必须把“当前实际可见 bottom tab”作为反应式布局状态传下去，不能只复用设备类型判断。
- `Index.ets:283-297` 的 `registerInterception()` 在 root 与 pushed `HdsNavDestination` 间切换 `isIndex`。`Index.ets:301-312` 的 `isBottomTabDevice()` 与 `MyNavigation` 版本相同，只表示设备类别。建议把 `isIndex`/当前 nav destination 与设备类别结合，形成 `hasBottomTab`，而不是把 `isBottomTabDevice()` 直接当成当前页面是否有 tab。
- 现有页面已用 `getBottomContentInset(..., false)` 表示“当前页面没有 root bottom tab”，这是很强的现成布局信号：`Search.ets:133,188`、`Download.ets:75`、`FilterItems.ets:137`、`EpisodeDetail.ets:847`、`CollectionDetail.ets:551`、`Log.ets` 等 pushed 页面如此使用；root `Home`/`Stat`/`Local`/`Setting` 页面通常保留默认 `hasBottomTab=true`。实现可沿用这一语义，避免另造与页面内容避让不一致的判断。
- `entry/src/main/resources/base/profile/router_map.json` 的 pushed routes 包括 `search`、`filterItems`、`libraryItemDetail`、`episodeDetail`、`playlistDetail`、`collectionDetail`、`downloadTask`、`log`；根页面只有 `main_pages.json -> pages/Index`。因此“无 bottom tab 页面”主要是这些 nav destination，但具体设备/导航层级仍应在真机上确认。
- `entry/src/main/ets/utils/Layout.ets:1-19`：`MOBILE_BOTTOM_TAB_BAR_HEIGHT=75`、`MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN=16`，`getBottomContentInset()` 对 phone/tablet 的 bottom-tab 内容避让值是 `75 + 16 = 91`。这 91vp 是内容避让基线，不等于官方 floating capsule 的 56vp 可视高度；不要把 75/16 直接当新 minibar 的视觉高度。

### Playback callbacks and callers

- `Index.ets:566-649` 的 `setAVSessionCallback()` 已接通系统 session 的 `rewind`、`fastForward`、`playPrevious`、`playNext`；`Index.ets:651-760` 的 `setAVPlayerCallback()` 更新 `playedTime`、`playedPercent`、duration，并处理自动下一曲/暂停。minibar 应继续调用现有 `goBackwardButton`/`playPauseButton`/`goForwardButton` 或同一层的动作函数，不能复制一套不更新全局状态的 seek/play 逻辑。
- 播放状态启动入口分散在 `Index.ets:258-281`、`Local.ets:96-104`、`CollectionDetail.ets`、`EpisodeDetail.ets`、`LibraryItemDetail.ets`、`PlaylistDetail.ets` 以及 `Component.ets` 的 episode/book action 中，但它们都写入 Index 提供的播放状态。视觉改造无需修改这些启动入口；只需消费现有 providers，并保持 `isStartPlaying`/`showPlay` 的生命周期语义。
- `Play.primaryButtonBuilder()` 当前封面点击会 `showPlay=true` 打开 `bindContentCover`；官方 HdsTabs collapsed minibar 自己也可能把点击解释为 expand。封面按钮与 HdsTabs 的折叠手势存在触摸优先级冲突，需要真机确认：应避免在整个 minibar host 上再挂一个会吞掉 HdsTabs 事件的 `onClick`，并明确“点击封面是展开 minibar”还是“直接进入全屏播放器”的产品行为。

### Minimal implementation plan

1. 以 `Component.ets:bottomTabBarBuilder()` 的官方 `Tabs.barFloatingStyle.miniBar` 为带 bottom tab 页的唯一渲染入口。minibar 初始态建议 `HdsBarStyle.COLLAPSE`；显式 `HdsBarLayoutMode.HORIZONTAL`；`miniBarWidth` 使用官方上限范围（展开宽度不超过 328vp），不要固定一个跨断点的超宽值。
2. 抽出一个共享的 player-mini-bar builder/component seam，保持 `Play` 的全局状态和现有三种动作只由一处维护。当前 `Play.ets` 反向 import 了 `Component.ets` 的 `ImmersiveActionButton`，若让 `Component.ets` 直接 import `Play`，可能形成 ArkTS 模块环依赖。优先通过 `Index` 向 `MyNavigation` 传 `@BuilderParam`/动作闭包，或把纯 player mini-bar 和动作适配放到不反向依赖 `Component.ets` 的新 utility；不要用两个独立的播放状态机。具体拆分方式需以 ArkTS 编译器对 builder/cycle 的限制验证。
3. 带 tab 的 collapsed builder 只渲染圆形 cover + progress ring，cover 尺寸填满官方 minibar 可视高度且不加 margin；保留 `ProgressType.Ring` 与 `playedPercent`，删除 rotate/animation。expanded builder 使用 left-right：左侧圆形 cover 带小 margin，中间是标题/副标题，右侧只有 rewind/play/fast-forward。移除 `stopButton`，全屏菜单里的“关闭播放器”不变。
4. 对无 bottom tab 的 pushed 页面，复用同一套状态/动作和 cover/text/control builder，但由 `Play` 或新的共享 bar host 渲染一个与 bottom tab 相同的视觉高度（官方 floating capsule 参考 56vp）、immersive-light capsule。cover 在左，标题/副标题占剩余宽度，三个控制在右。位置应由 navigationIndicator safe area + `hasBottomTab=false` 的布局语义决定，替换现有 `.height(0).margin({ bottom: 108 })`；不要再叠加一条 root bottom tab。
5. 标题/副标题只在 expanded layout 创建 marquee。优先使用 `TextOverflow.MARQUEE` + `marqueeOptions` 或 `Marquee` 的有限 `loop: 1`；需求是“滚动一遍、暂停、再重复”，不能使用 `loop: -1` 的无间隔连续滚动。`delay` 只表示轮次间等待，若 `loop: 1` 结束后组件不会自动重新开始，则用状态/组件 identity 或 `onFinish` + pause timer 重新 arm；实现前需在 API 26 真机验证 completed marquee 是否能通过 `start` 重启。短文本应保持静态，不强行触发动画。
6. 删除 `rotateAngle`、`rotateTimer`、`startRotate`、`stopRotate`、focus/lifecycle rotation calls，以及 `primaryButtonBuilder()` 中的 `.rotate`/`.animation`/`.onAppear(startRotate)`；保留 `geometryTransition("cover")` 只有在它与官方 HdsTabs/全屏 cover 过渡不冲突时。检查 71x71 ring 在官方 `enableMiniBarClip` 默认 true 下是否被裁剪，必要时只对播放器 host 设置不裁剪，避免扩大整个 tab bar 的触摸/绘制范围。
7. 保持现有 full-screen `bindContentCover` 和 sheets 只归 `playBuilder()`；minibar builder 不携带 bookmark/speed/sleep/chapter sheets、全屏 close menu、bottom safe-area padding。播放器动作继续调用已有 callbacks，让 AV session、progress ring、自动下一曲和 `isPlaying` 保持同一状态源。

### Pitfalls to verify during implementation

- **Safe area 与高度**：官方 capsule 56vp 是视觉高度；`Layout.ets` 的 75vp + 16vp = 91vp 是内容避让值。`barBottomMargin`、系统 navigation indicator 高度、`getBottomContentInset()` 只能各负责一层，不能同时把它们加到同一个 bar 上。当前全屏 `Play` 对 navigation indicator 的手动 padding 只应保留在全屏 controls。
- **Bar overlap**：现有 `Tabs` 使用 `barOverlap(true)`。root 页面内容必须继续使用 `getBottomContentInset(..., true)`；pushed 页面应使用 false。把 no-tab player bar 当成 tab bar 再传 true 会导致内容底部重复空隙。
- **Clip/ring**：HdsTabs `enableMiniBarClip` 默认 true；cover/ring/shadow 若超出 capsule 边界可能被裁剪。只扩大可视 host 或关闭 mini bar clip 前，先确认不会让 ring 穿出 tab capsule 并截断相邻 tab 的触摸区。
- **Hit testing**：当前外层 `Play` 是 `HitTestMode.Transparent`，内部 HdsActionBar 是 `BLOCK_HIERARCHY`。新 bar 仍应让透明区域穿透页面、只让 cover/三个控制消费触摸。不要给全屏 overlay 加一个覆盖整屏的 `BLOCK_HIERARCHY`；也不要在 HdsTabs container 与 child controls 同时加竞争性 `onClick`。
- **Collapsed click semantics**：官方 HdsTabs 需要处理 minibar/tabbar 的折叠切换；现有 cover 又需要打开 `showPlay`。要在产品上确定 collapsed cover 的一次点击是“展开 minibar”还是“打开 full-screen”，并按官方 controller/callback 做单一动作，避免 nested Button、`bindContentCover` 和 HdsTabs 手势互相吞事件。
- **Marquee restart**：`loop: 1` 本身只保证一次；`delay` 不等同于无限循环的暂停策略。重启可能需要重建 marquee 节点/改变 key 或在 `onFinish` 后再 arm，且标题切换时要取消旧 timer。不要在两个文本上开持续 loop，避免标题和副标题失去同步或长期耗电。
- **Sheet 生命周期**：`Play.playBuilder()` 的 sheets 会在 `onWillAppear`/`onDisappear` 更新 sleep/speed/chapter 状态。若把 controls builder 抽出，保留这些 sheet 的 owner 在 full-screen 页面，不要让 miniature host 持有一个隐藏 sheet 或沿用全屏的 `chapterScroller`。
- **Material scope**：项目规范 `component-guidelines.md` 规定 content-area actions 使用共享 HDS `ImmersiveActionButton`，system immersive-light 主要给 title/tab bars；本需求的 no-tab capsule 是边界案例。应复用 HDS container/共享按钮能力，并在设计/规范层确认该 capsule 的 material 例外，避免 `systemMaterial` + 自建 blur/shadow/background 叠加。
- **Route detection**：`isBottomTabDevice()` 只表示 phone/tablet，不能证明当前 pushed route 仍显示 bottom tab。沿用 `isIndex`/nav destination 或页面已有 `hasBottomTab=false` inset 语义，并在 phone/tablet 的 Search/Detail/Download 等页面真机确认 HdsNavigation 是否仍保留 root tab。
- **Version/defaults**：官方文档把 minibar 能力标在 HarmonyOS 6.1/API 23+ 的 HDS surface；本机 API 26 SDK 有完整声明，但 `miniBarStyle` 初始值、点击事件优先级、clip 对 ring 的表现仍需运行时验证，不应仅凭类型声明假定动画行为。

## Files found

- `entry/src/main/ets/pages/Play.ets` — 全屏播放器、当前 HdsActionBar 模拟条、封面 ring/rotation、播放按钮和 sheets。
- `entry/src/main/ets/utils/Component.ets` — `MyNavigation`、phone/tablet bottom `Tabs`、现有 `barFloatingStyle`、共享 `ImmersiveActionButton`。
- `entry/src/main/ets/pages/Index.ets` — provider 播放状态、AVPlayer/AVSession callbacks、root/pushed route interception、Play overlay 挂载点。
- `entry/src/main/ets/utils/Layout.ets` — bottom tab visual/inset constants 与 `getBottomContentInset()`。
- `entry/src/main/resources/base/profile/router_map.json` — pushed route 列表。
- `entry/src/main/resources/base/profile/main_pages.json` — root `Index` page。
- `entry/src/main/ets/pages/Search.ets`、`Download.ets`、`FilterItems.ets`、`EpisodeDetail.ets`、`CollectionDetail.ets`、`Log.ets` — 使用 `hasBottomTab=false` 内容避让的无 tab 页面样例。
- `entry/src/main/ets/entryability/EntryAbility.ets` — window/full-screen/safe-area 入口配置。
- `entry/src/main/resources/base/module.json5` — `ohos.arkui.UIMaterial.state` 已启用。
- `.trellis/spec/frontend/index.md`、`component-guidelines.md`、`state-management.md`、`type-safety.md` — 状态、HDS/immersive material、底部导航和 ArkTS 规范。
- `C:\Program Files\Huawei\DevEco Studio\sdk\default\hms\ets\api\@hms.hds.hdsBaseComponent.d.ets` — API 26 的 HdsTabs minibar、style、layout mode、animation callbacks 声明。
- `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\ets\component\marquee.d.ts`、`text.d.ts` — API 26 的 Marquee/Text marquee 行为声明。

## Related specs

- `.trellis/spec/frontend/component-guidelines.md`：system immersive-light 的标题/tab bar 范围，以及内容操作应使用共享 HDS action helper。
- `.trellis/spec/frontend/state-management.md`：`Index.ets` 是全局 `@Provider` 状态源，`Play.ets` 为 consumer；不要在 minibar 中复制播放状态。
- `.trellis/spec/frontend/index.md`：frontend 文件/组件组织和 HDS 导航约定。
- `.trellis/tasks/10-27-fix-search-item-radius-spacing/research/play-bottom-safe-area.md`、`play-bottom-gap-api26.md`、`play-square-cover.md`、`hds-tabs-radius.md`：已有 safe-area、cover、HdsTabs material/radius 研究，可作为本次实现的交叉参考；本文件未修改它们。

## Caveats / Not Found

- 未在仓库中找到现成 `Marquee`、`TextOverflow.MARQUEE`、`marqueeOptions` 或 title/subtitle repeated-scroll helper；marquee 是新增实现点。
- 未在当前 `HdsActionBar` 用法中找到一个可直接表达“左 cover + 中间文本 + 右三按钮”的现成 expanded layout；`HdsActionBar` 当前是 primary button + start/end button arrays，需通过官方 HdsTabs `miniBarBuilder` 或新的共享 builder 重新组织。
- `HdsTabsFloatingStyle` 声明没有独立 radius 字段；胶囊外观应依赖 HDS floating/material，而不是在 `barFloatingStyle` 中添加未声明属性。
- 只做了源码、SDK 声明和官方文档的只读核查，未运行真机/模拟器；collapsed 点击优先级、HdsTabs 动画回调时序、marquee 完成后重启方式、71x71 progress ring 是否被默认 clip 裁切，都必须在 API 26 目标设备上验证。
- AGENTS.md 要求命令前缀 `rtk`，但当前环境没有可执行的 `rtk`；因此本次检索使用等价的 PowerShell/`rg` 只读命令。未进行 build、git 操作或任何源文件修改。
