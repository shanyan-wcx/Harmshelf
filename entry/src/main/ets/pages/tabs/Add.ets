import { addPodcast, getFeed } from "../../utils/Api"
import { Library, Podcast, SearchPodcast } from "../../utils/Interface"
import { getBottomContentInset } from '../../utils/Layout';
import { ImmersiveActionButton } from '../../utils/Component';
import { uiMaterial } from '@kit.ArkUI';

@ComponentV2
export struct Add {
  @Consumer() addScroller: Scroller = new Scroller()
  @Consumer() displayWidth: number = 0
  @Consumer() library: Library | undefined = undefined
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() searchPodcasts: SearchPodcast[] = []
  @Consumer() statusBarHeight: number = 0
  @Local showConfirm: boolean[] = []
  @Local podcast: Podcast | undefined = undefined
  @Local autoDownload: boolean[] = []

  @Monitor('searchPodcasts')
  resetSearchState() {
    this.showConfirm = []
    this.autoDownload = []
    for (let index = 0; index < this.searchPodcasts.length; index++) {
      this.showConfirm.push(false)
      this.autoDownload.push(false)
    }
  }

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
            .borderRadius(10)
            .border({
              width: 0.35,
              radius: 10,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
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
            .borderRadius(10)
            .border({
              width: 0.35,
              radius: 10,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
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
            .borderRadius(10)
            .border({
              width: 0.35,
              radius: 10,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
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
            .borderRadius(10)
            .border({
              width: 0.35,
              radius: 10,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({
              size: 18
            })
            .type(TextAreaType.NORMAL)
            .enterKeyType(EnterKeyType.Done)
            .barState(BarState.Off)
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

          Row() {
            ImmersiveActionButton({
              barWidth: 160,
              barHeight: 50,
              onButtonClick: async () => {
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
              }
            }) {
              Text("提交")
                .fontSize(18)
                .hitTestBehavior(HitTestMode.None)
            }
          }
          .height(50)
          .width(160)
          .clip(false)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding({ left: 20, right: 20, top: 8, bottom: 15 })
    }
    .width('100%')
    .scrollBar(BarState.Off)
  }

  build() {
    Stack() {
      List({ scroller: this.addScroller }) {
        Repeat<SearchPodcast>(this.searchPodcasts)
          .each((repeatItem: RepeatItem<SearchPodcast>) => {
            ListItem() {
              Row() {
                Image(repeatItem.item.cover)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width(64)
                  .aspectRatio(1)
                  .borderRadius(10)
                  .margin({ right: 10 })
                  .draggable(false)

                Column() {
                  Text(repeatItem.item.title)
                    .fontSize(16)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 3 })

                  Text("by " + repeatItem.item.artistName)
                    .fontSize(13)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 5 })

                  Text(repeatItem.item.trackCount + " 剧集")
                    .fontSize(13)
                    .fontColor($r('sys.color.font_secondary'))
                }
                .width('100%')
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height(80)
              .padding({ left: 8, right: 8 })
              .alignItems(VerticalAlign.Center)
              .borderRadius(18)
              .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .border({
                width: 0.35,
                radius: 18,
                color: $r('sys.color.ohos_id_color_focused_outline_transparent')
              })
              .shadow(ShadowStyle.OUTER_DEFAULT_XS)
              .onClick(async () => {
                let podcast1 = await getFeed(repeatItem.item.feedUrl)
                if (podcast1) {
                  this.podcast = podcast1
                  this.autoDownload[repeatItem.index] = false
                  this.showConfirm[repeatItem.index] = true
                } else {
                  this.getUIContext().getPromptAction().showToast({
                    message: '获取播客失败，请检查网络！',
                    duration: 500
                  });
                }
              })
              .clip(false)
              .bindSheet(this.showConfirm[repeatItem.index], this.confirmBuilder(repeatItem.item, this.podcast!, repeatItem.index), {
                systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                height: SheetSize.FIT_CONTENT,
                preferType: SheetType.CENTER,
                title: {
                  title: "确认添加"
                },
                showClose: false,
                onDisappear: () => {
                  this.showConfirm[repeatItem.index] = false
                }
              })
            }
            .width('100%')
            .margin({
              top: repeatItem.index === 0 ? this.statusBarHeight + 56 + 36 + 75 : 0,
              bottom: repeatItem.index === this.searchPodcasts.length - 1 ?
                getBottomContentInset(25, this.isStartPlaying, 109) : 16
            })
            .clip(false)
          })
          .virtualScroll({ totalCount: this.searchPodcasts.length })
          .key((item: SearchPodcast) => item.feedUrl)
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .padding({ left: 4, right: 4, bottom: 0 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .cachedCount(2)
      .align(Alignment.Top)
      .clip(false)
      .clipContent(ContentClipMode.BOUNDARY)

      if (this.searchPodcasts.length === 0) {
        Column() {
          Text("没有结果")
            .fontSize(24)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 210 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
      }

    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .alignContent(Alignment.Top)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .clip(false)
  }
}
