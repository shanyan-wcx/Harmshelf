import { getFeed, searchPodcasts } from "../../utils/Api"
import { Podcast, SearchPodcast } from "../../utils/Interface"
import { ConfigurationConstant } from "@kit.AbilityKit"
import { env } from "../../utils/Class"

@ComponentV2
export struct Add {
  private addScroller: Scroller = new Scroller()
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Local term: string = ""
  @Local searchPodcasts: SearchPodcast[] = []
  @Local showConfirm: boolean = false
  @Local podcast: Podcast | undefined = undefined

  @Builder
  confirmBuilder() {
    Column() {
      Text("确认添加" + this.podcast?.metadata.title + "?")
        .fontSize(19)
        .margin({ bottom: 20 })

      if (this.displayWidth >= 600) {
        Blank()
          .height(160)
      }

      Row({ space: 20 }) {
        Button({ type: ButtonType.Normal }) {
          Text("取消")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(8)
        .onClick(() => {
          this.showConfirm = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("确认")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(8)
        .onClick(async () => {
          this.showConfirm = false
          this.getUIContext().getPromptAction().showToast({
            message: '暂不支持该功能！',
            duration: 500
          });
          // let status = await addPodcast(this.podcast)
          // if (status) {
          //   this.showConfirm = false
          // } else {
          //   this.getUIContext().getPromptAction().showToast({
          //     message: '添加播客失败，请检查网络！',
          //     duration: 500
          //   });
          // }
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
  }

  build() {
    Stack() {
      Scroll(this.addScroller) {
        Column() {
          if (this.searchPodcasts.length > 0) {
            ForEach(this.searchPodcasts, (searchPodcast: SearchPodcast, index) => {
              Row() {
                Image(searchPodcast.cover)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width(60)
                  .aspectRatio(1)
                  .borderRadius(8)
                  .margin({ right: 10 })
                  .draggable(false)

                Column() {
                  Text(searchPodcast.title)
                    .fontSize(17)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 5 })

                  Text("by " + searchPodcast.artistName)
                    .fontSize(15)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(70)
              .margin({ bottom: index === this.searchPodcasts.length - 1 ? (this.isStartPlaying ? 94 : 10) : 0 })
              .onClick(async () => {
                this.podcast = await getFeed(searchPodcast.feedUrl)
                if (this.podcast) {
                  console.log(JSON.stringify(this.podcast))
                  this.showConfirm = !this.showConfirm
                } else {
                  this.getUIContext().getPromptAction().showToast({
                    message: '获取播客失败，请检查网络！',
                    duration: 500
                  });
                }
              })
            })
          }

          if (this.searchPodcasts.length === 0) {
            Column() {
              Text("没有结果")
                .fontSize(32)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
          }
        }
        .bindSheet(this.showConfirm, this.confirmBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: SheetType.CENTER,
          title: {
            title: "确认添加"
          },
          showClose: false,
          onDisappear: () => {
            this.showConfirm = false
          }
        })
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .padding({ top: 36 + 70, bottom: this.isStartPlaying ? 84 : 0 })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .scrollBar(BarState.Off)

      Search()
        .width('100%')
        .height(45)
        .borderRadius(8)
        .margin({ top: 56, bottom: 20 })
        .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
        .backgroundBrightness({
          rate: env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 0.2 : 0.5,
          lightUpDegree: env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 0.1 : 0.5
        })
        .caretStyle({
          color: $r('sys.color.font')
        })
        .searchButton("   搜索   ", {
          fontColor: $r('sys.color.font'),
          autoDisable: true
        })
        .onChange((value: string) => {
          this.term = value
        })
        .onSubmit(async (query) => {
          if (query.length !== 0) {
            this.showLoadingProgress = true
            this.searchPodcasts = await searchPodcasts(this.term)
            this.showLoadingProgress = false
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
    .alignContent(Alignment.Top)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}