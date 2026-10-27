# 执行计划

1. 修改 `Search.ets`：移除 `ImmersiveActionButton` 导入和书籍/播客两处调用，改为普通 80vp 高、12vp 圆角、可点击的 `Row` 卡片。
2. 给两种结果卡片增加 `COMPONENT_THICK` 毛玻璃、系统 `sys.color.ohos_id_color_card_bg` 背景、12vp 圆角、0.5vp 主题自适应高亮边框和 `ShadowStyle.OUTER_DEFAULT_XS` 轻柔阴影；沿用原有文字颜色，不裁切卡片阴影。
3. 修改 `tabs/Add.ets`：将播客添加结果项从分割线 Column 改为相同的 80vp 高、12vp 圆角、64vp 封面 Row 卡片，保留获取 Feed 和确认面板逻辑。
4. 调整添加页 Stack/Scroll 水平布局为 16vp + 4vp，保留卡片视觉 20vp 页面边距，并关闭外层裁切以保留左右阴影。
5. 修改 `LibraryItemDetail.ets`：将章节/音轨列表改为外层 Stack 大卡片 + 内层圆角 Stack 裁切容器 + List 结构，保留原尺寸和交互，表头和数据行统一使用卡片背景，外层阴影不被裁切。
6. 给所有结果卡片增加 8vp 内部左右边距，搜索页和添加页卡片间距改为 8vp。
7. 搜索相同调用点和旧沉浸按钮引用，确认搜索页、添加页和详情列表没有遗漏；检查 diff 只包含本任务文件。
8. 使用项目要求的 `devecocli` 执行 debug build，记录编译结果。

## 验证命令

```powershell
$env:DEVECO_SDK_HOME = 'C:\Program Files\Huawei\DevEco Studio\sdk'
& 'C:\Users\21633\.bun\bin\devecocli.cmd' build --product default --build-mode debug
```
