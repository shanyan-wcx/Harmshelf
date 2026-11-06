# 实现计划

1. 检查 `Play.ets` 中播放器封面共享 id、`animateTo`、`bindContentCover` 和非 Tab
   宽度的全部调用点。
2. 将非 Tab 条宽度改为 `calc(100% + 22vp)`。
3. 给共享封面源节点与全屏封面三个分支补充同样的透明度 transition，保持现有
   geometry id 条件和稳定节点 id。
4. 执行相关源码搜索，确认没有遗漏的 `+24vp` 或无配对的播放器封面分支；运行
   DevEco CLI debug 构建。
5. 检查 diff 后提交代码，归档 Trellis 任务并记录本次会话。
