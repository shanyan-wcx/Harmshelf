import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, uiMaterial } from '@kit.ArkUI';
import { Author, Library, LibraryItem, LibraryItemSearchResult, SearchResult, Series } from '../utils/Interface';
import { searchLibrary } from '../utils/Api';
import { deviceInfo } from '@kit.BasicServicesKit';
import { gradientBlurTitleBarStyle } from '../utils/Component';
import { getBottomContentInset } from '../utils/Layout';

let deviceTypeInfo: string = deviceInfo.deviceType;

@Builder
export function searchBuilder(name: string, param: Object) {
  SearchMedia()
}

@ComponentV2
export struct SearchMedia {
  private searchScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() statusBarHeight: number = 0
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() searchResult: SearchResult | undefined = undefined
  @Consumer() showSearch: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() isStartPlaying: boolean = false
  @Local showLoadingProgress: boolean = false

  aboutToAppear() {
    this.searchResult = undefined
  }

  @Builder
  titleBarBuilder() {
    Row() {
      Row() {
        Search()
          .width('100%')
          .height(40)
          .systemMaterial(new uiMaterial.ImmersiveMaterial({
            style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
            applyShadow: true,
            interactive: true,
            lightEffect: { color: Color.White }
          }))
          .caretStyle({
            color: $r('sys.color.font')
          })
          .searchButton("   搜索   ", {
            fontColor: $r('sys.color.font'),
            autoDisable: true
          })
          .onSubmit(async (query) => {
            if (query.length !== 0) {
              this.showLoadingProgress = true
              this.searchResult = await searchLibrary(this.library!.id, encodeURIComponent(query))
              if (this.searchResult) {
                this.searchResult.tags = undefined
                this.searchResult.genres = undefined
                this.searchResult.narrators = undefined
                this.searchResult.episodes = undefined
              }
              this.searchScroller.scrollEdge(Edge.Top)
              this.showLoadingProgress = false
            }
          })
      }
      .width(deviceTypeInfo === '2in1' ? this.sideBarContentWidth - 214 : this.sideBarContentWidth - 56)
      .padding({ left: 16, right: 16 })
      .margin({ left: 56 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  build() {
    HdsNavDestination() {
      Stack() {
        List({ scroller: this.searchScroller }) {
          if (this.library?.mediaType === 'book') {
            if (this.searchResult && this.searchResult.book!.length > 0) {
              Repeat<LibraryItemSearchResult>(this.searchResult.book)
                .each((repeatItem: RepeatItem<LibraryItemSearchResult>) => {
                ListItem() {
                  Row() {
                    Image(this.baseUrl +
                      `/api/items/${repeatItem.item.libraryItem.id}/cover?token=${this.apiToken}`)
                      .alt($rawfile('nocover.jpg'))
                      .objectFit(ImageFit.Cover)
                      .width(64)
                      .aspectRatio(1)
                      .borderRadius(10)
                      .margin({ right: 10 })
                      .draggable(false)

                    Column() {
                      Text(repeatItem.item.libraryItem.media.metadata.title)
                        .fontSize(16)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ bottom: 3 })

                      Text((repeatItem.item.libraryItem.media.metadata.authorName ?? "-"))
                        .fontSize(13)
                        .fontColor($r('sys.color.font_secondary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ bottom: 5 })

                      Text((repeatItem.item.libraryItem.media.chapters?.length ?? 0) + " 章节")
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
                  .onClick(() => {
                    this.libraryItem = repeatItem.item.libraryItem
                    this.pageInfos.pushPathByName('libraryItemDetail', null)
                  })
                  .clip(false)
                }
                  .width('100%')
                  .padding({ left: 20, right: 20 })
                  .margin({ top: repeatItem.index === 0 ? 66 + this.statusBarHeight : 8, bottom: repeatItem.index === this.searchResult!.book!.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 99, false) : 8 })
                  .clip(false)
                })
                .virtualScroll({ totalCount: this.searchResult.book!.length })
                .key((item: LibraryItemSearchResult) => item.libraryItem.id)
            }
          } else if (this.library?.mediaType === 'podcast') {
            if (this.searchResult && this.searchResult.podcast!.length > 0) {
              Repeat<LibraryItemSearchResult>(this.searchResult.podcast)
                .each((repeatItem: RepeatItem<LibraryItemSearchResult>) => {
                ListItem() {
                  Row() {
                    Image(this.baseUrl +
                      `/api/items/${repeatItem.item.libraryItem.id}/cover?token=${this.apiToken}`)
                      .alt($rawfile('nocover.jpg'))
                      .objectFit(ImageFit.Cover)
                      .width(64)
                      .aspectRatio(1)
                      .borderRadius(10)
                      .margin({ right: 10 })
                      .draggable(false)

                    Column() {
                      Text(repeatItem.item.libraryItem.media.metadata.title)
                        .fontSize(16)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ bottom: 3 })

                      Text((repeatItem.item.libraryItem.media.metadata.author ?? "-"))
                        .fontSize(13)
                        .fontColor($r('sys.color.font_secondary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ bottom: 5 })

                      Text((repeatItem.item.libraryItem.media.episodes?.length ?? 0) + " 剧集")
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
                  .onClick(() => {
                    this.libraryItem = repeatItem.item.libraryItem
                    this.pageInfos.pushPathByName('libraryItemDetail', null)
                  })
                  .clip(false)
                }
                  .width('100%')
                  .padding({ left: 20, right: 20 })
                  .margin({ top: repeatItem.index === 0 ? 66 + this.statusBarHeight : 8, bottom: repeatItem.index === this.searchResult!.podcast!.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 99, false) : 8 })
                  .clip(false)
                })
                .virtualScroll({ totalCount: this.searchResult.podcast!.length })
                .key((item: LibraryItemSearchResult) => item.libraryItem.id)
            }
          }
        }
        .width('100%')
        .height('100%')
        .cachedCount(2)
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        if (!this.searchResult || Object.values(this.searchResult)
          .every((arr: LibraryItemSearchResult[] | string[] | Author[] | Series[]) => (arr?.length ?? 0) === 0)) {
          Column() {
            Text("没有结果")
              .fontSize(24)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
        }

        Column() {
          LoadingProgress()
            .width("100%")
            .height(45)
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
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      style: gradientBlurTitleBarStyle(),
      content: {
        stackBuilder: (): void => this.titleBarBuilder()
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.searchScroller])
  }
}
