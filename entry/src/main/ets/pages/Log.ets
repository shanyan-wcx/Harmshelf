@ComponentV2
export struct Log {

  build() {
    Scroll() {
      Column() {
        Text("暂不支持")
          .fontSize(34)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 56, bottom: 100 })
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
    .scrollBar(BarState.Off)
  }
}