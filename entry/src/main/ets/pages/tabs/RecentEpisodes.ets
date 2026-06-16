import { getRecentEpisodes } from "../../utils/Api";
import { EpisodeComponent, GlassFloatingButton } from "../../utils/Component";
import { Episode, Library } from "../../utils/Interface";

@ComponentV2
export struct RecentEpisodes {
  private recentEpisodesScroller: Scroller = new Scroller();
  @Consumer() recentEpisodes: Episode[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() recentEpisodesPage: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() showLoadingProgress: boolean = false

  build() {
    Stack() {
      Scroll(this.recentEpisodesScroller) {
        Column() {
          Text("最新剧集")
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 20 })

          ForEach(this.recentEpisodes, (episode: Episode, index) => {
            EpisodeComponent({
              item: episode
            })
          })

          Column() {
            Text("没有剧集")
              .fontSize(32)
              .fontColor($r('sys.color.font'))
          }
          .width('100%')
          .height('100%')
          .padding({ bottom: 100 })
          .justifyContent(FlexAlign.Center)
          .visibility(this.recentEpisodes.length === 0 ? Visibility.Visible : Visibility.None)
        }
        .alignItems(HorizontalAlign.Start)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 36, left: 20, right: 20, bottom: this.isStartPlaying ? 104 : 20 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .onReachEnd(async () => {
        let tmpEpisodes: Episode[] = await getRecentEpisodes(this.library!.id, this.recentEpisodesPage + 1)
        if (tmpEpisodes.length > 0) {
          this.recentEpisodesPage++
          this.recentEpisodes.push(...tmpEpisodes)
        }
      })

      GlassFloatingButton({
        scroller: this.recentEpisodesScroller,
        isStartPlaying: this.isStartPlaying
      })
      .position({
        right: 15,
        bottom: this.isStartPlaying ? 99 : 15
      })
    }
    .width('100%')
    .height('100%')
  }
}