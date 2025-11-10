@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()

  build() {
    Stack() {
      Scroll(this.LocalMediaScroller) {
        Column() {
          Text("暂不支持")
            .fontSize(32)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: 56, bottom: 100 })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}