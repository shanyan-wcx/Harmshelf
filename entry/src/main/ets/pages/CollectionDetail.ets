import { Book, Collection } from '../utils/Interface';
import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, PersistenceV2 } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { env } from '../utils/Class';
import { ColorMode } from "../pages/Index";

@Builder
export function collectionDetailBuilder(name: string, param: Object) {
  CollectionDetail()
}

@ComponentV2
export struct CollectionDetail {
  private PlaylistDetailScroller: Scroller = new Scroller();
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() collection1: Collection | undefined = undefined
  @Consumer() statusBarHeight: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local showLoadingProgress: boolean = false
  @Local imageWidth: Length = 0
  @Local showPlayLoading: boolean = false

  get totalDuration(): string {
    if (!this.collection1) {
      return '0s'
    }
    let totalSec = 0
    const books = this.collection1.books ?? [] // <--- safe default
    totalSec = books.map(item => item?.media?.duration ?? 0).reduce((a, b) => a + b, 0)
    const days = Math.floor(totalSec / 86400)
    const hours = Math.floor((totalSec % 86400) / 3600)
    const minutes = Math.floor((totalSec % 3600) / 60)
    const seconds = Math.round(totalSec % 60)
    if (days > 0) {
      return `${days}d ${hours}h ${minutes}m ${seconds}s`
    } else if (hours >
      0) {
      return `${hours}h ${minutes}m ${seconds}s`
    } else if (minutes >
      0) {
      return `${minutes}m ${seconds}s`
    } else {
      return `${seconds}s`
    }
  }

  private getPosition(collection: Collection, index: number): number {
    const gap = Number(this.imageWidth) / (collection.books.length - 1) / 2;
    if (collection.books.length == 1) {
      return Number(this.imageWidth) / 2
    } else {
      return (collection.books.length - 1 - index) * gap
    }
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Scroll(this.PlaylistDetailScroller) {
          Column() {
            Stack({ alignContent: Alignment.Bottom }) {
              if (this.collection1!.books.length === 1) {
                Column() {
                  Image(this.baseUrl + `/api/items/${this.collection1!.books[0].id}/cover?token=${this.apiToken}`)
                    .alt($rawfile('nocover.jpg'))
                    .objectFit(ImageFit.Cover)
                    .height('100%')
                    .aspectRatio(1)
                    .clip(true)
                    .objectFit(ImageFit.Fill)
                }
                .width('100%')
                .height('100%')
                .backgroundImage(this.baseUrl + `/api/items/${this.collection1!.books[0].id}/cover?token=${this.apiToken}`)
                .backgroundImageSize(ImageSize.FILL)
                .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
              } else {
                ForEach(this.collection1!.books.slice().reverse(), (book: Book, index) => {
                  Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                    .alt($rawfile('nocover.jpg'))
                    .objectFit(ImageFit.Cover)
                    .height('100%')
                    .aspectRatio(1)
                    .clip(true)
                    .objectFit(ImageFit.Fill)
                    .position({ x: this.getPosition(this.collection1, index) })
                    .shadow({
                      offsetX: 10,
                      offsetY: 0,
                      radius: 10,
                      color: $r('sys.color.ohos_id_shadow_default_lg_dark')
                    })
                })
              }
            }
            .height(160)
            .aspectRatio(2)
            .borderRadius(10)
            .clip(true)
            .onAreaChange((oldArea, newArea) => {
              this.imageWidth = newArea.width
            })

            Column() {
              Row() {
                Column() {
                  Text("收藏项目 " + this.collection1!.books.length)
                    .fontSize(18)
                    .margin({ bottom: 5 })

                  Text(this.totalDuration)
                    .fontSize(17)
                    .fontColor($r('sys.color.font_secondary'))
                }
                .width('100%')
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button({ type: ButtonType.Normal }) {
                  if (this.showPlayLoading) {
                    Column() {
                      LoadingProgress()
                        .width(30)
                        .height(30)
                        .color($r('sys.color.ohos_id_color_titlebar_icon'))
                    }
                  } else {
                    Row() {
                      SymbolGlyph($r('sys.symbol.play_fill'))
                        .fontWeight(FontWeight.Normal)
                        .fontSize(18)
                        .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                        .hitTestBehavior(HitTestMode.None)
                        .margin({ bottom: 1 })

                      Text(" 播放")
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                }
                .backgroundColor($r('sys.color.comp_emphasize_secondary'))
                .height(40)
                .width(100)
                .borderRadius(8)
                .onClick(async () => {
                  this.showPlayLoading = true

                  this.showPlayLoading = false
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })

              ForEach(this.collection1!.books, (book: Book, index) => {
                Row() {

                }
                .width('100%')
                .height(80)
                .backgroundColor($r('sys.color.background_secondary'))
                .borderRadius(8)
                .margin({ top: index === 0 ? 0 : 5 })
              })
            }
            .width('100%')
            .margin({ top: 20 })
            .padding({ left: 10, right: 10, bottom: 10 })
            .borderRadius(8)
            .clip(true)
            .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
              env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
              this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
              $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .padding({
          top: 56 + this.statusBarHeight,
          left: 20,
          right: 20,
          bottom: this.isStartPlaying ? 89 : 10
        })
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(72)
            .color($r('sys.color.loading_progress_focused_color'))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .visibility(this.showLoadingProgress === true ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.End)
    }
    .width('100%')
    .height('100%')
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      content: {
        title: {
          mainTitle: this.collection1!.name
        }
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          blurEffectiveStartOffset: LengthMetrics.vp(10)
        }
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.PlaylistDetailScroller])
  }
}