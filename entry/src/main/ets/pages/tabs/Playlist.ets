@ComponentV2
export struct AllPlaylists {
  private playlistScroller: Scroller = new Scroller();

  build() {
    Scroll(this.playlistScroller) {
      Column() {
        Text("暂不支持")
          .fontSize(34)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 36, bottom: 140 })
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
    .scrollBar(BarState.Off)
  }
}