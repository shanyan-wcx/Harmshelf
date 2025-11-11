import { Playlist, PlaylistItem } from '../utils/Interface';
import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, PersistenceV2 } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { env } from '../utils/Class';
import { ColorMode } from "../pages/Index";

@Builder
export function playlistDetailBuilder(name: string, param: Object) {
  PlaylistDetail()
}

@ComponentV2
export struct PlaylistDetail {
  private PlaylistDetailScroller: Scroller = new Scroller();
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() playlist1: Playlist | undefined = undefined
  @Consumer() statusBarHeight: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local showLoadingProgress: boolean = false
  @Local imageWidth: Length = 0
  @Local showPlayLoading: boolean = false

  get totalDuration(): string {
    if (!this.playlist1) {
      return '0s'
    }
    let totalSec = 0
    const items = this.playlist1.items ?? [] // <--- safe default
    totalSec = items.map(item => item?.libraryItem?.media?.duration ?? 0).reduce((a, b) => a + b, 0)
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

  get displayImages(): PlaylistItem[] {
    const len = this.playlist1!.items.length;
    if (len === 0) {
      return [];
    } else if (len === 1) {
      return [this.playlist1!.items[0], this.playlist1!.items[0], this.playlist1!.items[0], this.playlist1!.items[0]];
    } else if (len === 2) {
      return [this.playlist1!.items[0], this.playlist1!.items[1], this.playlist1!.items[1], this.playlist1!.items[0]];
    } else if (len === 3) {
      return [this.playlist1!.items[0], this.playlist1!.items[1], this.playlist1!.items[2], this.playlist1!.items[0]];
    } else {
      return this.playlist1!.items.slice(0, 4);
    }
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Scroll(this.PlaylistDetailScroller) {
          Column() {
            Column() {
              if ((this.playlist1!.items ?? []).length === 1) {
                Image(this.baseUrl +
                  `/api/items/${this.playlist1!.items[0].libraryItemId}/cover?token=${this.apiToken}`)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width('100%')
                  .aspectRatio(1)
                  .clip(true)
                  .objectFit(ImageFit.Fill)
              } else {
                ForEach([0, 1], (row: number) => {
                  Row() {
                    ForEach([0, 1], (col: number) => {
                      Image(this.baseUrl +
                        `/api/items/${this.displayImages[row * 2 + col].libraryItemId}/cover?token=${this.apiToken}`)
                        .alt($rawfile('nocover.jpg'))
                        .objectFit(ImageFit.Cover)
                        .width('50%')
                        .aspectRatio(1)
                        .clip(true)
                        .objectFit(ImageFit.Fill)
                    })
                  }
                })
              }
            }
            .height(160)
            .aspectRatio(1)
            .borderRadius(10)
            .clip(true)

            Column() {
              Row() {
                Column() {
                  Text("播放列表项目 " + this.playlist1!.items.length)
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

              ForEach(this.playlist1!.items, (item: Playlist, index) => {
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
          mainTitle: this.playlist1!.name
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