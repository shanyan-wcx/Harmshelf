import { HdsTabs, HdsTabsController, HdsTabsAttribute } from "@kit.UIDesignKit"
import { ColorMode } from "./Index";
import { PersistenceV2 } from "@kit.ArkUI";
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
  getProgress,
  getRecentEpisodes,
  getSeries,
  getUser} from "../utils/Api";
import { AllPlaylists } from "./tabs/Playlist";

@ComponentV2
export struct Home {
  private tabsController: HdsTabsController = new HdsTabsController()
  @Provider() homeData: HomeSection[] = []
  @Provider() recentEpisodes: Episode[] = []
  @Provider() collections: Collection[] = []
  @Provider() authors: Author[] = []
  @Provider() searchPodcasts: SearchPodcast[] = []
  @Provider() recentEpisodesPage: number = 0
  @Consumer() user: User | undefined = undefined
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() playlists: Playlist[] = []
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() needUpdate: boolean = false
  @Consumer() statusBarHeight: number = 0
  @Consumer() sidebarType: number = SideBarContainerType.Overlay
  @Consumer() displayWidth: number = 0
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() isOnFocus: boolean = true
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
            this.collections = await getCollections(this.library.id)
            break;
          case 4:
            this.authors = await getAuthors(this.library.id)
            break;
          case 5:
            this.playlists = await getPlaylists(this.library.id)
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
          case 3:
            this.searchPodcasts = []
            break
          case 4:
            this.playlists = await getPlaylists(this.library.id)
            break
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

  build() {
    Stack() {
      if (this.baseUrl !== "" && this.library) {
        if (this.library?.mediaType === 'book') {
          HdsTabs({ controller: this.tabsController, index: this.topTabIndex }) {
            TabContent() {
              SubHome()
            }
            .tabBar(new SubTabBarStyle('首页')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 0 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              MediaLibrary()
            }
            .tabBar(new SubTabBarStyle('媒体库')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 1 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              AllSeries()
            }
            .tabBar(new SubTabBarStyle('系列')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 2 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              AllCollections()
            }
            .tabBar(new SubTabBarStyle('收藏')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 3 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              AllAuthors()
            }
            .tabBar(new SubTabBarStyle('作者')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 4 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            if (this.playlists.length > 0) {
              TabContent() {
                AllPlaylists()
              }
              .tabBar(new SubTabBarStyle('播放列表')
                .selectedMode(SelectedMode.BOARD)
                .padding(0)
                .board({
                  borderRadius: 5
                })
                .labelStyle({
                  font: {
                    size: 14,
                    weight: this.topTabIndex === 4 ? FontWeight.Bold : FontWeight.Medium
                  },
                  selectedColor: $r('sys.color.select_font_color')
                })
                .indicator({
                  color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
                }))
            }
          }
          .barOverlap(true)
          .barPosition(BarPosition.Start)
          .vertical(false)
          .animationDuration(0)
          .scrollable(false)
          .barHeight(36)
          .barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
            policy: BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE,
            inactiveColor: $r('sys.color.ohos_id_color_hover')
          })
          .onTabBarClick((index: number) => {
            this.topTabIndex = index
            this.needUpdate = !this.needUpdate
          })
        } else if (this.library?.mediaType === 'podcast') {
          HdsTabs({ controller: this.tabsController, index: this.topTabIndex }) {
            TabContent() {
              SubHome()
            }
            .tabBar(new SubTabBarStyle('首页')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 0 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              RecentEpisodes()
            }
            .tabBar(new SubTabBarStyle('最新')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 1 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              MediaLibrary()
            }
            .tabBar(new SubTabBarStyle('媒体库')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 2 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            TabContent() {
              Add()
            }
            .tabBar(new SubTabBarStyle('添加')
              .selectedMode(SelectedMode.BOARD)
              .padding(0)
              .board({
                borderRadius: 5
              })
              .labelStyle({
                font: {
                  size: 14,
                  weight: this.topTabIndex === 3 ? FontWeight.Bold : FontWeight.Medium
                },
                selectedColor: $r('sys.color.select_font_color')
              })
              .indicator({
                color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
              }))

            if (this.playlists.length > 0) {
              TabContent() {
                AllPlaylists()
              }
              .tabBar(new SubTabBarStyle('播放列表')
                .selectedMode(SelectedMode.BOARD)
                .padding(0)
                .board({
                  borderRadius: 5
                })
                .labelStyle({
                  font: {
                    size: 14,
                    weight: this.topTabIndex === 4 ? FontWeight.Bold : FontWeight.Medium
                  },
                  selectedColor: $r('sys.color.select_font_color')
                })
                .indicator({
                  color: this.isOnFocus ? $r('sys.color.comp_emphasize_secondary') : $r('sys.color.ohos_id_color_hover')
                }))
            }
          }
          .barOverlap(true)
          .barPosition(BarPosition.Start)
          .vertical(false)
          .animationDuration(0)
          .scrollable(false)
          .barHeight(36)
          .barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK, {
            policy: BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE,
            inactiveColor: $r('sys.color.ohos_id_color_hover')
          })
          .onTabBarClick((index: number) => {
            this.topTabIndex = index
            this.needUpdate = !this.needUpdate
          })
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
    .alignContent(Alignment.Top)
    .margin({ top: 56 })
  }
}