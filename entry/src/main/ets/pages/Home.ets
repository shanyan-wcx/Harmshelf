import { ColorMode } from "./Index";
import { PersistenceV2, uiMaterial } from "@kit.ArkUI";
import { Author, Collection,
  Episode,
  HomeSection,
  Library, LibraryItem, Progress,
  Playlist,
  Series,
  User,
  SearchPodcast} from "../utils/Interface";
import { SubHome } from "./tabs/Home";
import { MediaLibrary } from "./tabs/Library";
import { AllSeries } from "./tabs/Series";
import { AllCollections } from "./tabs/Collection";
import { AllAuthors } from "./tabs/Author";
import { RecentEpisodes } from "./tabs/RecentEpisodes";
import { Add } from "./tabs/Add";
import {
  getAuthors,
  getCollections,
  getHome,
  getLibraries,
  getLibraryItems,
  getLogin,
  getPlaylists,
  getRecentEpisodes,
  getSeries,
  getUser} from "../utils/Api";
import { AllPlaylists } from "./tabs/Playlist";

export function getHomeTabLabels(mediaType: string | undefined, userType: string | undefined,
  hasPlaylists: boolean): string[] {
  let labels: string[] = mediaType === 'podcast' ? ['首页', '最新', '媒体库'] : ['首页', '媒体库', '系列'];
  if (userType === "root" || userType === "admin") {
    labels.push(mediaType === 'podcast' ? '添加' : '收藏');
  }
  if (mediaType !== 'podcast') {
    labels.push('作者');
  }
  if (hasPlaylists) {
    labels.push('播放列表');
  }
  return labels;
}

@ComponentV2
export struct HomeTopTabs {
  @Consumer() topTabIndex: number = 0
  @Consumer() library: Library | undefined = undefined
  @Consumer() user: User | undefined = undefined
  @Consumer() playlists: Playlist[] = []
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() displayWidth: number = 0
  @Consumer() needUpdate: boolean = false

  private tabLabels(): string[] {
    return getHomeTabLabels(this.library?.mediaType, this.user?.type, this.playlists.length > 0)
  }

  private homeTabContentWidth(): number {
    let width = this.sideBarContentWidth > 0 ? this.sideBarContentWidth : this.displayWidth
    return Math.max(width - 32, 1)
  }

  @Builder
  homeTabContents() {
    ForEach(this.tabLabels(), (label: string, index: number) => {
      TabContent() {
      }
      .tabBar(this.homeTabLabelBuilder(label, index))
    }, (label: string) => label)
  }

  @Builder
  homeTabLabelBuilder(label: string, index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .textAlign(TextAlign.Center)
        .fontSize(14)
        .fontColor(this.topTabIndex === index ?
          $r('sys.color.select_font_color') : $r('sys.color.font_secondary'))
        .fontWeight(this.topTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.None })
        .animation({ duration: 180, curve: Curve.Friction })

      Row()
        .width(20)
        .height(3)
        .borderRadius(1.5)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .opacity(this.topTabIndex === index ? 1 : 0)
        .translate({ x: 0, y: 11 })
        .animation({ duration: 280, curve: Curve.Friction })
    }
    .width('auto')
    .height(36)
    .clip(false)
    .padding({ left: 4, right: 4 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Tabs({ barPosition: BarPosition.End, index: this.topTabIndex }) {
        this.homeTabContents()
      }
      .width('100%')
      .height(36)
      .barWidth(this.homeTabContentWidth())
      .barOverlap(true)
      .vertical(false)
      .scrollable(false)
      .barMode(BarMode.Scrollable, {
        nonScrollableLayoutStyle: LayoutStyle.ALWAYS_AVERAGE_SPLIT
      })
      .barHeight('auto')
      .clip(false)
      .animationCurve(Curve.Friction)
      .animationDuration(280)
      .barBackgroundColor(Color.Transparent)
      .barFloatingStyle({
        barBottomMargin: 0,
        maskColor: Color.Transparent,
        maskHeight: 0,
        systemMaterial: new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
          applyShadow: true,
          interactive: true,
          lightEffect: { color: Color.White }
        })
      })
      .fadingEdge(true)
      .onChange((index: number) => {
        if (index !== this.topTabIndex) {
          this.topTabIndex = index
          this.needUpdate = !this.needUpdate
        }
      })
    }
    .width('100%')
    .height(36)
    .clip(false)
  }
}

@ComponentV2
export struct Home {
  @Provider() homeData: HomeSection[] = []
  @Provider() recentEpisodes: Episode[] = []
  @Provider() authors: Author[] = []
  @Consumer() searchPodcasts: SearchPodcast[] = []
  @Provider() recentEpisodesPage: number = 0
  @Consumer() term: string = ""
  @Consumer() user: User | undefined = undefined
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() playlists: Playlist[] = []
  @Consumer() collections: Collection[] = []
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() needUpdate: boolean = false
  @Consumer() statusBarHeight: number = 0
  @Consumer() sidebarType: number = SideBarContainerType.Overlay
  @Consumer() displayWidth: number = 0
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() selectLibraryIndex: number = 0
  @Consumer() topTabIndex: number = 0
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() firstAppear: boolean = false
  @Consumer() showAddServer: boolean = false
  @Consumer() libraries: Library[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() progress: Progress[] = []
  @Consumer() series: Series[] = []
  @Consumer() serverName: string = ""
  @Consumer() baseUrl: string = ""
  @Consumer() username: string = ""
  @Consumer() password: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() isConnect: boolean = false
  @Consumer() selectOptions: SelectOption[] = []

  private tabLabels(): string[] {
    return getHomeTabLabels(this.library?.mediaType, this.user?.type, this.playlists.length > 0)
  }

  private homeTabContentWidth(): number {
    let width = this.sideBarContentWidth > 0 ? this.sideBarContentWidth : this.displayWidth
    return Math.max(width - 32, 1)
  }

  @Monitor('needUpdate')
  async updateData(monitor: IMonitor) {
    this.showLoadingProgress = true
    if (this.firstAppear && this.baseUrl.length > 0) {
      //  登录
      let info = await getLogin({
        name: this.serverName,
        server: this.baseUrl,
        username: this.username,
        password: this.password
      })
      if (info !== null) {
        this.isConnect = true
        this.apiToken = info[0]
        this.libraries = await getLibraries()
        this.selectOptions = []
        if (this.libraries.length > 0) {
          this.library = this.library ? this.libraries.find(library => library.id === this.library!.id)??this.libraries[0] : this.libraries[0]
          this.libraries.forEach((library, index) => {
            this.selectOptions.push({ value: library.name })
          })
          this.selectLibraryIndex = this.libraries.findIndex(library => library.id === this.library!.id)
          if (this.selectLibraryIndex === -1) {
            this.selectLibraryIndex = 0
          }
        }
      }
      this.firstAppear = false
    }
    if (this.baseUrl !== "" && this.library) {
      this.searchPodcasts = []
      this.term = ""
      this.user = await getUser()
      this.progress = this.user?.mediaProgress??[]
      this.libraryItems = await getLibraryItems(this.library!.id)
      this.playlists = await getPlaylists(this.library.id)
      if (this.library.mediaType === 'book') {
        switch (this.topTabIndex) {
          case 0:
            this.homeData = await getHome(this.library.id)
            break;
          case 1:
            this.libraryItems = await getLibraryItems(this.library!.id)
            break;
          case 2:
            this.series = await getSeries(this.library.id)
            break;
          case 3:
            if (this.user?.type === "root" || this.user?.type === "admin") {
              this.collections = await getCollections(this.library.id)
            } else {
              this.authors = await getAuthors(this.library.id)
            }
            break;
          case 4:
            if (this.user?.type === "root" || this.user?.type === "admin") {
              this.authors = await getAuthors(this.library.id)
            }
            break;
          default :
            break;
        }
      } else if (this.library.mediaType === 'podcast') {
        switch (this.topTabIndex) {
          case 0:
            this.homeData = await getHome(this.library.id)
            break
          case 1:
            this.recentEpisodesPage = 0
            this.recentEpisodes = await getRecentEpisodes(this.library.id, this.recentEpisodesPage)
            break
          case 2:
            this.libraryItems = await getLibraryItems(this.library!.id)
            break;
          default :
            break;
        }
      }
    }
    this.showLoadingProgress = false
  }

  aboutToAppear() {
    this.needUpdate = !this.needUpdate
  }

  @Builder
  bookContentBuilder() {
    if (this.topTabIndex === 0) {
      SubHome()
    } else if (this.topTabIndex === 1) {
      MediaLibrary()
    } else if (this.topTabIndex === 2) {
      AllSeries()
    } else if ((this.user?.type === "root" || this.user?.type === "admin") && this.topTabIndex === 3) {
      AllCollections()
    } else if (this.topTabIndex === ((this.user?.type === "root" || this.user?.type === "admin") ? 4 : 3)) {
      AllAuthors()
    } else if (this.playlists.length > 0 && this.topTabIndex === this.tabLabels().length - 1) {
      AllPlaylists()
    }
  }

  @Builder
  podcastContentBuilder() {
    if (this.topTabIndex === 0) {
      SubHome()
    } else if (this.topTabIndex === 1) {
      RecentEpisodes()
    } else if (this.topTabIndex === 2) {
      MediaLibrary()
    } else if ((this.user?.type === "root" || this.user?.type === "admin") && this.topTabIndex === 3) {
      Add()
    } else if (this.playlists.length > 0 && this.topTabIndex === this.tabLabels().length - 1) {
      AllPlaylists()
    }
  }

  build() {
    Stack() {
      if (this.baseUrl !== "" && this.library) {
        if (this.library?.mediaType === 'book') {
          this.bookContentBuilder()
        } else if (this.library?.mediaType === 'podcast') {
          this.podcastContentBuilder()
        }
      } else {
        Column() {
          Text("没有服务器")
            .fontSize(32)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 92 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
      }

      // Row() {
      //   Text(this.LibraryItems.length.toString() + " 图书")
      //     .fontSize(16)
      //
      //   Row() {
      //
      //   }
      // }
      // .height(36)
      // .width('100%')
      // .padding({ left: 8, right: 8 })
      // .margin({ top: 36 })
      // .justifyContent(FlexAlign.SpaceBetween)
      // .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
      //   policy: BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE,
      //   inactiveColor: $r('sys.color.ohos_id_color_hover')
      // })
      // .shadow({
      //   offsetY: 2,
      //   radius: 8,
      //   color: $r('sys.color.font'),
      // })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Top)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .clip(false)
  }
}
