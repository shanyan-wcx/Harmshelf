import { getRecentEpisodes } from "../../utils/Api";
import { EpisodeComponent } from "../../utils/Component";
import { Episode, Library } from "../../utils/Interface";
import { getBottomContentInset } from '../../utils/Layout';

@ComponentV2
export struct RecentEpisodes {
  private recentEpisodesScroller: Scroller = new Scroller();
  @Consumer() recentEpisodes: Episode[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() recentEpisodesPage: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() statusBarHeight: number = 0
  build() {
    Stack() {
      Scroll(this.recentEpisodesScroller) {
        Column() {
          Text("最新剧集")
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })

          Column() {
            ForEach(this.recentEpisodes, (episode: Episode, index) => {
              EpisodeComponent({
                item: episode
              })
            })
          }
          .offset({ y: -5 })

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
      .clip(false)
      .padding({ top: this.statusBarHeight + 56 + 31, left: 20, right: 20, bottom: getBottomContentInset(20, this.isStartPlaying, 104) })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .clip(false)
      .onReachEnd(async () => {
        let tmpEpisodes: Episode[] = await getRecentEpisodes(this.library!.id, this.recentEpisodesPage + 1)
        if (tmpEpisodes.length > 0) {
          this.recentEpisodesPage++
          this.recentEpisodes.push(...tmpEpisodes)
        }
      })
    }
    .width('100%')
    .height('100%')
    .clip(false)
  }
}
