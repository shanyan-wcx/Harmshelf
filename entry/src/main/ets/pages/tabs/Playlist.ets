import { PlaylistItemComponent, GlassFloatingButton } from "../../utils/Component";
import { Playlist } from "../../utils/Interface";

@ComponentV2
export struct AllPlaylists {
  private playlistScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() playlists: Playlist[] = []
  @Consumer() statusBarHeight: number = 0

  build() {
    Stack() {
      Column() {
        Grid(this.playlistScroller) {
          GridItem() {
            Row() {
              Blank()
                .width('100%')
                .height(this.statusBarHeight + 56 + 36)
            }
          }
          .columnStart(0)
          .columnEnd(this.displayWidth >= 1400 ? 5 :
            (this.displayWidth >= 1000 ? 4 :
              (this.displayWidth >= 800 ? 3 :
                (this.displayWidth >= 400 ? 2 : 1))))

          ForEach(this.playlists, (playlist: Playlist, index) => {
            GridItem() {
              PlaylistItemComponent({
                playlist: playlist
              })
                .margin({ bottom: index === this.playlists.length - 1 ? (this.isStartPlaying ? 104 : 20 ): 0 })
            }
          })
        }
        .width('100%')
        .height('100%')
        .columnsTemplate(this.displayWidth >= 1400 ? "1fr 1fr 1fr 1fr 1fr 1fr" :
          (this.displayWidth >= 1000 ? "1fr 1fr 1fr 1fr 1fr" :
            (this.displayWidth >= 800 ? "1fr 1fr 1fr 1fr" :
              (this.displayWidth >= 400 ? "1fr 1fr 1fr" : "1fr 1fr"))))
        .columnsGap(20)
        .rowsGap(15)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .padding({
          left: 20,
          right: 20
        })
        .clip(false)
        .onReachEnd(async () => {

        })
        .visibility(this.playlists.length > 0 ? Visibility.Visible : Visibility.None)


        Column() {
          Text("没有播放列表")
            .fontSize(32)
            .fontColor($r('sys.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 100 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.playlists.length === 0 ? Visibility.Visible : Visibility.None)

      }
      .width('100%')
      .height('100%')
      .clip(false)


      GlassFloatingButton({
        scroller: this.playlistScroller,
        isStartPlaying: this.isStartPlaying
      })
      .position({
        right: 15,
        bottom: this.isStartPlaying ? 99 : 15
      })
    }
    .width('100%')
    .height('100%')
    .clip(false)
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
  }
}
