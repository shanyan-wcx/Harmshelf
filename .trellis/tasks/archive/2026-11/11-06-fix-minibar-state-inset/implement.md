# 实施计划

1. 重新检查 `MyNavigation.bottomTabBarBuilder` 的三个 HdsTabs 回调和 `PlaybackMiniBar.expandedBarBuilder` 的 standalone 几何链，确认调用方、状态引用和所有宿主。
2. 在 `Component.ets` 中加入动画协调状态：按开始回调的旧状态推导目标状态，动画期间屏蔽旧样式覆盖，结束回调落最终状态；保留普通样式更新的初始化路径。
3. 在 `Play.ets` 中把 standalone 内容校正从“宽度 100% + 向右偏移”改为“宽度增加 8vp + 不偏移”，带 tab 的现有右侧边距保持不变。
4. 搜索所有 `MiniBarBuilderOptions`、`PlaybackMiniBar`、`desktopMiniBarBuilder` 调用点，确保没有遗漏或改变 PC/2in1 行为。
5. 运行 `git diff --check` 和 DevEco API 26 debug 构建；检查 ArkTS 错误、未使用状态和现有告警是否没有新增。
6. 在可用设备上验证：折叠/展开首帧内容、快速连续切换不闪回、非 tab 左右边距、三按钮交互和打开全屏；若无设备，明确记录未做真机视觉验证。
7. 更新前端规范/任务研究记录，提交修改并按 Trellis 流程归档任务、记录会话。

## 风险与回滚点

- 最大风险是 HdsTabs 在某些版本的回调触发顺序不同；`miniBarAnimationActive` 和开始/结束双保险用于避免旧状态覆盖。
- 非 tab 宽度扩展依赖所有祖先 `.clip(false)` 已存在；若设备仍裁切，下一步只检查祖先裁切，不再继续叠加负偏移。
- 回滚点：代码提交前可丢弃工作树；提交后使用该提交的 revert，不修改播放数据。
