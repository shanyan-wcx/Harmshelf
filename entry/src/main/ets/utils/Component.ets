import {
  LengthMetrics,
  RectShape,
  SymbolGlyphModifier,
  uiMaterial,
} from "@kit.ArkUI"
import { deviceInfo } from "@kit.BasicServicesKit";
import {
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsNavigationMenuItemOptions,
  HdsTabs,
  DividerMode,
  BottomBuilderShowType,
  hdsMaterial,
  ScrollEffectOptions,
  ScrollEffectType,
  TitleBarStyleOptions,
} from "@kit.UIDesignKit"
import { Home, HomeTopTabs } from "../pages/Home";
import { LocalMedia } from "../pages/Local";
import { Setting } from "../pages/Setting";
import { Stats } from "../pages/Stat";
import {
  addToPlaylist,
  createPlaylist,
  getItem,
  getPlayItem,
  getPlaylists,
  getUser,
  removeFromPlaylist,
  searchPodcasts as searchPodcastLibrary,
  updateProgress
} from "./Api";
import {
  Author,
  Series,
  LibraryItem,
  Library,
  Book,
  Progress,
  Episode,
  Filter1,
  UpdateProgress,
  PlayItem,
  Collection,
  Playlist,
  PlaylistItem,
  SearchPodcast,
  User
} from "./Interface"
import { media } from "@kit.MediaKit";
import { DownloadStatus, DownloadTaskInfo, DownloadManager } from "./Class";
import { DownloadSetting } from "../pages/Index";
import { fileUri, fileIo as fs } from "@kit.CoreFileKit";
import { Logger } from './Logger';
import { MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN } from './Layout';

let deviceTypeInfo: string = deviceInfo.deviceType;

export function getImmersiveActionRadius(height: number): number {
  return deviceTypeInfo === 'phone' || deviceTypeInfo === 'tablet' ? height / 2 : 8
}

export interface MainNavigationItem {
  symbol: Resource
  label: string
}
export function getMainNavigationItems(): MainNavigationItem[] {
  return [
    { symbol: $r('sys.symbol.house'), label: '首页' },
    { symbol: $r('sys.symbol.arrow_counterclockwise_clock'), label: '统计' },
    { symbol: $r('sys.symbol.folder'), label: '本地' },
    { symbol: $r('sys.symbol.slider_vertical_3'), label: '设置' },
  ]
}

export function transparentTitleBarStyle(): TitleBarStyleOptions {
  return titleBarStyle({
    enableScrollEffect: false
  })
}

export function gradientBlurTitleBarStyle(): TitleBarStyleOptions {
  return titleBarStyle({
    enableScrollEffect: true,
    scrollEffectType: ScrollEffectType.GRADIENT_BLUR
  })
}

function titleBarStyle(scrollEffectOpts: ScrollEffectOptions): TitleBarStyleOptions {
  return {
    scrollEffectOpts,
    originalStyle: {
      backgroundStyle: {
        backgroundColor: $r('sys.color.ohos_id_color_background_transparent')
      }
    },
    systemMaterialEffect: {
      materialType: hdsMaterial.MaterialType.IMMERSIVE,
      materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
    }
  }
}

@ComponentV2
export struct ImmersiveActionButton {
  @Param barWidth: number | '100%' = '100%'
  @Param barHeight: number = 50
  @Param barRadius: number | undefined = undefined
  @Param barBackgroundColor: ResourceColor | undefined = undefined
  @Param menuItems: Array<MenuElement> | undefined = undefined
  @Param onButtonClick: (() => void) | undefined = undefined
  @Param monopolizeActionEvents: boolean = true
  @Local measuredBarWidth: number = 1

  private resolvedBarWidth(): number {
    if (this.barWidth === '100%') {
      return this.measuredBarWidth
    }
    return this.barWidth
  }

  @Builder
  defaultButtonBuilder() {
    Blank()
  }

  @BuilderParam buttonContent: () => void = this.defaultButtonBuilder

  @Builder
  buttonTabBarBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      this.buttonContent()
    }
    .width(this.barWidth)
    .height('100%')
    .borderRadius(this.barRadius ?? getImmersiveActionRadius(this.barHeight))
    .clip(false)
    .onClick(() => {
      if (this.onButtonClick) {
        this.onButtonClick()
      }
    })
    .bindMenu(this.menuItems ?? [])
  }

  build() {
    HdsTabs() {
      TabContent() {
        Column()
          .width(0)
          .height(0)
          .clip(false)
      }
      .clip(false)
      .tabBar(this.buttonTabBarBuilder())
    }
    .width(this.barWidth)
    .height(this.barHeight)
    .layoutWeight(this.barWidth === '100%' ? 1 : 0)
    .barWidth(this.resolvedBarWidth())
    .barHeight(this.barHeight)
    .barOverlap(true)
    .divider({ mode: DividerMode.NONE })
    .barPosition(BarPosition.End)
    .vertical(false)
    .scrollable(false)
    .barMode(BarMode.Fixed)
    .barFloatingStyle({
      barWidth: {
        smallWidth: this.resolvedBarWidth(),
        mediumWidth: this.resolvedBarWidth(),
        largeWidth: this.resolvedBarWidth()
      },
      barSideMargin: 0,
      barBottomMargin: 0,
      gradientMask: {
        maskColor: Color.Transparent
      },
      lightColor: this.barBackgroundColor,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    })
    .barBackgroundColor(this.barBackgroundColor ?? Color.Transparent)
    .barBackgroundBlurStyle(BlurStyle.NONE)
    .clip(false)
    .onAreaChange((oldArea, newArea) => {
      let measuredWidth: number = Number(newArea.width)
      if (this.barWidth === '100%' && this.measuredBarWidth !== measuredWidth) {
        this.measuredBarWidth = measuredWidth
      }
    })
    .monopolizeEvents(this.monopolizeActionEvents)
  }
}

@ComponentV2
export struct MyNavigation {
  @Consumer() statsScroller: Scroller = new Scroller()
  @Consumer() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() logScroller: Scroller = new Scroller()
  @Consumer() settingScroller: Scroller = new Scroller()
  @Consumer() displayWidth: number = 0
  @Consumer() sideBarWidth: number = 240
  @Consumer() statusBarHeight: number = 0
  @Consumer() pageInfos: NavPathStack = new NavPathStack()
  @Consumer() pageIndex: number = 0;
  @Consumer() firstAppear: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() selectOptions: SelectOption[] = []
  @Consumer() selectLibraryIndex: number = 0
  @Consumer() topTabIndex: number = 0
  @Consumer() needUpdate: boolean = false
  @Consumer() user: User | undefined = undefined
  @Consumer() isConnect: boolean = true
  @Consumer() isShowSidebar: boolean = false
  @Consumer() sidebarType: number = SideBarContainerType.Overlay
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() libraries: Library[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() searchPodcasts: SearchPodcast[] = []
  @Consumer() term: string = ""
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() downloadTasks: DownloadTaskInfo[] = []
  @Consumer() downloadCount: number = 0
  @Local isDownloadEmpty: boolean = true
  private navigationItems: MainNavigationItem[] = getMainNavigationItems()

  @Monitor('downloadCount')
  async updateMenus(monitor: IMonitor) {
    if (this.downloadCount === 0) {
      this.isDownloadEmpty = true
    } else {
      this.isDownloadEmpty = false
    }
  }

  aboutToAppear() {
    this.firstAppear = true
  }

  private isBottomTabDevice(): boolean {
    return deviceTypeInfo === 'phone' || deviceTypeInfo === 'tablet'
  }

  private isAddSearchVisible(): boolean {
    return this.pageIndex === 0 &&
      this.library?.mediaType === 'podcast' &&
      (this.user?.type === 'root' || this.user?.type === 'admin') &&
      this.topTabIndex === 3
  }

  private isHomeTabsVisible(): boolean {
    return this.pageIndex === 0 && this.baseUrl !== "" && this.library !== undefined
  }

  private addSearchRadius(): number {
    return this.isBottomTabDevice() ? 22.5 : 8
  }

  private bottomTabBarStyle(item: MainNavigationItem): BottomTabBarStyle {
    return new BottomTabBarStyle({
      normal: new SymbolGlyphModifier(item.symbol)
        .fontColor([$r('sys.color.font_secondary')]),
      selected: new SymbolGlyphModifier(item.symbol)
        .fontColor([$r('sys.color.comp_emphasize_secondary')])
    }, item.label).labelStyle({
      selectedColor: $r('sys.color.comp_emphasize_secondary'),
      unselectedColor: $r('sys.color.font_secondary')
    })
  }

  private onBottomTabChange(index: number) {
    if (index === this.pageIndex) {
      return
    }
    this.pageIndex = index
    this.pageInfos.clear()
  }

  @Builder
  bottomTabBarBuilder() {
    Tabs({ barPosition: BarPosition.End, index: this.pageIndex }) {
      TabContent() {
        Home()
      }
      .tabBar(this.bottomTabBarStyle(this.navigationItems[0]))

      TabContent() {
        Stats()
      }
      .tabBar(this.bottomTabBarStyle(this.navigationItems[1]))

      TabContent() {
        LocalMedia()
      }
      .tabBar(this.bottomTabBarStyle(this.navigationItems[2]))

      TabContent() {
        Setting()
      }
      .tabBar(this.bottomTabBarStyle(this.navigationItems[3]))
    }
    .width('100%')
    .height('100%')
    .barGridAlign({ sm: 4, md: 4, lg: 4, margin: 16 })
    .barOverlap(true)
    .vertical(false)
    .scrollable(false)
    .animationCurve(Curve.Friction)
    .animationDuration(280)
    .barHeight('auto')
    .barBackgroundColor(Color.Transparent)
    .barFloatingStyle({
      barSideMargin: 16,
      barBottomMargin: MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN,
      maskColor: Color.Transparent,
      maskHeight: 0,
      systemMaterial: new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
        applyShadow: true,
        interactive: true,
        lightEffect: { color: Color.White }
      })
    })
    .onChange((index: number) => {
      this.onBottomTabChange(index)
    })
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
          .flexShrink(1)

        SymbolGlyph(this.isConnect ? $r('sys.symbol.checkmark_icloud_fill') : $r('sys.symbol.icloud_slash_fill'))
          .margin({ left: 16 })
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor([this.isConnect ? Color.Green : Color.Orange])
      }
      .width(!this.isDownloadEmpty ?
        (deviceTypeInfo === '2in1' ? this.sideBarContentWidth - 225 : this.sideBarContentWidth - 149) :
        (deviceTypeInfo === '2in1' ? this.sideBarContentWidth - 177 : this.sideBarContentWidth - 101))
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  addSearchBuilder() {
    Row() {
      Search({ value: this.term })
        .width('100%')
        .height(45)
        .borderRadius(this.addSearchRadius())
        .margin({ top: 15, bottom: 20 })
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
        .onChange((value: string) => {
          this.term = value
        })
        .onSubmit(async (query) => {
          if (query.length !== 0) {
            this.showLoadingProgress = true
            this.searchPodcasts = await searchPodcastLibrary(this.term)
            this.showLoadingProgress = false
          }
        })
    }
    .width('100%')
    .height(80)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  homeTitleBottomBuilder() {
    Column() {
      HomeTopTabs()
      if (this.isAddSearchVisible()) {
        this.addSearchBuilder()
      }
    }
    .width('100%')
    .height(this.isAddSearchVisible() ? 116 : 36)
    .clip(false)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  build() {
    HdsNavigation(this.pageInfos) {
      if (this.isBottomTabDevice()) {
        this.bottomTabBarBuilder()
      } else {
        Column() {
          if (this.pageIndex === 0) {
            Home()
          } else if (this.pageIndex === 1) {
            Stats()
          } else if (this.pageIndex === 2) {
            LocalMedia()
          } else if (this.pageIndex === 3) {
            Setting()
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(this.isBottomTabDevice() || this.sidebarType === SideBarContainerType.Overlay ?
      '100%' : this.displayWidth - this.sideBarWidth)
    .height('100%')
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .backgroundColor($r('sys.color.background_secondary'))
    .mode(NavigationMode.Stack)
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        end: deviceTypeInfo === '2in1' ? LengthMetrics.vp(168) : LengthMetrics.vp(16)
      },
      style: transparentTitleBarStyle(),
      content: {
        stackBuilder: (): void => this.titleBarBuilder(),
        bottomBuilder: this.isHomeTabsVisible() ? {
          builder: (): void => this.homeTitleBottomBuilder(),
          height: this.isAddSearchVisible() ? 116 : 36,
          showType: BottomBuilderShowType.DIRECTLY_SHOW
        } : undefined,
        menu: {
          value: this.sidebarType === SideBarContainerType.Embed || this.isBottomTabDevice() ?
            (this.isDownloadEmpty ?
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
                  icon: $r('sys.symbol.download'),
                  label: 'download',
                  action: () => {
                    this.pageInfos.pushPathByName('downloadTask', null)
                  }
                },
                badge: {
                  count: this.downloadCount
                }
              }, {
                content: {
                  icon: $r('sys.symbol.magnifyingglass'),
                  label: 'search',
                  action: () => {
                    this.pageInfos.pushPathByName('search', null)
                  }
                }
              }]) : (this.isDownloadEmpty ?
              [{
                content: {
                  icon: $r('sys.symbol.magnifyingglass'),
                  label: 'search',
                  action: () => {
                    this.pageInfos.pushPathByName('search', null)
                  }
                }
              }, {
                content: {
                  icon: $r('sys.symbol.open_sidebar'),
                  label: 'sidebar',
                  action: () => {
                    this.isShowSidebar = !this.isShowSidebar
                  }
                }
              }] :
              [{
                content: {
                  icon: $r('sys.symbol.download'),
                  label: 'download',
                  action: () => {
                    this.pageInfos.pushPathByName('downloadTask', null)
                  }
                },
                badge: {
                  count: this.downloadCount
                }
              }, {
                content: {
                  icon: $r('sys.symbol.magnifyingglass'),
                  label: 'search',
                  action: () => {
                    this.pageInfos.pushPathByName('search', null)
                  }
                }
              }, {
                content: {
                  icon: $r('sys.symbol.open_sidebar'),
                  label: 'sidebar',
                  action: () => {
                    this.isShowSidebar = !this.isShowSidebar
                  }
                }
              }])
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MINI)
    .hideBackButton(true)
    .bindToScrollable([this.statsScroller, this.LocalMediaScroller, this.logScroller, this.settingScroller])
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
              .color(this.progress?.progress === 1 || this.progress?.isFinished ?
                $r('sys.color.ohos_id_color_palette4') :
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
        .borderRadius(10)
        .clip(true)
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .border({
        width: 0.35,
        radius: 10,
        color: $r('sys.color.ohos_id_color_focused_outline_transparent')
      })
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .clip(false)
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
    .clip(false)
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
              .color(this.progress?.progress === 1 || this.progress?.isFinished ?
                $r('sys.color.ohos_id_color_palette4') :
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
        .borderRadius(10)
        .clip(true)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .border({
        width: 0.35,
        radius: 10,
        color: $r('sys.color.ohos_id_color_focused_outline_transparent')
      })
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .clip(false)
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
    .clip(false)
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
      .borderRadius(10)
      .clip(true)
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

      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: 28,
          onButtonClick: () => {
            let filter: Filter1 = {
              criteria: this.series.name,
              type: "series"
            }
            this.series1 = this.series
            this.pageInfos.pushPathByName('filterItems', filter)
          }
        }) {
          Text(this.series.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .padding({ left: 6, right: 6 })
        }
      }
      .width('100%')
      .height(28)
      .padding({ left: 6, right: 6 })
      .margin({ bottom: 6 })
    }
    .borderRadius(10)
    .border({
      width: 0.35,
      radius: 10,
      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
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
    const gap = Number(this.imageWidth) / (collection.books!.length - 1) / 2;
    if (collection.books!.length == 1) {
      return Number(this.imageWidth) / 2
    } else {
      return (collection.books!.length - 1 - index) * gap
    }
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Stack({ alignContent: Alignment.Bottom }) {
          if (this.collection.books!.length === 1) {
            Column() {
              Image(this.baseUrl + `/api/items/${this.collection.books![0].id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
                .draggable(false)
            }
            .width('100%')
            .height('100%')
            .backgroundImage(this.baseUrl + `/api/items/${this.collection.books![0].id}/cover?token=${this.apiToken}`)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
          } else {
            ForEach(this.collection.books!.slice().reverse(), (book: Book, index) => {
              Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height('100%')
                .aspectRatio(1)
                .clip(true)
                .objectFit(ImageFit.Fill)
                .draggable(false)
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
      .borderRadius(10)
      .clip(true)
      .onAreaChange((oldArea, newArea) => {
        this.imageWidth = newArea.width
      })
      .onClick(() => {
        this.collection1 = this.collection
        this.pageInfos.pushPathByName('collectionDetail', null)
      })

      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: 28,
          onButtonClick: () => {
            this.collection1 = this.collection
            this.pageInfos.pushPathByName('collectionDetail', null)
          }
        }) {
          Text(this.collection.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .padding({ left: 6, right: 6 })
        }
      }
      .width('100%')
      .height(28)
      .padding({ left: 6, right: 6 })
      .margin({ bottom: 6 })
    }
    .borderRadius(10)
    .border({
      width: 0.35,
      radius: 10,
      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
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
    Stack({ alignContent: Alignment.Bottom }) {
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
              .draggable(false)
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
                    .draggable(false)
                })
              }
            })
          }
        }
        .borderRadius(10)
        .clip(true)
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

      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: 28,
          onButtonClick: () => {
            this.playlist1 = this.playlist
            this.pageInfos.pushPathByName('playlistDetail', null)
          }
        }) {
          Text(this.playlist.name)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .padding({ left: 6, right: 6 })
        }
      }
      .width('100%')
      .height(28)
      .padding({ left: 6, right: 6 })
      .margin({ bottom: 6 })
    }
    .borderRadius(10)
    .border({
      width: 0.35,
      radius: 10,
      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
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
  @Local imageHeight: number = 0

  private getTitleHeight(): number {
    return this.imageHeight > 0 ? this.imageHeight / 5 : 1
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Stack() {
          Image(this.baseUrl + `/api/authors/${this.author.id}/image?token=${this.apiToken}`)
            .alt($rawfile('noprofile.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .borderRadius(10)
            .draggable(false)

          Stack() {
            ImmersiveActionButton({
              barWidth: 18,
              barHeight: 18,
              barRadius: 9,
              onButtonClick: () => {
                let filter: Filter1 = {
                  criteria: this.author.name,
                  type: "author"
                }
                this.pageInfos.pushPathByName('filterItems', filter)
              }
            }) {
              Row() {
                Text(Math.min(this.author.numBooks ?? 0, 99).toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Center)
                  .offset({ y: -1 })
                  .hitTestBehavior(HitTestMode.None)
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .clip(false)
            }
          }
          .width(18)
          .height(18)
          .position({ top: 6, right: 6 })
        }
        .width('100%')
        .height('100%')
        .clip(false)
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(0.85)
      .borderRadius(10)
      .backgroundColor(Color.Transparent)
      .onAreaChange((oldArea, newArea) => {
        this.imageHeight = Number(newArea.height)
      })

      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: this.getTitleHeight(),
          onButtonClick: () => {
            let filter: Filter1 = {
              criteria: this.author.name,
              type: "author"
            }
            this.pageInfos.pushPathByName('filterItems', filter)
          }
        }) {
          Row() {
            Text(this.author.name)
              .fontSize(18)
              .minFontSize(13)
              .maxFontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('calc(100% + 16vp)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .offset({ x: -8 })
              .hitTestBehavior(HitTestMode.None)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .clip(false)
        }
      }
      .width('calc(100% - 12vp)')
      .height(this.getTitleHeight())
      .margin({ left: 6, right: 6, bottom: 6 })
    }
    .borderRadius(10)
    .border({
      width: 0.35,
      radius: 10,
      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
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
  @Local imageHeight: number = 0

  private getTitleHeight(): number {
    return this.imageHeight > 0 ? this.imageHeight / 5 : 1
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Normal }) {
        Stack() {
          Image(this.baseUrl + `/api/authors/${this.author.id}/image?token=${this.apiToken}`)
            .alt($rawfile('noprofile.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .borderRadius(10)
            .draggable(false)

          Stack() {
            ImmersiveActionButton({
              barWidth: 18,
              barHeight: 18,
              barRadius: 9,
              onButtonClick: () => {
                let filter: Filter1 = {
                  criteria: this.author.name,
                  type: "author"
                }
                this.pageInfos.pushPathByName('filterItems', filter)
              }
            }) {
              Row() {
                Text(Math.min(this.author.numBooks ?? 0, 99).toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Center)
                  .offset({ y: -1 })
                  .hitTestBehavior(HitTestMode.None)
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .clip(false)
            }
          }
          .width(18)
          .height(18)
          .position({ top: 6, right: 6 })
        }
        .width('100%')
        .height('100%')
        .clip(false)
      }
      .width('100%')
      .height('auto')
      .layoutWeight(1)
      .aspectRatio(0.85)
      .borderRadius(10)
      .backgroundColor(Color.Transparent)
      .onAreaChange((oldArea, newArea) => {
        this.imageHeight = Number(newArea.height)
      })

      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: this.getTitleHeight(),
          onButtonClick: () => {
            let filter: Filter1 = {
              criteria: this.author.name,
              type: "author"
            }
            this.pageInfos.pushPathByName('filterItems', filter)
          }
        }) {
          Row() {
            Text(this.author.name)
              .fontSize(18)
              .minFontSize(13)
              .maxFontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('calc(100% + 16vp)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .offset({ x: -8 })
              .hitTestBehavior(HitTestMode.None)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .clip(false)
        }
      }
      .width('calc(100% - 12vp)')
      .height(this.getTitleHeight())
      .margin({ left: 6, right: 6, bottom: 6 })
    }
    .borderRadius(10)
    .border({
      width: 0.35,
      radius: 10,
      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
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
            .color(this.progress?.progress === 1 || this.progress?.isFinished ? $r('sys.color.ohos_id_color_palette4') :
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

          Stack() {
            ImmersiveActionButton({
              barWidth: 38,
              barHeight: 20,
              barRadius: 10,
              onButtonClick: () => {
                this.episode = this.item.recentEpisode
                this.pageInfos.pushPathByName('episodeDetail', null)
              },
              monopolizeActionEvents: true
            }) {
              Text("剧集")
                .fontSize(12)
            }
          }
          .width(38)
          .height(20)
          .position({
            top: 6,
            right: 6
          })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Bottom)
        .borderRadius(10)
        .clip(true)
      }
      .width('auto')
      .height('100%')
      .layoutWeight(1)
      .aspectRatio(1)
      .borderRadius(10)
      .border({
        width: 0.35,
        radius: 10,
        color: $r('sys.color.ohos_id_color_focused_outline_transparent')
      })
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .clip(false)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.episode = this.item.recentEpisode
        this.pageInfos.pushPathByName('episodeDetail', null)
      })

      Column() {
        Text(this.item.recentEpisode?.title ?? "-")
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
    .clip(false)
  }
}

@ComponentV2
export struct EpisodeComponent {
  @Require @Param item: Episode
  @Consumer() displayWidth: number = 0
  @Consumer() downloadManager: DownloadManager | undefined = undefined
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() playlists: Playlist[] = []
  @Consumer() library: Library | undefined = undefined
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
  @Consumer() user: User | undefined = undefined
  @Consumer() downloadUri: string = ""
  @Consumer() downloadTasks: DownloadTaskInfo[] = []
  @Consumer() downloadCount: number = 0
  @Consumer() downloadSetting: DownloadSetting | undefined = undefined
  @Consumer() toCloseSession: PlayItem | undefined = undefined
  @Consumer() toCloseIndex: number = 0
  @Local podcast: LibraryItem | undefined = undefined
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.episodeId === this.item.id)
  @Local showPlayLoading: boolean = false
  @Local showPlaylists: boolean = false
  @Local showProgress: boolean = false
  @Local showCreatePlaylist: boolean = false
  @Local showConfirmDownload: boolean = false
  @Local tmpPlaylistName: string = ""
  @Local tmpPlaylistDescription: string = ""

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

  @Builder
  confirmDownloadBuilder() {
    Column() {
      Text("确认下载" + this.item.title + "？")
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
        .borderRadius(10)
        .onClick(() => {
          this.showConfirmDownload = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("确认")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(async () => {
          this.getUIContext().getPromptAction().showToast({
            message: '开始下载！',
            duration: 500
          });
          this.showConfirmDownload = false
          this.podcast = await getItem(this.item!.libraryItemId!)
          if (this.podcast) {
            this.item!.audioTrack = this.podcast!.media.episodes!.find(e => e.id === this.item!.id)?.audioTrack
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '下载失败，请检查网络！',
              duration: 500
            });
            return
          }
          const downloadPath = new fileUri.FileUri(this.downloadUri).path
          const dir = downloadPath + "/播客/" + this.podcast!.media.metadata.title
          const existsDir = fs.accessSync(dir)
          if (!existsDir) {
            fs.mkdirSync(dir);
          }
          const filePath = dir + "/" + this.item!.audioFile!.metadata.filename
          if (this.downloadSetting?.skipExistingFiles && fs.accessSync(filePath)) {
            Logger.info(`文件已存在，跳过: ${filePath}`)
          } else {
            const task = new DownloadTaskInfo()
            task.mediaType = this.library!.mediaType
            task.folder = this.podcast!.media.metadata.title
            task.id = this.item!.id!
            task.title = this.item!.audioFile!.metadata.filename
            task.url = this.baseUrl + this.item!.audioTrack?.contentUrl + "?token=" + this.apiToken
            task.filePath = filePath
            this.downloadTasks.push(task)
            this.downloadCount = this.downloadTasks.length
            this.downloadManager!.add(
              this.library!.mediaType,
              this.podcast!.media.metadata.title,
              this.item!.id!,
              this.item!.audioFile!.metadata.filename,
              this.baseUrl + this.item!.audioTrack?.contentUrl + "?token=" + this.apiToken,
              filePath,
              (info) => {
                // 下载进度回调
                Logger.info(`Progress: ${info.title} ${Math.floor(info.progress)}%`);
                let index = this.downloadTasks.findIndex(t => t.id === info.id)
                if (index >= 0) {
                  this.downloadTasks[index].progress = info.progress;
                }
              },
              (info) => {
                // 状态变化回调
                Logger.info(`Status changed: ${info.title} ${info.status}`);
                let index = this.downloadTasks.findIndex(t => t.id === info.id)
                if (index >= 0) {
                  if (info.status === DownloadStatus.Removed) {
                    this.downloadTasks.splice(index, 1);
                    this.downloadCount = this.downloadTasks.length
                  } else {
                    this.downloadTasks[index].status = info.status;
                  }
                }
              }
            )
          }
          const coverUrl = this.baseUrl + `/api/items/${this.item.libraryItemId}/cover?token=${this.apiToken}`
          this.downloadManager!.downloadCover(coverUrl, dir + "/cover.jpg")
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
  }

  @Builder
  playlistsBuilder() {
    Column() {
      Stack() {
        List() {
          ForEach(this.playlists, (playlist: Playlist, index) => {
            ListItem() {
              Row() {
                Text(playlist.name)
                  .fontSize(18)
                  .width('100%')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Button({ type: ButtonType.Normal }) {
                  Text(playlist.items.find(p => p.episodeId === this.item.id) ? "移除" : "添加")
                }
                .width(80)
                .height(40)
                .borderRadius(10)
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  let tmpPlaylist: Playlist | undefined = undefined
                  let item = playlist.items.find(p => p.episodeId === this.item.id)
                  if (!item) {
                    tmpPlaylist = await addToPlaylist(playlist.id!, this.item.libraryItemId!, this.item.id)
                  } else {
                    tmpPlaylist = await removeFromPlaylist(playlist.id!, this.item.libraryItemId!, this.item.id)
                  }
                  if (tmpPlaylist) {
                    this.showPlaylists = false
                    playlist = tmpPlaylist
                  }
                })
              }
              .height(60)
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.divider')
        })
        .visibility(!this.showProgress ? Visibility.Visible : Visibility.None)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(72)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 80 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)

      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("新建播放列表")
            .fontSize(18)
        }
        .height(45)
        .width('100%')
        .borderRadius(10)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(async () => {
          if (this.showProgress) {
            this.getUIContext().getPromptAction().showToast({
              message: '正在加载播放列表！',
              duration: 500
            });
          } else {
            this.tmpPlaylistName = ""
            this.tmpPlaylistDescription = ""
            this.showPlaylists = false
            this.showCreatePlaylist = true
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 25 })
    }
  }

  @Builder
  createPlaylistBuilder() {
    Column() {
      TextInput({
        placeholder: "播放列表名称"
      })
        .width("100%")
        .height(45)
        .borderRadius(10)
        .margin({ bottom: 20 })
        .caretColor($r('sys.color.font_secondary'))
        .fontSize(18)
        .placeholderFont({
          size: 18
        })
        .type(InputType.Normal)
        .enterKeyType(EnterKeyType.Done)
        .onChange((value) => {
          this.tmpPlaylistName = value
        })

      TextArea({
        placeholder: "播放列表描述"
      })
        .width("100%")
        .height(120)
        .borderRadius(10)
        .margin({ bottom: 20 })
        .caretColor($r('sys.color.font_secondary'))
        .fontSize(18)
        .placeholderFont({
          size: 18
        })
        .type(TextAreaType.NORMAL)
        .enterKeyType(EnterKeyType.Done)
        .barState(BarState.Off)
        .onChange((value) => {
          this.tmpPlaylistDescription = value
        })

      Row({ space: 20 }) {
        Button({ type: ButtonType.Normal }) {
          Text("取消")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(() => {
          this.showCreatePlaylist = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("确认")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(async () => {
          if (this.tmpPlaylistName.length === 0) {
            this.getUIContext().getPromptAction().showToast({
              message: '播放列表名称不能为空！',
              duration: 500
            });
          } else {
            let playlist: Playlist = {
              libraryId: this.library!.id,
              name: this.tmpPlaylistName,
              description: this.tmpPlaylistDescription.length > 0 ? this.tmpPlaylistDescription : null,
              items: [{
                libraryItemId: this.episode!.libraryItemId!,
                episodeId: this.episode!.id!,
                episode: this.episode
              }]
            }
            let newPlaylist = await createPlaylist(playlist)
            if (newPlaylist) {
              this.playlists.push(newPlaylist)
              this.showCreatePlaylist = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表失败，请检查网络！',
                duration: 500
              });
            }
          }
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
  }

  build() {
    Column() {
      Row() {
        Stack() {
          Image(this.baseUrl + `/api/items/${this.item.libraryItemId}/cover?token=${this.apiToken}`)
            .alt($rawfile('nocover.jpg'))
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
            .borderRadius(10)
            .clip(true)
            .draggable(false)
        }
          .width(45)
          .height(45)
          .borderRadius(10)
          .border({
            width: 0.35,
            radius: 10,
            color: $r('sys.color.ohos_id_color_focused_outline_transparent')
          })
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
          .clip(false)
          .margin({ right: 10 })

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
              this.libraryItem = this.libraryItems.find(item => item.id === this.item.libraryItemId!)
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

      Row({ space: 16 }) {
        Row() {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 38,
            onButtonClick: async () => {
              this.showPlayLoading = true
              this.toCloseIndex = this.playingIndex
              this.toCloseSession = this.playingItem
              this.playingItem = await getPlayItem(this.item.libraryItemId!, this.item.id)
              if (this.playingItem) {
                await this.avPlayer!.reset();
                this.isStartPlaying = true
                this.isPlaying = true
                this.playingIndex = 0
                this.playingTitle = this.playingItem!.displayTitle.trim()
                this.playStartTime = this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
                this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
                Logger.info(`共this.playingItem!.audioTracks.length条音轨`)
                Logger.info(`播放序号为this.playingIndex`)
                Logger.info(`起始位置为this.playStartTime`)
              }
              this.showPlayLoading = false
            }
          }) {
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
                  .clip(false)
                  .hitTestBehavior(HitTestMode.None)
                  .margin({ bottom: 1 })
              }

              Text(this.formatDuration(this.item.duration!))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 5 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .padding({ left: 10, right: 10 })
            .clip(false)
          }
        }
        .clip(false)
        .layoutWeight(1)
        .height(38)
        .clip(false)

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: async () => {
              if (this.itemProgress?.isFinished) {
                let tmpProgress: UpdateProgress = {
                  duration: this.item.duration!,
                  currentTime: 0,
                  progress: 0,
                  isFinished: false
                }
                let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
                if (status) {
                  this.progress = (await getUser())?.mediaProgress ?? this.progress
                  this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
                }
              } else {
                let tmpProgress: UpdateProgress = {
                  duration: this.item.duration!,
                  currentTime: this.item.duration!,
                  progress: 1,
                  isFinished: true
                }
                let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
                if (status) {
                  this.progress = (await getUser())?.mediaProgress ?? this.progress
                  this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
                }
              }
            }
          }) {
            Row() {
              SymbolGlyph(this.itemProgress?.isFinished ? $r('sys.symbol.checkmark_square_fill') :
                $r('sys.symbol.checkmark_square'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: (): void => {
              this.showPlaylists = true
            }
          }) {
            Row() {
              SymbolGlyph($r('sys.symbol.music_note_list'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)
        .bindSheet(this.showPlaylists, this.playlistsBuilder(), {
          height: SheetSize.MEDIUM,
          preferType: SheetType.CENTER,
          title: {
            title: "播放列表"
          },
          showClose: false,
          onWillAppear: async () => {
            this.showProgress = true
            this.playlists = await getPlaylists(this.library!.id)
            this.showProgress = false
          },
          onDisappear: () => {
            this.showPlaylists = false
          }
        })

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: (): void => {
              if (!this.user?.permissions.download) {
                this.getUIContext().getPromptAction().showToast({
                  message: '当前用户没有下载权限！',
                  duration: 500
                });
              } else {
                this.showConfirmDownload = true
              }
            }
          }) {
            Row() {
              SymbolGlyph($r('sys.symbol.download'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)
        .bindSheet(this.showConfirmDownload, this.confirmDownloadBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: SheetType.CENTER,
          title: {
            title: "确认下载"
          },
          showClose: false,
          onDisappear: () => {
            this.showConfirmDownload = false
          }
        })
      }
      .padding({
        top: 15, bottom: 20
      })
      .clip(false)
      .bindSheet(this.showCreatePlaylist, this.createPlaylistBuilder(), {
        height: SheetSize.FIT_CONTENT,
        preferType: SheetType.CENTER,
        title: {
          title: "新建播放列表"
        },
        showClose: false,
        onDisappear: () => {
          this.showCreatePlaylist = false
        }
      })

      Divider()
        .strokeWidth(1)
    }
    .margin({ top: 20 })
    .alignItems(HorizontalAlign.Start)
    .clip(false)
    .onClick(() => {
      this.episode = this.item
      this.pageInfos.pushPathByName('episodeDetail', null)
    })
  }
}

@ComponentV2
export struct EpisodeComponent1 {
  @Require @Param item: Episode
  @Consumer() displayWidth: number = 0
  @Consumer() downloadManager: DownloadManager | undefined = undefined
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() progress: Progress[] = []
  @Consumer() playlists: Playlist[] = []
  @Consumer() library: Library | undefined = undefined
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
  @Consumer() user: User | undefined = undefined
  @Consumer() downloadUri: string = ""
  @Consumer() downloadTasks: DownloadTaskInfo[] = []
  @Consumer() downloadCount: number = 0
  @Consumer() downloadSetting: DownloadSetting | undefined = undefined
  @Consumer() toCloseSession: PlayItem | undefined = undefined
  @Consumer() toCloseIndex: number = 0
  @Local podcast: LibraryItem | undefined = undefined
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.episodeId === this.item.id)
  @Local showPlayLoading: boolean = false
  @Local showPlaylists: boolean = false
  @Local showProgress: boolean = false
  @Local showCreatePlaylist: boolean = false
  @Local showConfirmDownload: boolean = false
  @Local tmpPlaylistName: string = ""
  @Local tmpPlaylistDescription: string = ""

  async playEpisodeItem() {
    this.showPlayLoading = true
    this.toCloseIndex = this.playingIndex
    this.toCloseSession = this.playingItem
    this.playingItem = await getPlayItem(this.item.libraryItemId!, this.item.id)
    if (this.playingItem) {
      await this.avPlayer!.reset();
      this.isStartPlaying = true
      this.isPlaying = true
      this.playingIndex = 0
      this.playingTitle = this.playingItem!.displayTitle.trim()
      this.playStartTime = this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
      Logger.info(`共this.playingItem!.audioTracks.length条音轨`)
      Logger.info(`播放序号为this.playingIndex`)
      Logger.info(`起始位置为this.playStartTime`)
    }
    this.showPlayLoading = false
  }

  async toggleEpisodeProgress() {
    let tmpProgress: UpdateProgress = {
      duration: this.item.duration!,
      currentTime: this.itemProgress?.isFinished ? 0 : this.item.duration!,
      progress: this.itemProgress?.isFinished ? 0 : 1,
      isFinished: !this.itemProgress?.isFinished
    }
    let status = await updateProgress(tmpProgress, this.item.libraryItemId!, this.item.id)
    if (status) {
      this.progress = (await getUser())?.mediaProgress ?? this.progress
      this.itemProgress = this.progress.find(p => p.episodeId === this.item.id)
    }
  }

  async requestEpisodeDownload() {
    if (!this.user?.permissions.download) {
      this.getUIContext().getPromptAction().showToast({
        message: '当前用户没有下载权限！',
        duration: 500
      });
    } else {
      this.showConfirmDownload = true
    }
  }

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

  @Builder
  confirmDownloadBuilder() {
    Column() {
      Text("确认下载" + this.item.title + "？")
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
        .borderRadius(10)
        .onClick(() => {
          this.showConfirmDownload = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("确认")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(async () => {
          this.getUIContext().getPromptAction().showToast({
            message: '开始下载！',
            duration: 500
          });
          this.showConfirmDownload = false
          this.podcast = await getItem(this.item!.libraryItemId!)
          if (this.podcast) {
            this.item!.audioTrack = this.podcast!.media.episodes!.find(e => e.id === this.item!.id)?.audioTrack
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '下载失败，请检查网络！',
              duration: 500
            });
            return
          }
          const downloadPath = new fileUri.FileUri(this.downloadUri).path
          const dir = downloadPath + "/播客/" + this.podcast!.media.metadata.title
          const existsDir = fs.accessSync(dir)
          if (!existsDir) {
            fs.mkdirSync(dir);
          }
          const filePath = dir + "/" + this.item!.audioFile!.metadata.filename
          if (this.downloadSetting?.skipExistingFiles && fs.accessSync(filePath)) {
            Logger.info(`文件已存在，跳过: ${filePath}`)
          } else {
            const task = new DownloadTaskInfo()
            task.mediaType = this.library!.mediaType
            task.folder = this.podcast!.media.metadata.title
            task.id = this.item!.id!
            task.title = this.item!.audioFile!.metadata.filename
            task.url = this.baseUrl + this.item!.audioTrack?.contentUrl + "?token=" + this.apiToken
            task.filePath = filePath
            this.downloadTasks.push(task)
            this.downloadCount = this.downloadTasks.length
            this.downloadManager!.add(
              this.library!.mediaType,
              this.podcast!.media.metadata.title,
              this.item!.id!,
              this.item!.audioFile!.metadata.filename,
              this.baseUrl + this.item!.audioTrack?.contentUrl + "?token=" + this.apiToken,
              filePath,
              (info) => {
                // 下载进度回调
                Logger.info(`Progress: ${info.title} ${Math.floor(info.progress)}%`);
                let index = this.downloadTasks.findIndex(t => t.id === info.id)
                if (index >= 0) {
                  this.downloadTasks[index].progress = info.progress;
                }
              },
              (info) => {
                // 状态变化回调
                Logger.info(`Status changed: ${info.title} ${info.status}`);
                let index = this.downloadTasks.findIndex(t => t.id === info.id)
                if (index >= 0) {
                  if (info.status === DownloadStatus.Removed) {
                    this.downloadTasks.splice(index, 1);
                    this.downloadCount = this.downloadTasks.length
                  } else {
                    this.downloadTasks[index].status = info.status;
                  }
                }
              }
            )
          }
          const coverUrl = this.baseUrl + `/api/items/${this.item.libraryItemId}/cover?token=${this.apiToken}`
          this.downloadManager!.downloadCover(coverUrl, dir + "/cover.jpg")
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
  }

  @Builder
  playlistsBuilder() {
    Column() {
      Stack() {
        List() {
          ForEach(this.playlists, (playlist: Playlist, index) => {
            ListItem() {
              Row() {
                Text(playlist.name)
                  .fontSize(18)
                  .width('100%')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Button({ type: ButtonType.Normal }) {
                  Text(playlist.items.find(p => p.episodeId === this.item.id) ? "移除" : "添加")
                }
                .width(80)
                .height(40)
                .borderRadius(10)
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  let tmpPlaylist: Playlist | undefined = undefined
                  let item = playlist.items.find(p => p.episodeId === this.item.id)
                  if (!item) {
                    tmpPlaylist = await addToPlaylist(playlist.id!, this.item.libraryItemId!, this.item.id)
                  } else {
                    tmpPlaylist = await removeFromPlaylist(playlist.id!, this.item.libraryItemId!, this.item.id)
                  }
                  if (tmpPlaylist) {
                    this.showPlaylists = false
                    playlist = tmpPlaylist
                  }
                })
              }
              .height(60)
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.divider')
        })
        .visibility(!this.showProgress ? Visibility.Visible : Visibility.None)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(72)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 80 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)

      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("新建播放列表")
            .fontSize(18)
        }
        .height(45)
        .width('100%')
        .borderRadius(10)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(async () => {
          if (this.showProgress) {
            this.getUIContext().getPromptAction().showToast({
              message: '正在加载播放列表！',
              duration: 500
            });
          } else {
            this.tmpPlaylistName = ""
            this.tmpPlaylistDescription = ""
            this.showPlaylists = false
            this.showCreatePlaylist = true
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 25 })
    }
  }

  @Builder
  createPlaylistBuilder() {
    Column() {
      TextInput({
        placeholder: "播放列表名称"
      })
        .width("100%")
        .height(45)
        .borderRadius(10)
        .margin({ bottom: 20 })
        .caretColor($r('sys.color.font_secondary'))
        .fontSize(18)
        .placeholderFont({
          size: 18
        })
        .type(InputType.Normal)
        .enterKeyType(EnterKeyType.Done)
        .onChange((value) => {
          this.tmpPlaylistName = value
        })

      TextArea({
        placeholder: "播放列表描述"
      })
        .width("100%")
        .height(120)
        .borderRadius(10)
        .margin({ bottom: 20 })
        .caretColor($r('sys.color.font_secondary'))
        .fontSize(18)
        .placeholderFont({
          size: 18
        })
        .type(TextAreaType.NORMAL)
        .enterKeyType(EnterKeyType.Done)
        .barState(BarState.Off)
        .onChange((value) => {
          this.tmpPlaylistDescription = value
        })

      Row({ space: 20 }) {
        Button({ type: ButtonType.Normal }) {
          Text("取消")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(() => {
          this.showCreatePlaylist = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("确认")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(10)
        .onClick(async () => {
          if (this.tmpPlaylistName.length === 0) {
            this.getUIContext().getPromptAction().showToast({
              message: '播放列表名称不能为空！',
              duration: 500
            });
          } else {
            let playlist: Playlist = {
              libraryId: this.library!.id,
              name: this.tmpPlaylistName,
              description: this.tmpPlaylistDescription.length > 0 ? this.tmpPlaylistDescription : null,
              items: [{
                libraryItemId: this.episode!.libraryItemId!,
                episodeId: this.episode!.id!,
                episode: this.episode
              }]
            }
            let newPlaylist = await createPlaylist(playlist)
            if (newPlaylist) {
              this.playlists.push(newPlaylist)
              this.showCreatePlaylist = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表失败，请检查网络！',
                duration: 500
              });
            }
          }
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
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

      Row({ space: 16 }) {
        Row() {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 38,
            onButtonClick: (): void => {
              this.playEpisodeItem()
            }
          }) {
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
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
                .margin({ bottom: 1 })
            }

            Text(this.formatDuration(this.item.duration!))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 5 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .padding({ left: 10, right: 10 })
          .clip(false)
        }
        }
        .clip(false)
        .layoutWeight(1)
        .height(38)
        .clip(false)

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: (): void => {
              this.toggleEpisodeProgress()
            }
          }) {
            Row() {
              SymbolGlyph(this.itemProgress?.isFinished ? $r('sys.symbol.checkmark_square_fill') :
                $r('sys.symbol.checkmark_square'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: (): void => {
              this.showPlaylists = true
            }
          }) {
            Row() {
              SymbolGlyph($r('sys.symbol.music_note_list'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)
        .bindSheet(this.showPlaylists, this.playlistsBuilder(), {
          height: SheetSize.MEDIUM,
          preferType: SheetType.CENTER,
          title: {
            title: "播放列表"
          },
          showClose: false,
          onWillAppear: async () => {
            this.showProgress = true
            this.playlists = await getPlaylists(this.library!.id)
            this.showProgress = false
          },
          onDisappear: () => {
            this.showPlaylists = false
          }
        })

        Row() {
          ImmersiveActionButton({
            barWidth: 38,
            barHeight: 38,
            onButtonClick: (): void => {
              this.requestEpisodeDownload()
            }
          }) {
            Row() {
              SymbolGlyph($r('sys.symbol.download'))
                .fontSize(18)
                .fontColor([$r('sys.color.font')])
                .clip(false)
                .hitTestBehavior(HitTestMode.None)
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .clip(false)
          }
        }
        .width(38)
        .height(38)
        .clip(false)
        .bindSheet(this.showConfirmDownload, this.confirmDownloadBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: SheetType.CENTER,
          title: {
            title: "确认下载"
          },
          showClose: false,
          onDisappear: () => {
            this.showConfirmDownload = false
          }
        })
      }
      .padding({
        top: 15, bottom: 20
      })
      .clip(false)
      .bindSheet(this.showCreatePlaylist, this.createPlaylistBuilder(), {
        height: SheetSize.FIT_CONTENT,
        preferType: SheetType.CENTER,
        title: {
          title: "新建播放列表"
        },
        showClose: false,
        onDisappear: () => {
          this.showCreatePlaylist = false
        }
      })

      Divider()
        .strokeWidth(1)
    }
    .margin({ top: 20 })
    .alignItems(HorizontalAlign.Start)
    .clip(false)
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

@CustomDialog
export struct reportBuilder {
  @State reason: string = ''
  @State description: string = ''
  @State showProgress: boolean = false
  reportDialog: CustomDialogController = new CustomDialogController({
    builder: reportBuilder({})
  })

  build() {
    Stack() {
      Column() {
        Text("举报内容")
          .width('100%')
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16, bottom: 15 })

        Row() {
          Text("举报原因")
            .fontSize(18)
          TextInput({
            placeholder: '请填写举报原因',
            text: $$this.reason
          })
            .width("100%")
            .height(40)
            .layoutWeight(1)
            .borderRadius(10)
            .margin({ left: 15 })
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({ size: 18 })
            .enterKeyType(EnterKeyType.Next)
        }
        .width('100%')
        .margin({ bottom: 20 })

        Row() {
          Text("详细描述")
            .fontSize(18)
            .margin({ top: 5 })
          TextArea({
            placeholder: '请描述具体情况（可选）',
            text: $$this.description
          })
            .width("100%")
            .height(120)
            .layoutWeight(1)
            .borderRadius(10)
            .margin({ left: 15 })
            .caretColor($r('sys.color.font_secondary'))
            .fontSize(18)
            .placeholderFont({ size: 18 })
            .enterKeyType(EnterKeyType.Next)
        }
        .width('100%')
        .margin({ bottom: 20 })
        .alignItems(VerticalAlign.Top)

        Row({ space: 20 }) {
          Button({ type: ButtonType.Normal }) {
            Text("取消")
              .fontSize(18)
          }
          .width('50%')
          .layoutWeight(1)
          .height(50)
          .borderRadius(10)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .onClick(() => {
            this.reportDialog.close()
          })

          Button({ type: ButtonType.Normal }) {
            Text("提交")
              .fontSize(18)
          }
          .width('50%')
          .layoutWeight(1)
          .height(50)
          .borderRadius(10)
          .backgroundColor($r('sys.color.comp_emphasize_secondary'))
          .onClick(async () => {
            if (!this.reason.trim()) {
              this.getUIContext().getPromptAction().showToast({
                message: '请填写举报原因！',
                duration: 800
              })
              return
            }

            this.showProgress = true
            let success = true
            this.showProgress = false

            if (success === true) {
              this.reportDialog.close()
              this.getUIContext().getPromptAction().showToast({
                message: '举报已提交，感谢反馈！',
                duration: 1000
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '提交失败，请检查网络！',
                duration: 1000
              });
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .padding({ left: 20, right: 20 })

      Column() {
        LoadingProgress()
          .width("100%")
          .height(72)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}
