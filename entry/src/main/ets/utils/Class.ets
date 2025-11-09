import { ConfigurationConstant } from '@kit.AbilityKit';

export class Env {
  language: string | undefined;
  colorMode: ConfigurationConstant.ColorMode | undefined;
  fontSizeScale: number | undefined;
  fontWeightScale: number | undefined;
}

export let env: Env = new Env();

export class CountdownTimer {
  private durationMs: number = 0
  private remainingMs: number = 0
  private timerId: number | null = null
  private intervalId: number | null = null
  private startTime: number = 0
  private isPaused: boolean = true
  private onFinish?: () => void
  private onTick?: (remainingSec: number) => void

  /**
   * @param durationSec 倒计时总时长（秒）
   * @param onFinish 倒计时结束回调
   * @param onTick 每秒更新回调
   */
  constructor(durationSec: number, onFinish?: () => void, onTick?: (remainingSec: number) => void) {
    this.durationMs = durationSec * 1000
    this.remainingMs = this.durationMs
    this.onFinish = onFinish
    this.onTick = onTick
  }

  /** 启动倒计时 */
  start() {
    if (!this.isPaused) return
    this.isPaused = false
    this.startTime = Date.now()
    this._startInterval()
    this._run()
  }

  /** 暂停倒计时 */
  pause() {
    if (this.isPaused) return
    this.isPaused = true
    if (this.timerId) {
      clearTimeout(this.timerId)
      this.timerId = null
    }
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    const elapsed = Date.now() - this.startTime
    this.remainingMs = Math.max(0, this.remainingMs - elapsed)
  }

  /** 继续倒计时 */
  resume() {
    if (!this.isPaused) return
    this.start()
  }

  /** 重置倒计时（可选传入新秒数） */
  reset(newDurationSec?: number) {
    this.clear()
    if (newDurationSec !== undefined) {
      this.durationMs = newDurationSec * 1000
    }
    this.remainingMs = this.durationMs
  }

  /** 清除倒计时（彻底销毁） */
  clear() {
    if (this.timerId) {
      clearTimeout(this.timerId)
      this.timerId = null
    }
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.isPaused = true
    this.remainingMs = this.durationMs
  }

  /** 获取剩余秒数 */
  getRemainingSeconds(): number {
    if (this.isPaused) return Math.ceil(this.remainingMs / 1000)
    const elapsed = Date.now() - this.startTime
    return Math.ceil(Math.max(0, this.remainingMs - elapsed) / 1000)
  }

  /** 内部倒计时主定时器（结束时触发） */
  private _run() {
    if (this.isPaused) return
    this.timerId = setTimeout(() => {
      this.isPaused = true
      this.timerId = null
      this.remainingMs = 0
      if (this.intervalId) {
        clearInterval(this.intervalId)
        this.intervalId = null
      }
      if (this.onTick) this.onTick(0)
      if (this.onFinish) this.onFinish()
    }, this.remainingMs)
  }

  /** 内部每秒刷新逻辑 */
  private _startInterval() {
    if (this.intervalId) clearInterval(this.intervalId)
    this.intervalId = setInterval(() => {
      const sec = this.getRemainingSeconds()
      if (this.onTick) this.onTick(sec)
    }, 1000)
  }
}