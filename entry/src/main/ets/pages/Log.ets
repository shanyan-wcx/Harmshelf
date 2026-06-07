import { LogEntry, LogLevel, Logger } from '../utils/Logger';
import { pasteboard } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

@ComponentV2
export struct Log {
  @Consumer() logScroller: Scroller = new Scroller()
  @Consumer() isStartPlaying: boolean = false
  @Consumer() logs: LogEntry[] = []
  @Consumer() context: common.UIAbilityContext | undefined = undefined
  @Local selectedFilter: number = 1
  @Local showLoadingProgress: boolean = false
  @Local displayLogs: LogEntry[] = []

  private filterOptions: SelectOption[] = [
    { value: 'DEBUG' },
    { value: 'INFO' },
    { value: 'WARN' },
    { value: 'ERROR' }
  ]

  get filteredLogs(): LogEntry[] {
    const result: LogEntry[] = []
    for (const e of this.logs) {
      if (e.level >= this.selectedFilter) {
        result.push(e)
      }
    }
    return result
  }

  getColor(level: LogLevel): ResourceColor {
    if (level === LogLevel.DEBUG) {
      return Color.Green
    } else if (level === LogLevel.INFO) {
      return $r('sys.color.font')
    } else if (level === LogLevel.WARN) {
      return Color.Orange
    }
    return Color.Red
  }

  @Monitor('logs')
  onLogsChange() {
    if (this.showLoadingProgress) {
      return
    }
    this.displayLogs = this.filteredLogs
    setTimeout(() => {
      this.logScroller.scrollEdge(Edge.Bottom)
    }, 25)
  }

  refreshDisplay() {
    this.showLoadingProgress = true
    this.displayLogs = []
    setTimeout(() => {
      this.displayLogs = this.filteredLogs
      this.showLoadingProgress = false
      setTimeout(() => {
        this.logScroller.scrollEdge(Edge.Bottom)
      }, 75)
    }, 50)
  }

  copyAllLogs() {
    const text = this.filteredLogs.map((log: LogEntry) => `${log.timestamp} ${log.message}`).join('\n')
    if (text.length === 0) {
      return
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    try { pasteboard.getSystemPasteboard().setData(data) } catch (_) {}
    try { this.getUIContext().getPromptAction().showToast({ message: '日志已复制', duration: 500 }) } catch (_) {}
  }

  async shareLogs() {
    const ctx = this.context
    if (ctx === undefined) {
      return
    }
    const dir = ctx.cacheDir
    const now = new Date()
    const name = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}_${String(now.getMinutes()).padStart(2, '0')}_${String(now.getSeconds()).padStart(2, '0')}.log`
    const filePath = `${dir}/${name}`

    let files: string[] = []
    try { files = fileIo.listFileSync(dir) } catch (_) {}
    for (const f of files) {
      if (f.endsWith('.log') && f !== name) {
        try {
          fileIo.unlinkSync(`${dir}/${f}`)
        } catch {}
      }
    }

    const content = this.filteredLogs.map((log: LogEntry) => `${log.timestamp} ${log.message}`).join('\n')
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(file.fd, content)
      fileIo.closeSync(file)
    } catch (_) {}

    const uri = fileUri.getUriFromPath(filePath)
    let utdTypeId: string | undefined
    try {
      utdTypeId = utd.getUniformDataTypeByFilenameExtension('.log', utd.UniformDataType.PLAIN_TEXT)
    } catch (e) {
      let error: BusinessError = e as BusinessError
      Logger.error(`getUniformDataTypeByFilenameExtension failed: ${error.message}`)
    }
    if (utdTypeId === undefined) {
      utdTypeId = utd.UniformDataType.PLAIN_TEXT
    }
    const shareData = new systemShare.SharedData({ utd: utdTypeId, uri: uri })
    const controller = new systemShare.ShareController(shareData)
    try {
      controller.show(ctx, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      })
    } catch (_) {}
  }

  build() {
    Stack() {
      if (this.showLoadingProgress) {
        Column() {
          LoadingProgress()
            .width(56)
            .height(56)
            .color($r('sys.color.loading_progress_focused_color'))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.displayLogs.length > 0) {
        List({ scroller: this.logScroller }) {
          ForEach(this.displayLogs, (log: LogEntry, index: number) => {
          ListItem() {
            Row() {
              Text(log.timestamp)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize(16)
                .margin({ right: 15 })
                .copyOption(CopyOptions.LocalDevice)
                .textSelectable(TextSelectableMode.SELECTABLE_FOCUSABLE)
              Text(log.message)
                .fontSize(16)
                .fontColor(this.getColor(log.level))
                .wordBreak(WordBreak.BREAK_ALL)
                .layoutWeight(1)
                .textAlign(TextAlign.JUSTIFY)
                .copyOption(CopyOptions.LocalDevice)
                .textSelectable(TextSelectableMode.SELECTABLE_FOCUSABLE)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 4 })
          .margin({ top: index === 0 ? 56 : 0, bottom: index === this.displayLogs.length - 1 ? (this.isStartPlaying ? 150 : 79) : 0 })
          })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None)
      }

      if (!this.showLoadingProgress && this.displayLogs.length === 0) {
        Text('没有日志')
          .fontSize(32)
          .fontColor($r('sys.color.font'))
          .margin({ bottom: 56 })
      }

      Row() {
        Select(this.filterOptions)
          .selected(this.selectedFilter)
          .value(this.filterOptions[this.selectedFilter].value)
          .onSelect((index: number) => {
            this.selectedFilter = index
            this.refreshDisplay()
          })
          .width(120)
          .margin({ left: 20 })
          .backgroundColor('rgba(255, 255, 255, 0.15)')
          .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
          .shadow({
            radius: 16,
            offsetX: 0,
            offsetY: 0,
            color: 'rgba(0, 0, 0, 0.25)'
          })
          .border({
            width: 0.5,
            color: 'rgba(255, 255, 255, 0.2)',
            radius: 6
          })

        Blank()
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.doc'))
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
        }
        .width(36)
        .height(36)
        .onClick(() => {
          this.copyAllLogs()
        })
        .backgroundColor('rgba(255, 255, 255, 0.15)')
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        .shadow({
          radius: 16,
          offsetX: 0,
          offsetY: 0,
          color: 'rgba(0, 0, 0, 0.25)'
        })
        .border({
          width: 0.5,
          color: 'rgba(255, 255, 255, 0.2)',
          radius: 6
        })
        .margin({ right: 12 })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
        }
        .width(36)
        .height(36)
        .onClick(() => {
          this.shareLogs()
        })
        .backgroundColor('rgba(255, 255, 255, 0.15)')
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        .shadow({
          radius: 16,
          offsetX: 0,
          offsetY: 0,
          color: 'rgba(0, 0, 0, 0.25)'
        })
        .border({
          width: 0.5,
          color: 'rgba(255, 255, 255, 0.2)',
          radius: 6
        })
        .margin({ right: 20 })
      }
      .position({ bottom: this.isStartPlaying ? 99 : 28 })
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.refreshDisplay()
    })
  }
}
