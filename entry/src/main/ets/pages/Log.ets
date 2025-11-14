@ComponentV2
export struct Log {
  @Consumer() logScroller: Scroller = new Scroller()
  @Consumer() isStartPlaying: boolean = false
  @Consumer() logs: string[] = []

  @Monitor('logs')
  async scrollLogs(monitor: IMonitor) {
    this.logScroller.scrollEdge(Edge.Bottom)
  }

  onDidBuild() {
    this.logScroller.scrollEdge(Edge.Bottom)
  }

  build() {
    Scroll(this.logScroller) {
      Column() {
        if (this.logs.length > 0) {
          ForEach(this.logs, (log: string, index) => {
            Row() {
              Text(log)
                .fontSize(20)
                .wordBreak(WordBreak.BREAK_ALL)
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 10,
              bottom: 10
            })
            .backgroundColor(index % 2 === 1 ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
          })
        } else {
          Column() {
            Text("没有日志")
              .fontSize(32)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ bottom: 80 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
    .padding({ top: 56, bottom: this.isStartPlaying ? 104 : 20 })
  }
}