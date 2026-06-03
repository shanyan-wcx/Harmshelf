import { fileIo as fs } from '@kit.CoreFileKit';

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
const MAX_LOG_FILES = 3
const LOG_PREFIX = 'harmshelf-'
let entries: LogEntry[] = []
let callback: ((entries: LogEntry[]) => void) | null = null
let logFd: number = -1
let fileLoggingActive: boolean = false

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
  if (fileLoggingActive && logFd !== -1) {
    const levelTag = ['D', 'I', 'W', 'E'][level]
    try {
      fs.writeSync(logFd, `[${ts}] [${levelTag}] ${message}\n`)
    } catch (_) {}
  }
}

function rotateLogFiles(dir: string): void {
  try {
    const all = fs.listFileSync(dir)
    const logFiles = all.filter(name => name.startsWith(LOG_PREFIX)).sort()
    while (logFiles.length >= MAX_LOG_FILES) {
      const oldest = logFiles.shift()!
      try { fs.unlinkSync(`${dir}/${oldest}`) } catch (_) {}
    }
  } catch (_) {}
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

  static startFileLogging(logDir: string): void {
    if (fileLoggingActive) return
    try {
      if (!fs.accessSync(logDir)) {
        fs.mkdirSync(logDir)
      }
    } catch (_) { return }
    rotateLogFiles(logDir)
    const now = new Date()
    const ts = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}-${String(now.getMinutes()).padStart(2, '0')}-${String(now.getSeconds()).padStart(2, '0')}`
    const filePath = `${logDir}/${LOG_PREFIX}${ts}.log`
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      logFd = file.fd
      fileLoggingActive = true
    } catch (_) {}
  }

  static stopFileLogging(): void {
    if (!fileLoggingActive) return
    fileLoggingActive = false
    if (logFd !== -1) {
      try { fs.closeSync(logFd) } catch (_) {}
      logFd = -1
    }
  }
}
