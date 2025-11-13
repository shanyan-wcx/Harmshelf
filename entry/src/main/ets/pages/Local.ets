@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()

  build() {
    Stack() {
      Scroll(this.LocalMediaScroller) {
        Column() {
          Text("没有本地媒体")
            .fontSize(32)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: 56, bottom: 100 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}