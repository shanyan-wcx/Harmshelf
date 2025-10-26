import { searchPodcasts } from '../../api/Api'
import { SearchPodcast } from '../../api/Interface'

@Component
export default struct add {
  @Consume searchPodcastsValue: string
  @Consume podcasts: SearchPodcast[]
  @Consume sidebarShow: boolean
  @Consume searchPodcasts: boolean
  private listScroller: Scroller = new Scroller

  build() {
    Column() {
      Row() {
        TextInput({
          text: $$this.searchPodcastsValue,
          placeholder: "搜索 ..."
        })
          .enterKeyType(EnterKeyType.Search)
          .caretColor('#95ffffff')
          .width('100%')
          .height(32)
          .layoutWeight(1)
          .backgroundColor('#30cccccc')
          .fontColor('#95ffffff')
          .placeholderColor('#60ffffff')
          .onSubmit((value) => {

          })
          .onClick(() => {
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })

        Button() {
          Text("搜索")
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width(60)
        .height(32)
        .margin({ left: 10 })
        .backgroundColor('#30cccccc')
        .onClick(async () => {
          this.podcasts = await searchPodcasts(encodeURIComponent(this.searchPodcastsValue))
          this.searchPodcasts = true
          this.listScroller.scrollEdge(Edge.Top)
        })
      }
      .width('90%')
      .margin({ top: 20, bottom: 20 })

      List({ scroller: this.listScroller }) {
        if (this.searchPodcasts === true && this.podcasts.length === 0) {
          ListItem() {
            Column() {
              Text("未找到播客")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width('100%')
            .height('100%')
          }
        } else {
          ForEach(this.podcasts, (podcast: SearchPodcast, index) => {
            ListItem() {
              Button({ type: ButtonType.Normal }) {
                Row() {
                  Image(podcast.cover)
                    .width(80)
                    .height(80)
                    .margin({ right: 10 })
                  Column() {
                    Text(podcast.title)
                      .fontSize(20)
                      .fontColor(Color.White)
                      .maxLines(1)
                      .margin({ top: 10 })
                    Text("by " + podcast.artistName)
                      .fontSize(18)
                      .fontColor(Color.White)
                      .maxLines(1)
                    Text(podcast.genres.toString())
                      .fontSize(16)
                      .fontColor(Color.Gray)
                      .maxLines(1)
                    Text(podcast.trackCount + " 剧集")
                      .fontSize(16)
                      .fontColor(Color.Gray)
                      .maxLines(1)
                  }
                  .width('100%')
                  .height('100%')
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Start)
                }
                .width('100%')
                .height('100%')
                .padding({ left: 20, right: 20 })
              }
              .backgroundColor('#00000000')
              .width('100%')
              .height(100)
            }
          })
        }
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Fade)
    }
    .width('100%')
    .height('100%')
  }
}