import { LengthMetrics, RectShape } from "@kit.ArkUI"
import { deviceInfo } from "@kit.BasicServicesKit";
import {
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsNavigationAttribute,
  HdsNavigationMenuItemOptions,
} from "@kit.UIDesignKit"
import { Home } from "../pages/Home";
import { LocalMedia } from "../pages/Local";
import { Log } from "../pages/Log";
import { Setting } from "../pages/Setting";
import { Stats } from "../pages/Stat";
import { getItem, getPlayItem, getUser, updateProgress } from "./Api";
import { Author, Series, LibraryItem, Library, Book, Progress, Episode, Filter1, UpdateProgress, PlayItem, Collection, Playlist,
  PlaylistItem} from "./Interface"
import { media } from "@kit.MediaKit";

let deviceTypeInfo: string = deviceInfo.deviceType;

@ComponentV2
export struct MyNavigation {
  @Consumer() statsScroller: Scroller = new Scroller();
  @Provider() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() displayWidth: number = 0
  @Consumer() sideBarWidth: number = 240
  @Consumer() statusBarHeight: number = 0
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() pageIndex: number = 0;
  @Consumer() firstAppear: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() selectOptions: SelectOption[] = []
  @Consumer() selectLibraryIndex: number = 0
  @Consumer() topTabIndex: number = 0
  @Consumer() needUpdate: boolean = false
  @Consumer() isConnect: boolean = true
  @Consumer() isShowSidebar: boolean = false
  @Consumer() sidebarType: number = SideBarContainerType.Overlay
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() libraries: Library[] = []
  @Consumer() library: Library | undefined = undefined

  aboutToAppear() {
    this.firstAppear = true
  }

  @Builder
  titleBarBuilder() {
    Row() {
      Row() {
        Select(this.selectOptions)
          .selected(this.selectLibraryIndex)
          .value(this.library?.name)
          .font({
            weight: FontWeight.Medium
          })
          .menuBackgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
          .selectedOptionFontColor($r('sys.color.select_font_color'))
          .onSelect((index: number, text?: string | undefined) => {
            if (this.selectLibraryIndex !== index) {
              this.selectLibraryIndex = index
              this.library = this.libraries[index]
              this.topTabIndex = 0
              this.needUpdate = !this.needUpdate
            }
          })
          .borderRadius(8)
          .flexShrink(1)

        SymbolGlyph(this.isConnect ? $r('sys.symbol.checkmark_icloud_fill') : $r('sys.symbol.icloud_slash_fill'))
          .margin({ left: 16 })
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor([this.isConnect ? Color.Green : Color.Orange])
      }
      .clip(true)
      .width(deviceTypeInfo === '2in1' ? this.sideBarContentWidth - 180 : this.sideBarContentWidth - 104)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  build() {
    HdsNavigation(this.pageInfos) {
      Column() {
        if (this.pageIndex === 0) {
          Home()
        } else if (this.pageIndex === 1) {
          Stats()
        } else if (this.pageIndex === 2) {
          LocalMedia()
        } else if (this.pageIndex === 3) {
          Log()
        } else if (this.pageIndex === 4) {
          Setting()
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.statusBarHeight })
    }
    .width(this.sidebarType === SideBarContainerType.Overlay ? '100%' : this.displayWidth - this.sideBarWidth)
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .mode(NavigationMode.Stack)
    .titleBar({
      avoidLayoutSafeArea:true,
      enableComponentSafeArea: false,
      padding: {
        end: deviceTypeInfo === '2in1' ? LengthMetrics.vp(168)  : LengthMetrics.vp(16)
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: this.pageIndex === 0 ? false : true,
          blurEffectiveStartOffset: LengthMetrics.vp(20)
        }
      },
      content: {
        stackBuilder: (): void => this.titleBarBuilder(),
        menu: {
          value: this.sidebarType === SideBarContainerType.Embed ?
            [{
              content: {
                icon: $r('sys.symbol.magnifyingglass'),
                label: 'search',
                action: () => {
                  this.pageInfos.pushPathByName('search', null)
                }
              }
            }] :
            [{
              content: {
                icon: $r('sys.symbol.magnifyingglass'),
                label: 'search',
                action: () => {
                  this.pageInfos.pushPathByName('search', null)
                }
              }
            },
            {
              content: {
                icon: $r('sys.symbol.open_sidebar'),
                label: 'sidebar',
                action: () => {
                  this.isShowSidebar = !this.isShowSidebar
                }
              }
            }]
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MINI)
    .hideBackButton(true)
    .bindToScrollable([this.statsScroller, this.LocalMediaScroller])
    .onSizeChange((oldValue, newValue) => {
      if (newValue.width) {
        this.sideBarContentWidth = Number(newValue.width)
      }
    })
  }
}

@ComponentV2
export struct LibraryItemComponent {
  @Require @Param item: LibraryItem
  @Require @Param progress: Progress | undefined
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Local imageWidth: Length = 0

  build() {
    Column() {
      Button({ type: ButtonType.Normal }) {
        Stack() {
          Image(this.baseUrl + `/api/items/${this.item.id}/cover?token=${this.apiToken}`)
            .alt($rawfile('nocover.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .draggable(false)
            .onAreaChange((oldArea, newArea) => {
              this.imageWidth = newArea.width
            })

          if (this.library?.mediaType === 'book') {
            Progress({ value: (this.progress?.progress ?? 0) * 100, total: 100, type: ProgressType.Linear })
              .width('100%')
              .color(this.progress?.progress === 1 ? $r('sys.color.ohos_id_color_palette4') :
                $r('sys.color.multi_color_11'))
              .backgroundColor(Color.Transparent)
              .style({
                strokeWidth: 10,
                strokeRadius: 10
              })
              .offset({
                y: 0.5
              })
              .clipShape(new RectShape({
                width: '100%',
                height: '5'
              }).position({
                y: 5
              }))
          }
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Bottom)
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .clip(true)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.libraryItem = this.item
        this.pageInfos.pushPathByName('libraryItemDetail', null)
      })

      Column() {
        Text(this.item.media.metadata.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 5 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.library?.mediaType === 'book' ? (this.item.media.metadata.authorName ?? "-") :
          (this.item.media.metadata.author ?? "-"))
          .fontSize(15)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.imageWidth)
      .alignItems(HorizontalAlign.Start)
    }
    .width('auto')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct LibraryItemComponent1 {
  @Require @Param item: LibraryItem
  @Require @Param progress: Progress | undefined
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Local imageWidth: Length = 0

  build() {
    Column() {
      Button({ type: ButtonType.Normal }) {
        Stack() {
          Image(this.baseUrl + `/api/items/${this.item.id}/cover?token=${this.apiToken}`)
            .alt($rawfile('nocover.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .draggable(false)
            .onAreaChange((oldArea, newArea) => {
              this.imageWidth = newArea.width
            })

          if (this.library?.mediaType === 'book') {
            Progress({ value: (this.progress?.progress ?? 0) * 100, total: 100, type: ProgressType.Linear })
              .width('100%')
              .color(this.progress?.progress === 1 ? $r('sys.color.ohos_id_color_palette4') :
                $r('sys.color.multi_color_11'))
              .backgroundColor(Color.Transparent)
              .style({
                strokeWidth: 10,
                strokeRadius: 10
              })
              .offset({
                y: 0.5
              })
              .clipShape(new RectShape({
                width: '100%',
                height: '5'
              }).position({
                y: 5
              }))
          }
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Bottom)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .clip(true)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.libraryItem = this.item
        this.pageInfos.pushPathByName('libraryItemDetail', null)
      })

      Column() {
        Text(this.item.media.metadata.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 5 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.library?.mediaType === 'book' ? (this.item.media.metadata.authorName ?? "-") :
          (this.item.media.metadata.author ?? "-"))
          .fontSize(15)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.imageWidth)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('auto')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct SeriesItemComponent {
  @Require @Param series: Series
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() series1: Series | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local imageWidth: Length = 0
  @Local seriesWidth: Length = 0

  private getPosition(series: Series, index: number): number {
    const gap = Number(this.imageWidth) / (series.books.length - 1) / 2;
    if (series.books.length == 1) {
      return Number(this.imageWidth) / 2
    } else {
      return (series.books.length - 1 - index) * gap
    }
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Stack({ alignContent: Alignment.Bottom }) {
          if (this.series.books.length === 1) {
            Column() {
              Image(this.baseUrl + `/api/items/${this.series.books[0].id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
            }
            .width('100%')
            .height('100%')
            .backgroundImage(this.baseUrl + `/api/items/${this.series.books[0].id}/cover?token=${this.apiToken}`)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
          } else {
            ForEach(this.series.books.slice().reverse(), (book: Book, index) => {
              Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
                .position({ x: this.getPosition(this.series, index) })
                .shadow({
                  offsetX: 10,
                  offsetY: 0,
                  radius: 10,
                  color: $r('sys.color.ohos_id_shadow_default_lg_dark')
                })
            })
          }
        }
        .width('100%')
        .height('100%')
        .borderRadius(10)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .clip(true)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(2)
      .backgroundColor(Color.Transparent)
      .onAreaChange((oldArea, newArea) => {
        this.imageWidth = newArea.width
      })
      .onClick(() => {
        let filter: Filter1 = {
          criteria: this.series.name,
          type: "series"
        }
        this.series1 = this.series
        this.pageInfos.pushPathByName('filterItems', filter)
      })

      Column() {
        Text(this.series.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.seriesWidth)
      .padding(4)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    }
    .borderRadius(10)
    .clip(true)
    .width('100%')
    .height('auto')
    .alignContent(Alignment.Bottom)
    .onAreaChange((oldArea, newArea) => {
      this.seriesWidth = newArea.width
    })
  }
}

@ComponentV2
export struct CollectionItemComponent {
  @Require @Param collection: Collection
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() collection1: Collection | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local imageWidth: Length = 0
  @Local collectionWidth: Length = 0

  private getPosition(collection: Collection, index: number): number {
    const gap = Number(this.imageWidth) / (collection.books.length - 1) / 2;
    if (collection.books.length == 1) {
      return Number(this.imageWidth) / 2
    } else {
      return (collection.books.length - 1 - index) * gap
    }
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Stack({ alignContent: Alignment.Bottom }) {
          if (this.collection.books.length === 1) {
            Column() {
              Image(this.baseUrl + `/api/items/${this.collection.books[0].id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
            }
            .width('100%')
            .height('100%')
            .backgroundImage(this.baseUrl + `/api/items/${this.collection.books[0].id}/cover?token=${this.apiToken}`)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
          } else {
            ForEach(this.collection.books.slice().reverse(), (book: Book, index) => {
              Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
                .position({ x: this.getPosition(this.collection, index) })
                .shadow({
                  offsetX: 10,
                  offsetY: 0,
                  radius: 10,
                  color: $r('sys.color.ohos_id_shadow_default_lg_dark')
                })
            })
          }
        }
        .width('100%')
        .height('100%')
        .borderRadius(10)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .clip(true)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(2)
      .backgroundColor(Color.Transparent)
      .onAreaChange((oldArea, newArea) => {
        this.imageWidth = newArea.width
      })
      .onClick(() => {
        this.collection1 = this.collection
        this.pageInfos.pushPathByName('collectionDetail', null)
      })

      Column() {
        Text(this.collection.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.collectionWidth)
      .padding(4)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    }
    .borderRadius(10)
    .clip(true)
    .width('100%')
    .height('auto')
    .alignContent(Alignment.Bottom)
    .onAreaChange((oldArea, newArea) => {
      this.collectionWidth = newArea.width
    })
  }
}

@ComponentV2
export struct PlaylistItemComponent {
  @Require @Param playlist: Playlist
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() playlist1: Playlist | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local playlistWidth: Length = 0

  get displayImages(): PlaylistItem[] {
    const len = this.playlist.items.length;
    if (len === 0) {
      return [];
    } else if (len === 1) {
      return [this.playlist.items[0], this.playlist.items[0], this.playlist.items[0], this.playlist.items[0]];
    } else if (len === 2) {
      return [this.playlist.items[0], this.playlist.items[1], this.playlist.items[1], this.playlist.items[0]];
    } else if (len === 3) {
      return [this.playlist.items[0], this.playlist.items[1], this.playlist.items[2], this.playlist.items[0]];
    } else {
      return this.playlist.items.slice(0, 4);
    }
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Column() {
          if (this.playlist.items.length === 1) {
            Image(this.baseUrl + `/api/items/${this.playlist.items[0].libraryItemId}/cover?token=${this.apiToken}`)
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
                  Image(this.baseUrl + `/api/items/${this.displayImages[row * 2 + col].libraryItemId}/cover?token=${this.apiToken}`)
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
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(1)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.playlist1 = this.playlist
        this.pageInfos.pushPathByName('playlistDetail', null)
      })

      Column() {
        Text(this.playlist.name)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.playlistWidth)
      .padding(4)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    }
    .borderRadius(10)
    .clip(true)
    .width('100%')
    .height('auto')
    .alignContent(Alignment.Bottom)
    .onAreaChange((oldArea, newArea) => {
      this.playlistWidth = newArea.width
    })
  }
}

@ComponentV2
export struct AuthorComponent {
  @Require @Param author: Author
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local imageWidth: Length = 0

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Image(this.baseUrl + `/api/authors/${this.author.id}/image?token=${this.apiToken}`)
          .alt($rawfile('noprofile.jpg'))
          .objectFit(ImageFit.Cover)
          .width('100%')
          .height('100%')
          .draggable(false)
          .onAreaChange((oldArea, newArea) => {
            this.imageWidth = newArea.width
          })
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(0.85)
      .backgroundColor(Color.Transparent)

      Column() {
        Text(this.author.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.author.numBooks?.toString() + " 图书")
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.imageWidth)
      .padding(3)
      .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    }
    .borderRadius(10)
    .clip(true)
    .width('auto')
    .height('100%')
    .alignContent(Alignment.Bottom)
    .onClick(() => {
      let filter: Filter1 = {
        criteria: this.author.name,
        type: "author"
      }
      this.pageInfos.pushPathByName('filterItems', filter)
    })
  }
}

@ComponentV2
export struct AuthorComponent1 {
  @Require @Param author: Author
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local imageWidth: Length = 0

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Image(this.baseUrl + `/api/authors/${this.author.id}/image?token=${this.apiToken}`)
          .alt($rawfile('noprofile.jpg'))
          .objectFit(ImageFit.Cover)
          .width('100%')
          .height('100%')
          .draggable(false)
          .onAreaChange((oldArea, newArea) => {
            this.imageWidth = newArea.width
          })
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(0.85)
      .backgroundColor(Color.Transparent)

      Column() {
        Text(this.author.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.author.numBooks?.toString() + " 图书")
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.imageWidth)
      .padding(3)
      .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    }
    .borderRadius(10)
    .clip(true)
    .width('100%')
    .height('auto')
    .alignContent(Alignment.Bottom)
    .onClick(() => {
      let filter: Filter1 = {
        criteria: this.author.name,
        type: "author"
      }
      this.pageInfos.pushPathByName('filterItems', filter)
    })
  }
}

@ComponentV2
export struct RecentEpisodeComponent {
  @Require @Param item: LibraryItem
  @Require @Param progress: Progress | undefined
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local imageWidth: Length = 0

  build() {
    Column() {
      Button({ type: ButtonType.Normal }) {
        Stack() {
          Image(this.baseUrl + `/api/items/${this.item.id}/cover?token=${this.apiToken}`)
            .alt($rawfile('nocover.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .draggable(false)
            .onAreaChange((oldArea, newArea) => {
              this.imageWidth = newArea.width
            })

          Progress({ value: (this.progress?.progress ?? 0) * 100, total: 100, type: ProgressType.Linear })
            .width('100%')
            .color(this.progress?.progress === 1 ? $r('sys.color.ohos_id_color_palette4') :
              $r('sys.color.multi_color_11'))
            .backgroundColor(Color.Transparent)
            .style({
              strokeWidth: 10,
              strokeRadius: 10
            })
            .offset({
              y: 0.5
            })
            .clipShape(new RectShape({
              width: '100%',
              height: '5'
            }).position({
              y: 5
            }))

          Text("剧集")
            .fontSize(12)
            .padding({ left: 5, right: 5, top: 3, bottom: 2 })
            .borderRadius(5)
            .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
            .position({
              top: 5,
              right: 5
            })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Bottom)
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .clip(true)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.episode = this.item.recentEpisode
        this.pageInfos.pushPathByName('episodeDetail', null)
      })

      Column() {
        Text(this.item.recentEpisode?.title??"-")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 5 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.item.media.metadata.title)
          .fontSize(15)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(this.imageWidth)
      .alignItems(HorizontalAlign.Start)
    }
    .width('auto')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct EpisodeComponent {
  @Require @Param item: Episode
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() progress: Progress[] = []
  @Consumer() isPlaying: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() syncTime: number = 0
  @Consumer() isIndex: boolean = true
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.episodeId === this.item.id)
  @Local showPlayLoading: boolean = false
  @Monitor('syncTime')
  async refreshProgress(monitor: IMonitor) {
    this.itemProgress = undefined
    this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
  }

  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    let formattedTime = '';
    if (hours > 0) {
      formattedTime += `${hours} hr `;
    }
    formattedTime += `${minutes} min`;
    return formattedTime;
  }

  formatTime(timestamp: number): string {
    let date = new Date(timestamp)
    let year = date.getFullYear()
    let month = (date.getMonth() + 1).toString().padStart(2, '0')
    let day = date.getDate().toString().padStart(2, '0')
    let hours = date.getHours().toString().padStart(2, '0')
    let minutes = date.getMinutes().toString().padStart(2, '0')
    return `${year}/${month}/${day} ${hours}:${minutes}`
  }

  build() {
    Column() {
      Row() {
        Image(this.baseUrl + `/api/items/${this.item.libraryItemId}/cover?token=${this.apiToken}`)
          .alt($rawfile('nocover.jpg'))
          .objectFit(ImageFit.Cover)
          .height(45)
          .aspectRatio(1)
          .borderRadius(8)
          .margin({ right: 10 })
          .draggable(false)

        Column() {
          Text(this.item.podcast?.metadata.title ?? "-")
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 5 })
            .decoration({
              type: TextDecorationType.Underline
            })
            .onClick(async () => {
              this.libraryItem = await getItem(this.item.libraryItemId!)
              this.pageInfos.pushPathByName('libraryItemDetail', null)
            })

          Text(this.formatTime(this.item.publishedAt!))
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 10 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      Text(this.item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 5 })

      Text(this.item.description
      // 段落与换行
        .replace(/<p[^>]*>/gi, '')
        .replace(/<\/p>/gi, '\n')
        .replace(/<br\s*\/?>/gi, '')
        // 列表相关
        .replace(/<ul[^>]*>/gi, '')
        .replace(/<\/ul>/gi, '')
        .replace(/<ol[^>]*>/gi, '')
        .replace(/<\/ol>/gi, '')
        .replace(/<li[^>]*>/gi, '• ')
        .replace(/<\/li>/gi, '\n')
        // 链接：保留文字，去掉URL
        .replace(/<a[^>]*>(.*?)<\/a>/gi, '$1')
        // 忽略强调类标签
        .replace(/<\/?(b|strong|i|em|u)>/gi, '')
        // 去除其他残余HTML标签
        .replace(/<\/?[^>]+(>|$)/g, '')
        // HTML 实体
        .replace(/&nbsp;/gi, ' ')
        .replace(/&lt;/gi, '<')
        .replace(/&gt;/gi, '>')
        .replace(/&amp;/gi, '&')
        // 优化空行
        .replace(/\n{3,}/g, '\n')
        .trim())
        .fontSize(16)
        .width('100%')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Button({ type: ButtonType.Normal }) {
          Row() {
            if (this.showPlayLoading) {
              Column() {
                LoadingProgress()
                  .width(18)
                  .height(18)
                  .color($r('sys.color.ohos_id_color_titlebar_icon'))
              }
            } else {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontWeight(FontWeight.Normal)
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                .hitTestBehavior(HitTestMode.None)
                .margin({ bottom: 1 })
            }

            Text(this.formatDuration(this.item.duration))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 5 })
          }
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(38)
        .padding({ left: 10, right: 10 })
        .borderRadius(8)
        .onClick(async () => {
          this.showPlayLoading = true
          this.playingItem = await getPlayItem(this.item.libraryItemId!, this.item.id)
          if (this.playingItem) {
            await this.avPlayer!.reset();
            this.isStartPlaying = true
            this.isPlaying = true
            this.playingIndex = 0
            this.playingTitle = this.playingItem!.displayTitle.trim()
            this.playStartTime = this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
            console.log("共", this.playingItem!.audioTracks.length, "条音轨")
            console.log("播放序号为", this.playingIndex)
            console.log("起始位置为", this.playStartTime)
          }
          this.showPlayLoading = false
        })

        Button({ type: ButtonType.Normal }) {
          SymbolGlyph(this.itemProgress?.isFinished ? $r('sys.symbol.checkmark_square_fill') : $r('sys.symbol.checkmark_square'))
            .fontSize(20)
            .fontColor([$r('sys.color.font')])
        }
        .backgroundColor(Color.Transparent)
        .width(38)
        .height(38)
        .borderRadius(8)
        .margin({ left: 5 })
        .onClick(async () => {
          if (this.itemProgress?.isFinished) {
            let tmpProgress: UpdateProgress = {
              duration: this.item.duration,
              currentTime: 0,
              progress: 0,
              isFinished: false
            }
            let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
            }
          } else {
            let tmpProgress: UpdateProgress = {
              duration: this.item.duration,
              currentTime: this.item.duration,
              progress: 1,
              isFinished: true
            }
            let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
            }
          }
        })
      }
      .padding({
        top: 15, bottom: 20
      })

      Divider()
        .strokeWidth(1)
    }
    .margin({ top: 20 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.episode = this.item
      this.pageInfos.pushPathByName('episodeDetail', null)
    })
  }
}

@ComponentV2
export struct EpisodeComponent1 {
  @Require @Param item: Episode
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() progress: Progress[] = []
  @Consumer() isPlaying: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() syncTime: number = 0
  @Consumer() isIndex: boolean = true
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.episodeId === this.item.id)
  @Local showPlayLoading: boolean = false
  @Monitor('syncTime')
  async refreshProgress(monitor: IMonitor) {
    this.itemProgress = undefined
    this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
  }

  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    let formattedTime = '';
    if (hours > 0) {
      formattedTime += `${hours} hr `;
    }
    formattedTime += `${minutes} min`;
    return formattedTime;
  }

  formatTime(timestamp: number): string {
    let date = new Date(timestamp)
    let year = date.getFullYear()
    let month = (date.getMonth() + 1).toString().padStart(2, '0')
    let day = date.getDate().toString().padStart(2, '0')
    let hours = date.getHours().toString().padStart(2, '0')
    let minutes = date.getMinutes().toString().padStart(2, '0')
    return `${year}/${month}/${day} ${hours}:${minutes}`
  }

  build() {
    Column() {
      Text(this.formatTime(this.item.publishedAt) + " 发布")
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .margin({ bottom: 5 })

      Text(this.item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 5 })

      Text(this.item.description
      // 段落与换行
        .replace(/<p[^>]*>/gi, '')
        .replace(/<\/p>/gi, '\n')
        .replace(/<br\s*\/?>/gi, '')
        // 列表相关
        .replace(/<ul[^>]*>/gi, '')
        .replace(/<\/ul>/gi, '')
        .replace(/<ol[^>]*>/gi, '')
        .replace(/<\/ol>/gi, '')
        .replace(/<li[^>]*>/gi, '• ')
        .replace(/<\/li>/gi, '\n')
        // 链接：保留文字，去掉URL
        .replace(/<a[^>]*>(.*?)<\/a>/gi, '$1')
        // 忽略强调类标签
        .replace(/<\/?(b|strong|i|em|u)>/gi, '')
        // 去除其他残余HTML标签
        .replace(/<\/?[^>]+(>|$)/g, '')
        // HTML 实体
        .replace(/&nbsp;/gi, ' ')
        .replace(/&lt;/gi, '<')
        .replace(/&gt;/gi, '>')
        .replace(/&amp;/gi, '&')
        // 优化空行
        .replace(/\n{3,}/g, '\n')
        .trim())
        .fontSize(16)
        .width('100%')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Button({ type: ButtonType.Normal }) {
          Row() {
            if (this.showPlayLoading) {
              Column() {
                LoadingProgress()
                  .width(18)
                  .height(18)
                  .color($r('sys.color.ohos_id_color_titlebar_icon'))
              }
            } else {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontWeight(FontWeight.Normal)
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                .hitTestBehavior(HitTestMode.None)
                .margin({ bottom: 1 })
            }

            Text(this.formatDuration(this.item.duration))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 5 })
          }
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(38)
        .padding({ left: 10, right: 10 })
        .borderRadius(8)
        .onClick(async () => {
          this.showPlayLoading = true
          this.playingItem = await getPlayItem(this.item.libraryItemId!, this.item.id)
          if (this.playingItem) {
            await this.avPlayer!.reset();
            this.isStartPlaying = true
            this.isPlaying = true
            this.playingIndex = 0
            this.playingTitle = this.playingItem!.displayTitle.trim()
            this.playStartTime = this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
            console.log("共", this.playingItem!.audioTracks.length, "条音轨")
            console.log("播放序号为", this.playingIndex)
            console.log("起始位置为", this.playStartTime)
          }
          this.showPlayLoading = false
        })

        Button({ type: ButtonType.Normal }) {
          SymbolGlyph(this.itemProgress?.isFinished ? $r('sys.symbol.checkmark_square_fill') : $r('sys.symbol.checkmark_square'))
            .fontSize(20)
            .fontColor([$r('sys.color.font')])
        }
        .backgroundColor(Color.Transparent)
        .width(38)
        .height(38)
        .borderRadius(8)
        .margin({ left: 5 })
        .onClick(async () => {
          if (this.itemProgress?.isFinished) {
            let tmpProgress: UpdateProgress = {
              duration: this.item.duration,
              currentTime: 0,
              progress: 0,
              isFinished: false
            }
            let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
            }
          } else {
            let tmpProgress: UpdateProgress = {
              duration: this.item.duration,
              currentTime: this.item.duration,
              progress: 1,
              isFinished: true
            }
            let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
            }
          }
        })
      }
      .padding({
        top: 15, bottom: 20
      })

      Divider()
        .strokeWidth(1)
    }
    .margin({ top: 20 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.episode = this.item
      this.pageInfos.pushPathByName('episodeDetail', null)
    })
  }
}

@ComponentV2
export struct pageUpDown {
  @Require @Param scroller: Scroller

  build() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontWeight(FontWeight.Normal)
          .fontSize($r('sys.float.ohos_id_text_size_headline9'))
          .fontColor([$r('sys.color.font')])
      }
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .height(25)
      .width(25)
      .borderRadius(5)
      .onClick(() => {
        this.scroller.scrollPage({ next: false, animation: true })
      })

      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontWeight(FontWeight.Normal)
          .fontSize($r('sys.float.ohos_id_text_size_headline9'))
          .fontColor([$r('sys.color.font')])
      }
      .margin({ left: 12 })
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .height(25)
      .width(25)
      .borderRadius(5)
      .onClick(() => {
        this.scroller.scrollPage({ next: true, animation: true })
      })
    }
    .visibility(deviceTypeInfo === '2in1' ? Visibility.Visible : Visibility.None)
  }
}