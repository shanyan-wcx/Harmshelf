# 修复后台播放返回卡顿闪退

## 问题
长时间后台播放后回到应用，应用卡顿甚至闪退。

## 根因
1. `aboutToDisappear` 释放 AVPlayer 但未停止长时任务和销毁 AVSession → 页面重建后新旧任务/会话冲突
2. `stopped` 状态直接设 `continuousTaskRunning = false` 而不调 `stopBackgroundRunning()` → 长时任务泄露
3. 退后台后旋转动画持续运行，返回前台时 UI 线程过载
4. EntryAbility 的 `onBackground/onForeground` 为空函数，无法协调前后台行为

## 改动

### 改动1: Index.ets `aboutToDisappear()` 
追加 `stopContinuousTask()` + `session?.destroy()` + `session = undefined`

### 改动2: Index.ets `'stopped'` handler 
`this.continuousTaskRunning = false` → `await this.stopContinuousTask()`

### 改动3: EntryAbility.ets `onBackground/onForeground`
`AppStorage.set<boolean>('appInBackground', true/false)`

### 改动4: Play.ets
监听 `appInBackground`，后台时 `stopRotate()`，前台恢复旋转
