# 下载弹窗增加选择章节范围

## 需求
下载弹窗中增加起始章节和结束章节输入框，支持选择下载范围。

## 改动
- **LibraryItemDetail.ets**: 
  - 新增 `downloadStart` 和 `downloadEnd` 状态变量
  - 改造 `confirmDownloadBuilder`：添加两个 TextInput 输入框，限定数字
  - 校验逻辑：起始>0、起始<结束、结束≤最大章节
  - 未输入时默认下载全部
  - 校验失败 toast 提示，不关闭弹窗
  - 成功时只下载选中范围
