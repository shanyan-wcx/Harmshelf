# 技术设计：minibar 到全屏播放页的共享封面转场

## 根因与约束

- minibar 到非 Tab 条的闪烁修复已经移除了 minibar 封面常驻的 `geometryTransition("cover")`，因此不能重新无条件绑定封面，否则会再次参与 minibar/非 Tab 条切换。
- 全屏播放页通过 `bindContentCover` 显示，默认模态转场会与共享元素转场叠加；需要关闭默认模态动画。
- 官方共享元素转场要求在 `animateTo` 状态闭包中同时建立源/目标绑定，并为分支首节点提供稳定 `id`。

## 方案

1. `PlaybackMiniBar` 增加仅在打开全屏播放时使用的本地状态 `playerCoverTransition`。
2. `openPlayer()` 先启用该状态，再在 `getUIContext().animateTo` 闭包中设置 `showPlay = true`。
3. minibar 封面仅在该状态为 true 时使用 `geometryTransition("playerCover")`；平时保持无封面转场，避免影响 minibar 到非 Tab 条的切换。
4. 全屏播放页封面使用同一 `playerCover` 共享元素 ID，并给各 `if/else` 分支设置稳定节点 ID。
5. `bindContentCover` 设置 `modalTransition: ModalTransition.NONE`，避免系统默认模态动画与共享元素动画叠加；其余关闭逻辑保持不变。

## 影响范围

- `entry/src/main/ets/pages/Play.ets`：minibar 打开动作、全屏封面绑定、ContentCover 选项。
- 不修改播放状态、条宽度、非 Tab 条布局、HdsTabs 原生展开/收起动画或全屏页面内容布局。

## 回滚

回退本任务提交即可恢复当前无封面转场的行为，不影响播放数据和全屏播放器功能。
