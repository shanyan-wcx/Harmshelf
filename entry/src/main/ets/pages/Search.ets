import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, uiMaterial } from '@kit.ArkUI';
import { Author, Library, LibraryItem, LibraryItemSearchResult, SearchResult, Series } from '../utils/Interface';
import { searchLibrary } from '../utils/Api';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ImmersiveActionButton, transparentTitleBarStyle } from '../utils/Component';
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
              ForEach(this.searchResult.book, (libraryItemSearchResult: LibraryItemSearchResult, index) => {
                ListItem() {
                  Row() {
                    ImmersiveActionButton({
                      barWidth: '100%',
                      barHeight: 64,
                      barRadius: 8,
                      onButtonClick: () => {
                        this.libraryItem = libraryItemSearchResult.libraryItem
                        this.pageInfos.pushPathByName('libraryItemDetail', null)
                      }
                    }) {
                      Row() {
                        Image(this.baseUrl +
                          `/api/items/${libraryItemSearchResult.libraryItem.id}/cover?token=${this.apiToken}`)
                          .alt($rawfile('nocover.jpg'))
                          .objectFit(ImageFit.Cover)
                          .width(64)
                          .aspectRatio(1)
                          .borderRadius(8)
                          .margin({ right: 10 })
                          .draggable(false)

                        Column() {
                          Text(libraryItemSearchResult.libraryItem.media.metadata.title)
                            .fontSize(19)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ bottom: 5 })

                          Text((libraryItemSearchResult.libraryItem.media.metadata.authorName ?? "-"))
                            .fontSize(16)
                            .fontColor($r('sys.color.font_secondary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .alignItems(HorizontalAlign.Start)
                      }
                      .width('100%')
                      .height('100%')
                      .alignItems(VerticalAlign.Center)
                      .clip(false)
                    }
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20 })
                  .margin({ top: index === 0 ? 66 + this.statusBarHeight : 10, bottom: index === this.searchResult!.book!.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 99, false) : 10 })
                  .clip(false)
                }
              })
            }
          } else if (this.library?.mediaType === 'podcast') {
            if (this.searchResult && this.searchResult.podcast!.length > 0) {
              ForEach(this.searchResult.podcast, (libraryItemSearchResult: LibraryItemSearchResult, index) => {
                ListItem() {
                  Row() {
                    ImmersiveActionButton({
                      barWidth: '100%',
                      barHeight: 64,
                      barRadius: 8,
                      onButtonClick: () => {
                        this.libraryItem = libraryItemSearchResult.libraryItem
                        this.pageInfos.pushPathByName('libraryItemDetail', null)
                      }
                    }) {
                      Row() {
                        Image(this.baseUrl +
                          `/api/items/${libraryItemSearchResult.libraryItem.id}/cover?token=${this.apiToken}`)
                          .alt($rawfile('nocover.jpg'))
                          .objectFit(ImageFit.Cover)
                          .width(64)
                          .aspectRatio(1)
                          .borderRadius(8)
                          .margin({ right: 10 })
                          .draggable(false)

                        Column() {
                          Text(libraryItemSearchResult.libraryItem.media.metadata.title)
                            .fontSize(19)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ bottom: 5 })

                          Text((libraryItemSearchResult.libraryItem.media.metadata.author ?? "-"))
                            .fontSize(16)
                            .fontColor($r('sys.color.font_secondary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .alignItems(HorizontalAlign.Start)
                      }
                      .width('100%')
                      .height('100%')
                      .alignItems(VerticalAlign.Center)
                      .clip(false)
                    }
                  }
                  .width('100%')
                  .padding({ left: 20, right: 20 })
                  .margin({ top: index === 0 ? 66 + this.statusBarHeight : 10, bottom: index === this.searchResult!.podcast!.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 99, false) : 10 })
                  .clip(false)
                }
              })
            }
          }
        }
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        if (!this.searchResult || Object.values(this.searchResult)
          .every((arr: LibraryItemSearchResult[] | string[] | Author[] | Series[]) => (arr?.length ?? 0) === 0)) {
          Column() {
            Text("没有结果")
              .fontSize(32)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
        }

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
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      style: transparentTitleBarStyle(),
      content: {
        stackBuilder: (): void => this.titleBarBuilder()
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.searchScroller])
  }
}
