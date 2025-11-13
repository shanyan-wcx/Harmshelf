import { addPodcast, getFeed, searchPodcasts } from "../../utils/Api"
import { Library, Podcast, SearchPodcast } from "../../utils/Interface"
import { ConfigurationConstant } from "@kit.AbilityKit"
import { env } from "../../utils/Class"

@ComponentV2
export struct Add {
  private addScroller: Scroller = new Scroller()
  @Consumer() displayWidth: number = 0
  @Consumer() library: Library | undefined = undefined
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() searchPodcasts: SearchPodcast[] = []
  @Consumer() term: string = ""
  @Local showConfirm: boolean[] = []
  @Local podcast: Podcast | undefined = undefined
  @Local autoDownload: boolean[] = []

  @Builder
  confirmBuilder(searchPodcast: SearchPodcast, podcast: Podcast, index: number) {
    Scroll() {
      Column() {
        Row() {
          Text("标题")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width(65)
            .margin({ top: 5 })

          TextInput({
            text: searchPodcast.title
          })
            .width("100%")
            .layoutWeight(1)
            .height(45)
            .borderRadius(8)
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({
              size: 18
            })
            .type(InputType.Normal)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value) => {
              searchPodcast.title = value
            })
        }
        .width('100%')
        .margin({ bottom: 10 })
        .alignItems(VerticalAlign.Top)

        Row() {
          Text("作者")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width(65)
            .margin({ top: 5 })

          TextInput({
            text: searchPodcast.artistName
          })
            .width("100%")
            .layoutWeight(1)
            .height(45)
            .borderRadius(8)
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({
              size: 18
            })
            .type(InputType.Normal)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value) => {
              searchPodcast.artistName = value
            })
        }
        .width('100%')
        .margin({ bottom: 10 })
        .alignItems(VerticalAlign.Top)

        Row() {
          Text("源URL")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width(65)
            .margin({ top: 5 })

          TextInput({
            text: searchPodcast.feedUrl
          })
            .width("100%")
            .layoutWeight(1)
            .height(45)
            .borderRadius(8)
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({
              size: 18
            })
            .type(InputType.Normal)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value) => {
              searchPodcast.feedUrl = value
            })
        }
        .width('100%')
        .margin({ bottom: 10 })
        .alignItems(VerticalAlign.Top)

        Row() {
          Text("描述")
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width(65)
            .margin({ top: 5 })

          TextArea({
            text: podcast.metadata.description
          })
            .width("100%")
            .layoutWeight(1)
            .height(120)
            .borderRadius(8)
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({
              size: 18
            })
            .type(TextAreaType.NORMAL)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value) => {
              podcast.metadata.description = value
            })
        }
        .width('100%')
        .margin({ bottom: 15 })
        .alignItems(VerticalAlign.Top)

        Row() {
          Row() {
            Radio({ value: 'autoDownload', group: 'autoDownload', indicatorType: RadioIndicatorType.TICK })
              .width(20)
              .checked(this.autoDownload[index])
              .radioStyle({
                checkedBackgroundColor: $r('sys.color.comp_emphasize_secondary'),
                indicatorColor: $r('app.color.start_window_background')
              })
              .onClick(() => {
                this.autoDownload[index] = !this.autoDownload[index]
              })

            Text("自动下载剧集")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 5 })
          }

          Button({ type: ButtonType.Normal }) {
            Text("提交")
              .fontSize(18)
          }
          .backgroundColor($r('sys.color.comp_emphasize_secondary'))
          .height(40)
          .width(100)
          .borderRadius(8)
          .onClick(async () => {
            let podcast1 = await addPodcast(this.library!.id, this.library!.folders[0].id, this.library!.folders[0].fullPath + "/" + searchPodcast.title, searchPodcast, podcast, this.autoDownload[index])
            if (podcast1) {
              this.showConfirm[index] = false
              this.getUIContext().getPromptAction().showToast({
                message: '添加成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '添加播客失败，请检查网络！',
                duration: 500
              });
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, bottom: 25 })
    .scrollBar(BarState.Off)
  }

  build() {
    Stack() {
      Scroll(this.addScroller) {
        Column() {
          if (this.searchPodcasts.length > 0) {
            ForEach(this.searchPodcasts, (searchPodcast: SearchPodcast, index) => {
              Column() {
                Row() {
                  Image(searchPodcast.cover)
                    .alt($rawfile('nocover.jpg'))
                    .objectFit(ImageFit.Cover)
                    .width(70)
                    .aspectRatio(1)
                    .borderRadius(8)
                    .margin({ right: 10 })
                    .draggable(false)

                  Column() {
                    Text(searchPodcast.title)
                      .fontSize(17)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ bottom: 3 })

                    Text("by " + searchPodcast.artistName)
                      .fontSize(15)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ bottom: 5 })

                    Text(searchPodcast.trackCount + " 剧集")
                      .fontSize(13)
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')

                Divider()
                  .width('100%')
                  .strokeWidth(1)
                  .margin({ top: 15 })
              }
              .width('100%')
              .margin({ bottom: index === this.searchPodcasts.length - 1 ? (this.isStartPlaying ? 109 : 25) : 15 })
              .onClick(async () => {
                let podcast1 = await getFeed(searchPodcast.feedUrl)
                if (podcast1) {
                  this.podcast = podcast1
                  this.autoDownload[index] = false
                  this.showConfirm[index] = true
                } else {
                  this.getUIContext().getPromptAction().showToast({
                    message: '获取播客失败，请检查网络！',
                    duration: 500
                  });
                }
              })
              .bindSheet(this.showConfirm[index], this.confirmBuilder(searchPodcast, this.podcast!, index), {
                height: 429,
                preferType: SheetType.CENTER,
                title: {
                  title: "确认添加"
                },
                showClose: false,
                onDisappear: () => {
                  this.showConfirm[index] = false
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
            .padding({ bottom: 210 })
            .justifyContent(FlexAlign.Center)
            .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
          }
        }
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .padding({ top: 36 + 80, bottom: this.isStartPlaying ? 84 : 0 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Search({ value: this.term })
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
            this.showConfirm = []
            this.autoDownload = []
            for(let item of this.searchPodcasts) {
              this.showConfirm.push(false)
              this.autoDownload.push(false)
            }
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