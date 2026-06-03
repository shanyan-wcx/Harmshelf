# Logger 逐条写入文件

## 问题
播放器在真机后台播放时闪退（无错误日志），模拟器无法复现。需要将应用日志实时写入文件以便事后排查。

## 需求

1. **逐条写入**：每次调用 `Logger.info/warn/error/debug` 时，立即将日志写入文件
2. **多文件轮转**：保留最近 3 个日志文件，超出时删除最旧的
3. **保存位置**：应用沙箱 `{context.filesDir}/logs/` 目录
4. **文件命名**：`harmshelf-YYYY-MM-DD-HH-mm-ss.log`
5. **格式**：`[HH:MM:SS] [LEVEL] message\n`
6. **生命周期**：在 `Index.aboutToAppear` 中启动日志文件记录，`aboutToDisappear` 中关闭 fd
7. **无阻塞**：写入使用同步 API（`fs.writeSync`），避免异步队列丢失日志

## 改动文件

- `entry/src/main/ets/utils/Logger.ets`：新增文件写入相关静态方法
- `entry/src/main/ets/pages/Index.ets`：接入启动和关闭

## 测试标准

- 日志页面（Log.ets）仍然正常工作
- 启动应用后 `{filesDir}/logs/` 下生成日志文件
- 文件中包含每个 Logger 调用的记录
- 日志文件超过 3 个时自动清理最旧的
