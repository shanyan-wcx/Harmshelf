# 实现计划

1. 复核 `MiniBarState`、`PlaybackMiniBar`、`Play.playBuilder`、`Index` Provider 和
   全屏左上角/关闭按钮的全部调用点，记录当前尺寸、底部位置和命中链。
2. 在共享组件中增加 `PlayerTransitionState`，由 `Index` 提供；保持 `MiniBarState`
   的 HdsTabs 过期回调保护，但把 minibar 交互判断改为目标状态语义。
3. 在 `PlaybackMiniBar` 增加向上 `PanGesture`、拖拽进度更新、直接点击打开和
   折叠态 HdsTabs 事件穿透；将开始、补全、取消/关闭逻辑收敛到少量共享方法。
4. 在 `Play.playBuilder` 根节点使用共享进度做从播放条锚点到全屏的缩放/位移/圆角
   过渡；左上角按钮改为反向动画后再关闭 `showPlay`，其余关闭路径保持原逻辑。
5. 保留并核对封面分支、播放源、标题和控制按钮在进度为 0/中间/1 时的渲染；移除
   失效的动画期点击禁用分支和不再需要的临时源绑定。
6. 更新前端组件规范与本任务研究记录，补充 HdsTabs 回调与交互进度分离的约束。
7. 运行 `git diff --check` 和 DevEco CLI API 26 debug 构建；运行 Trellis check，
   复核 HdsTabs 命中、全屏关闭时序及现有播放逻辑。
8. 提交代码、归档任务并记录会话；未得到用户要求前不推送远端。

## 回滚点

- 首个代码提交前只修改 `Component.ets`、`Index.ets`、`Play.ets` 及对应 Trellis
  记录/规范。
- 若 ArkTS 不接受动态变换参数，保留状态流与手势逻辑，改用 SDK 支持的等价
  `offset/scale` 组合；不回退到默认透明度模态动画。
