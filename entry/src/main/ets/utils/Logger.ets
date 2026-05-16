export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

export interface LogEntry {
  level: LogLevel
  message: string
  timestamp: string
}

const MAX_LOGS = 1000
let entries: LogEntry[] = []
let callback: ((entries: LogEntry[]) => void) | null = null

function push(level: LogLevel, message: string) {
  const now = new Date()
  const ts = `${String(now.getHours()).padStart(2, '0')}:${
    String(now.getMinutes()).padStart(2, '0')}:${
    String(now.getSeconds()).padStart(2, '0')}`
  entries.push({ level, message, timestamp: ts })
  if (entries.length > MAX_LOGS) {
    entries.shift()
  }
  callback?.(entries)
}

export class Logger {
  static info(message: string) {
    console.info(message)
    push(LogLevel.INFO, message)
  }

  static warn(message: string) {
    console.warn(message)
    push(LogLevel.WARN, message)
  }

  static error(message: string) {
    console.error(message)
    push(LogLevel.ERROR, message)
  }

  static debug(message: string) {
    console.debug(message)
    push(LogLevel.DEBUG, message)
  }

  static getEntries(): LogEntry[] {
    return entries
  }

  static clear() {
    entries = []
    callback?.(entries)
  }

  static setCallback(cb: (entries: LogEntry[]) => void) {
    callback = cb
  }
}
