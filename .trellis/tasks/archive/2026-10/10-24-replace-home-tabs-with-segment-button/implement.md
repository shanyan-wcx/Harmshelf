# 实施计划：首页仅使用标题栏分段按钮切换

## 实施清单

1. 在 `Home.ets` 删除 HdsTabs 相关导入、控制器、tabBar 样式和点击回调。
2. 保留 `getHomeTabLabels()` 与共享 `topTabIndex`/`needUpdate`，新增最小的书籍/播客内容 builder 分支，按现有动态条件渲染页面组件。
3. 在 `Component.ets` 保留 `.padding({ left: 16, right: 16 })`，为标题栏按钮容器增加顶部对齐配置，保持水平居中和 56 高度 bottomBuilder。
4. 复核动态选项索引：书籍管理员收藏、作者、播放列表；播客管理员添加、播放列表；普通用户路径。
5. 运行 `git diff --check` 和 `devecocli build`。
6. 运行 Trellis 质量检查，确认无 HdsTabs 残留、无无关改动，再提交并归档任务。

## 风险点

- `Home.ets` 的内容组件原先由 HdsTabs 管理生命周期，替换为条件 builder 后需要确认只有当前索引内容被创建。
- 动态播放列表是末项，不能硬编码为固定索引。
- 标题栏底部区域的高度和左右 padding 属于现有布局约束，不应在本任务中重置。

## 回滚

若构建失败或内容映射不完整，回滚 `Home.ets` 的 builder 替换即可；不回退用户在 `Component.ets` 中保留的 16 padding。
