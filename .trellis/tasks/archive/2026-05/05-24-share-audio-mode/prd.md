# 增加与其他应用同时播放的可选功能

## 需求

用户希望在听书过程中开启可选功能，允许本应用与其他应用（如音乐App、视频App等）同时播放音频，不被其他应用中断。

## 方案

利用 HarmonyOS `AudioSession` API，在播放时设置并发模式 `CONCURRENCY_MIX_WITH_OTHERS`，使本应用与其他应用的声音并发混音。

### 涉及文件

| 文件 | 改动 |
|------|------|
| `entry/src/main/ets/pages/Index.ets` | `PlaySetting` 新增 `shareAudio` 字段；新增 `activateAudioSession()` / `deactivateAudioSession()` 方法；在 `stateChange` 的 playing/paused/idle/stopped/error 中管理 AudioSession 生命周期 |
| `entry/src/main/ets/pages/Setting.ets` | 在「播放设置」区新增「与其他应用同时播放」Switch 开关 |

### 关键逻辑

- 开关默认关闭，行为与当前一致（被其他应用中断时暂停）
- 开关开启后，播放时激活 `AudioSession` 设置 `CONCURRENCY_MIX_WITH_OTHERS`
- 暂停/停止/出错时，停用 `AudioSession` 释放焦点
- `audioInterrupt` 回调无需改动：`MIX_WITH_OTHERS` 模式下系统不会向本应用发送来自其他媒体应用的强制中断事件
