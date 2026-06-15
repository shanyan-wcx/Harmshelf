# 修复收听时长异常的bug

## Goal

修复收听时长 `timeListened` 在某些场景下被错误上报为数十万小时的问题。将壁钟时间改为追踪实际播放时间。

## Root Cause

`syncTime` 初始化为 0 (`@Provider() syncTime: number = 0`)。`syncProgress()` 在 `syncTime` 未初始化时调用：
```
timeListened: new Date().getTime() / 1000 - this.syncTime
            = Date.now()/1000 - 0 ≈ 17亿秒 ≈ 49万小时
```

## Requirements

1. 改用 `actualListenTime`（实际播放累积秒数）替代壁钟时间作为 `timeListened`
2. 在 `timeUpdate` 回调中根据音频 `currentSec - lastPosition` 差值累加，仅 `isPlaying` 且 `delta > 0` 时计入
3. seek/切轨后用正确位置更新 `lastPosition`，消除 delta 计算丢失
4. 同步成功后重置 `actualListenTime = 0`

## Changes (仅 Index.ets)

### 新增变量 (L201 附近)
```typescript
@Local actualListenTime: number = 0
@Local lastPosition: number = -1
```

### timeUpdate 回调 (L654) — 插入 delta 累加
```typescript
let currentSec = time / 1000
if (this.isPlaying && this.lastPosition >= 0) {
  let delta = currentSec - this.lastPosition
  if (delta > 0) {
    this.actualListenTime += delta
  }
}
this.lastPosition = currentSec
```

### seekDone 回调 (L701) — 新增
```typescript
this.lastPosition = seekDoneTime / 1000
```

### prepared 状态 (L869) — 新增
```typescript
this.lastPosition = seekTarget
```

### 两处 timeListened (L385, L408) — 替换
```typescript
// 原
timeListened: new Date().getTime() / 1000 - this.syncTime
// 改为
timeListened: this.actualListenTime
```

### 同步成功后 (L425) — 新增
```typescript
this.actualListenTime = 0
```

## Acceptance Criteria

- [ ] `timeListened` 不会出现异常大值（数百至数十万小时）
- [ ] 正常播放时累计值与实际音频播放时长一致
- [ ] 暂停、seek、切轨、skip-intro 均不影响累计精度
- [ ] 同步失败后 `actualListenTime` 不丢、继续累计
- [ ] 构建通过，无新增警告

## Out of Scope

- Server 端数据清理（已有异常大值的 `timeListened`）
- 其他页面的 UI 改动
- 跟踪 `syncTime` 变量的清理（保留但不再使用）
