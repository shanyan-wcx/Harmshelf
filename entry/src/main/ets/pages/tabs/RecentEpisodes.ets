import { getRecentEpisodes } from "../../utils/Api";
import { EpisodeComponent } from "../../utils/Component";
import { Episode, Library } from "../../utils/Interface";
import { getBottomContentInset } from '../../utils/Layout';

@ComponentV2
export struct RecentEpisodes {
  @Consumer() recentEpisodesScroller: Scroller = new Scroller();
  @Consumer() recentEpisodes: Episode[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() recentEpisodesPage: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() statusBarHeight: number = 0
  build() {
    Stack() {
      List({ scroller: this.recentEpisodesScroller }) {
        ListItem() {
          Text("最新剧集")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 16 })
        }
        .clip(false)

        Repeat<Episode>(this.recentEpisodes)
          .each((repeatItem: RepeatItem<Episode>) => {
            ListItem() {
              EpisodeComponent({
                item: repeatItem.item
              })
            }
            .clip(false)
          })
          .virtualScroll({ totalCount: this.recentEpisodes.length })
          .key((item: Episode) => item.id)
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .padding({ top: this.statusBarHeight + 56 + 31, left: 20, right: 20, bottom: getBottomContentInset(20, this.isStartPlaying, 104) })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .cachedCount(2)
      .visibility(this.showLoadingProgress || this.recentEpisodes.length === 0 ? Visibility.None : Visibility.Visible)
      .clip(false)
      .onReachEnd(async () => {
        let tmpEpisodes: Episode[] = await getRecentEpisodes(this.library!.id, this.recentEpisodesPage + 1)
        if (tmpEpisodes.length > 0) {
          this.recentEpisodesPage++
          this.recentEpisodes.push(...tmpEpisodes)
        }
      })

      Column() {
        Text("没有剧集")
          .fontSize(24)
          .fontColor($r('sys.color.font'))
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 100 })
      .justifyContent(FlexAlign.Center)
      .visibility(this.showLoadingProgress || this.recentEpisodes.length > 0 ? Visibility.None : Visibility.Visible)
    }
    .width('100%')
    .height('100%')
    .clip(false)
  }
}
