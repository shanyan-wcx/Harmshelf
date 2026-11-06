# 实施计划

1. 检查 `PlaybackMiniBar.openPlayer`、minibar 封面和 `Play.playBuilder` 的调用关系。
2. 增加打开全屏时的动画状态，并在 `animateTo` 闭包中显示 ContentCover。
3. 仅为全屏打开过程绑定共享封面转场 ID；补充 ContentCover 的 `ModalTransition.NONE` 和稳定分支 ID。
4. 运行 `git diff --check` 与 DevEco API 26 Debug 构建。
5. 检查关闭按钮和原有播放交互未改变，提交并归档任务。
