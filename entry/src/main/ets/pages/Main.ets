import { media } from '@kit.MediaKit';
import { router, promptAction, curves, window } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { getPixelMap, readConfig, writeConfig } from '../util/fs'
import {
  getLogout,
  getLibraries,
  getLibrarieItems,
  getProgress,
  getLibrarieItemsInProgress,
  getLibrarieItemsFinished,
  getAuthors,
  getSeries,
  closeSession,
  getStats,
  getBookmarks,
  getCover,
  getFeed,
  getRecentEpisodes,
  getCollections
} from '../api/Api'
import {
  Library,
  LibraryItem,
  Chapter,
  Progress,
  Track,
  Series,
  Author,
  PlayItem,
  UpdateSession,
  ListeningStats,
  Bookmark,
  SearchPodcast,
  Episode,
  Collection
} from '../api/Interface'
import library from './tabs/Library'
import home from './tabs/Home'
import author from './tabs/Author'
import series from './tabs/Series'
import collection from './tabs/Collection'
import Detail from './Detail'
import Play from './Play'
import Setting from './Setting'
import Stats from './Stats'
import SearchItems from './Search';
import add from './tabs/Add';
import newEpisode from './tabs/NewEpisode';
import Items from './Items';
import Loading from './Loading';

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;
let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
let libraries: Library[] = []

class RouTmp {
  server: string = ''
  username: string = ''
  apitoken: string = ''
  userId: string = ''
}

@Entry
@Component
export default struct main {
  @State statusBarHeight: number = 0;
  @State index: number = 0;
  @State pageIndex: number = 0;
  @Provide @Watch('changePage') PageIndexTransfer: number = this.pageIndex
  @Provide sidebarShow: boolean = false;
  @Provide @Watch('changePage') showProgressTransfer: boolean = false
  @State selectedLibrary: string = '';
  @Provide selectedLibraryId: string = '';
  @State selectedLibraryIndex: number = 0;
  @Provide selectedLibraryMediaType: string = ''
  @State shadowRadius: number = 0;
  @State isPlaying: boolean = true
  @Provide avPlayer: media.AVPlayer | null = null
  @Provide @Watch('changePage') isPlayingTransfer: boolean = this.isPlaying
  @State startPlaying: boolean = false
  @Provide showPlayTransfer: boolean = false;
  @Provide @Watch('changePage') startPlayingTransfer: boolean = this.startPlaying
  @Provide libraryItems: LibraryItem[] = []
  private controller: TabsController = new TabsController();
  private params: RouTmp = router.getParams() as RouTmp
  @Provide pageStack: NavPathStack = new NavPathStack()
  @Provide allProgress: Progress[] = []
  @Provide server: string = this.params.server
  @Provide playTitle: string = ''
  @Provide nowPlayingTracks: Track[] = []
  @Provide nowPlayingIndex: number = 0
  @Provide nowPlayingDuration: number = 0
  @Provide nowPlayedTime: number = 0
  @Provide nowPlayedProgress: number = 0
  @Provide nowTrackStartTime: number = 0
  @Provide libraryItemsInProgress: LibraryItem[] = []
  @Provide libraryItemsFinished: LibraryItem[] = []
  @Provide bookmarks: Bookmark[] = []
  @Provide nowPlayingBookmarks: Bookmark[] = []
  @Provide apitoken: string = this.params.apitoken
  @Provide userId: string = this.params.userId
  @Provide session: AVSessionManager.AVSession | null = null
  @Provide backPageIndex: number = 0
  @Provide sessionId: string = ''
  @Provide syncTime: number = 0
  @Provide startTime: number = 0
  @Provide speed: number = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @Provide speedNumber: number = 1
  @Provide sleepTime: number = 0
  @Provide @Watch('changeSetting') jumpTime: number = 10
  @Provide mainWindow: window.Window | null = null
  @Provide prepared: boolean = false
  @Provide searchTransfer: LibraryItem[] = []
  @Provide serverStatus: boolean = true
  @Provide podcasts: SearchPodcast[] = []
  @Provide searchPodcasts: boolean = false
  @Provide searchPodcastsValue: string = ''
  @Provide recentEpisodes: Episode[] = []
  @State searchValue: string = ''
  @State currentItem: LibraryItem = {
    id: '',
    ino: '',
    oldLibraryItemId: '',
    libraryId: '',
    folderId: '',
    path: '',
    relPath: '',
    isFile: false,
    mtimeMs: 0,
    ctimeMs: 0,
    birthtimeMs: 0,
    addedAt: 0,
    updatedAt: 0,
    isMissing: false,
    isInvalid: false,
    mediaType: '',
    media: {
      id: '',
      libraryItemId: '',
      metadata: {
        title: '',
        titleIgnorePrefix: '',
        subtitle: null,
        authorName: '',
        authorNameLF: '',
        narratorName: '',
        seriesName: '',
        genres: [],
        publishedYear: '',
        publishedDate: null,
        publisher: null,
        description: '',
        isbn: null,
        asin: null,
        language: '',
        explicit: false,
        abridged: false,
      },
      coverPath: '',
      tags: [],
      audioFiles: [],
      chapters: [],
      duration: 0,
      size: 0,
      tracks: [],
      ebookFile: null
    },
    numFiles: 0,
    size: 0
  }
  @Provide @Watch('changePage') itemTransfer: LibraryItem = this.currentItem
  @Provide nowPlayingItem: LibraryItem = this.currentItem
  @Provide nowPlayingChapters: Chapter[] = []
  @Provide authors: Author[] = []
  @Provide series: Series[] = []
  @Provide collections: Collection[] = []
  @Provide playItem: PlayItem | null = null
  @Provide isSeries: boolean = true
  @Provide seriesTransfer: Series = {
    id: '',
    name: '',
    nameIgnorePrefix: '',
    nameIgnorePrefixSort: '',
    type: '',
    books: [],
    addedAt: 0,
    totalDuration: 0
  }
  @Provide collectionTransfer: Collection = {
    id: '',
    libraryId: '',
    userId: '',
    name: '',
    description: '',
    books: [],
    lastUpdate: 0,
    createdAt: 0,
  }
  @Provide listeningStats: ListeningStats = {
    totalTime: 0,
    items: {},
    days: {},
    dayOfWeek: {},
    today: 0,
    recentSessions: []
  }
  uiContext: UIContext | undefined = undefined
  context: common.UIAbilityContext | undefined = undefined
  @Provide displayWidth: number = 0
  @Provide displayHeight: number = 0

  async changePage() {
    this.pageIndex = this.PageIndexTransfer
    this.startPlaying = this.startPlayingTransfer
    this.isPlaying = this.isPlayingTransfer
    this.currentItem = this.itemTransfer
  }

  async changeSetting() {
    let config = readConfig()
    config.jumpTime = this.jumpTime
    writeConfig(config)
    this.setSessionInfo()
  }

  async setSessionInfo() {
    let metadata: AVSessionManager.AVMetadata = {
      assetId: '0',
      title: this.nowPlayingChapters[this.nowPlayingIndex].title,
      mediaImage: getPixelMap(await getCover(this.nowPlayingItem.id)),
      duration: this.nowPlayingTracks[this.nowPlayingIndex].duration * 1000,
      artist: this.nowPlayingItem.media.metadata.authorName,
      skipIntervals: this.jumpTime === 10 ? AVSessionManager.SkipIntervals.SECONDS_10 :
      AVSessionManager.SkipIntervals.SECONDS_30,
    };
    this.session!.setAVMetadata(metadata).then(() => {
      console.info(`SetAVMetadata successfully`);
    }).catch((err: BusinessError) => {
      console.error(`Failed to set AVMetadata. Code: ${err.code}, message: ${err.message}`);
    });
  }

  async setPlaybackState(state: number, time: number) {
    let playbackState: AVSessionManager.AVPlaybackState = {
      state: state,
      position: {
        elapsedTime: time * 1000,
        updateTime: new Date().getTime(),
      },
      duration: this.nowPlayingTracks[this.nowPlayingIndex].duration * 1000,
      speed: this.speedNumber,
    };
    this.session!.setAVPlaybackState(playbackState, (err) => {
      if (err) {
        console.error(`设置Session状态失败，Code: ${err.code}, message: ${err.message}`);
      } else {
        console.info("设置Session状态", state);
      }
    });
  }

  async stopContinuousTask() {
    backgroundTaskManager.stopBackgroundRunning(context).then(() => {
      console.info(`停止长时任务。`);
    }).catch((err: BusinessError) => {
      console.error(`停止长时任务出错，代码 ${err.code}，错误信息 ${err.message}`);
    });
  }

  @Builder
  bindContentCoverBuilder() {
    Column() {
      Play()
    }
    .transition(TransitionEffect.translate({ y: 1000 }).animation({ curve: curves.springMotion(0.6, 1) }))
  }

  @Builder
  bindMenuBuilder(libraries: Library[]) {
    Menu() {
      ForEach(libraries, (library: Library, index) => {
        MenuItem({ content: library.name })
          .onClick(async () => {
            if (this.selectedLibraryIndex !== index) {
              this.selectedLibrary = library.name
              this.selectedLibraryId = library.id
              this.selectedLibraryIndex = index
              this.selectedLibraryMediaType = library.mediaType
              this.pageIndex = 0
              this.PageIndexTransfer = 0
              this.showProgressTransfer = true
              this.allProgress = []
              console.log("获取媒体库项目", this.selectedLibraryId)
              this.libraryItems = (await getLibrarieItems(this.selectedLibraryId)).reverse()
              await Promise.all(this.libraryItems.map(async (element) => {
                this.allProgress.push(await getProgress(element.id))
              }));
              this.libraryItemsFinished = await getLibrarieItemsFinished(this.selectedLibraryId)
              this.libraryItemsInProgress = (await getLibrarieItemsInProgress(this.selectedLibraryId)).sort((a, b) => {
                const progressA = this.allProgress.find(p => p.libraryItemId === a.id);
                const progressB = this.allProgress.find(p => p.libraryItemId === b.id);
                if (progressA && progressB) {
                  return progressB.lastUpdate - progressA.lastUpdate;
                }
                return 0;
              });
              this.series = await getSeries(this.selectedLibraryId)
              this.collections = await getCollections(this.selectedLibraryId)
              this.authors =
                (await getAuthors(this.selectedLibraryId)).sort((a, b) => a.name.localeCompare(b.name, 'zh'))
              if (library.mediaType === 'podcast') {
                this.recentEpisodes = await getRecentEpisodes(this.selectedLibraryId)
                for (let item of this.libraryItems) {
                  item.episodes = await getFeed(item.media.metadata.feedUrl!)
                }
              }
              this.showProgressTransfer = false
            }
          })
          .width('auto')
          .height('auto')
          .borderRadius(10)
      })
    }
    .radius(10)
  }

  @Builder
  titlebar() {
    Row() {
      Row() {
        Image($rawfile('logo.png'))
          .width(40)
          .height(40)
          .margin({ left: 15 })
          .visibility(this.pageIndex > 2 ? Visibility.None : Visibility.Visible)
        Button({ type: ButtonType.Normal }) {
          Image($rawfile('return.png'))
            .height(32)
            .width(32)
        }
        .borderRadius(5)
        .width(40)
        .height(40)
        .margin({ left: 15 })
        .backgroundColor('#00000000')
        .visibility(this.pageIndex > 2 ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          if (this.backPageIndex === this.pageIndex) {
            this.backPageIndex = 0
          }
          this.pageIndex = this.backPageIndex
          this.PageIndexTransfer = this.backPageIndex
          animateTo({
            duration: 300,
            curve: Curve.EaseOut,
          }, () => {
            this.sidebarShow = false
          })
        })

        Text(this.selectedLibrary)
          .width('auto')
          .height(32)
          .fontSize(16)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ left: 10 })
          .padding({ left: 10, right: 10 })
          .fontColor(Color.White)
          .borderRadius(5)
          .backgroundColor('#30cccccc')
          .bindMenu(this.bindMenuBuilder(libraries))
          .onClick(() => {
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })
      }
      .alignItems(VerticalAlign.Center)
      .height(40)

      Row() {
        TextInput({
          text: $$this.searchValue,
          placeholder: "搜索 ..."
        })
          .enterKeyType(EnterKeyType.Search)
          .caretColor('#95ffffff')
          .width('40%')
          .height(32)
          .margin({ right: 55 })
          .backgroundColor('#30cccccc')
          .fontColor('#95ffffff')
          .placeholderColor('#60ffffff')
          .onSubmit((value) => {
            if (this.searchValue === '') {
              promptAction.showToast({
                message: '搜索关键词不能为空',
                duration: 500
              });
            } else {
              this.searchTransfer = []
              this.libraryItems.forEach(element => {
                if (element.media.metadata.title.includes(this.searchValue)) {
                  this.searchTransfer.push(element)
                }
              })
              if (this.PageIndexTransfer !== 5) {
                this.backPageIndex = this.PageIndexTransfer
              }
              this.PageIndexTransfer = 5
            }
          })
          .onClick(() => {
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })
      }
      .alignItems(VerticalAlign.Center)
      .height(40)
    }
    .width("100%")
    .height('100%')
    .backgroundColor('#232323')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ top: 5, bottom: 10 })
  }

  @Builder
  TabBuilder(title: string, index: number, icon: Resource) {
    if (this.index === index) {
      Column() {
        Text(title)
          .fontSize(16)
          .width('100%')
          .height('100%')
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#232323')
      .onClick(() => {
        this.index = index;
        this.controller.changeIndex(index);
        animateTo({
          duration: 300,
          curve: Curve.EaseOut,
        }, () => {
          this.sidebarShow = false
        })
      })
    } else {
      Column() {
        Image(icon)
          .width(24)
          .height(24)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#2F3130')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.index = index;
        this.controller.changeIndex(index);
        animateTo({
          duration: 300,
          curve: Curve.EaseOut,
        }, () => {
          this.sidebarShow = false
        })
      })
    }
  }

  private getStatusBarHeight() {
    window.getLastWindow(getContext(this), (error, topWindow) => {
      if (topWindow) {
        let area = topWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = px2vp(area.topRect.height)
      }
    });
  }

  async aboutToAppear() {
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      console.warn("no uiContext");
      return;
    }
    this.context = this.uiContext.getHostContext() as common.UIAbilityContext;
    this.mainWindow = await window.getLastWindow(this.context)
    this.displayWidth = this.uiContext!.px2vp(this.mainWindow.getWindowProperties().windowRect.width)
    this.displayHeight= this.uiContext!.px2vp(this.mainWindow.getWindowProperties().windowRect.height)
    this.getStatusBarHeight()
    this.showProgressTransfer = true
    libraries = await getLibraries()
    this.selectedLibrary = libraries[0].name
    this.selectedLibraryId = libraries[0].id
    this.selectedLibraryIndex = 0
    this.selectedLibraryMediaType = libraries[0].mediaType
    this.avPlayer = await media.createAVPlayer();
    this.allProgress = []
    console.log("获取媒体库项目", this.selectedLibraryId)
    this.libraryItems = (await getLibrarieItems(this.selectedLibraryId)).reverse()
    await Promise.all(this.libraryItems.map(async (element) => {
      let progress = await getProgress(element.id)
      this.allProgress.push(progress)
    }));
    this.libraryItemsInProgress = (await getLibrarieItemsInProgress(this.selectedLibraryId)).sort((a, b) => {
      const progressA = this.allProgress.find(p => p.libraryItemId === a.id);
      const progressB = this.allProgress.find(p => p.libraryItemId === b.id);
      if (progressA && progressB) {
        return progressB.lastUpdate - progressA.lastUpdate;
      }
      return 0;
    });
    this.libraryItemsFinished = await getLibrarieItemsFinished(this.selectedLibraryId)
    this.series = await getSeries(this.selectedLibraryId)
    this.collections = await getCollections(this.selectedLibraryId)
    this.authors = (await getAuthors(this.selectedLibraryId)).sort((a, b) => a.name.localeCompare(b.name, 'zh'))
    if (this.selectedLibraryMediaType === 'podcast') {
      this.recentEpisodes = await getRecentEpisodes(this.selectedLibraryId)
      for (let item of this.libraryItems) {
        item.episodes = await getFeed(item.media.metadata.feedUrl!)
      }
    }
    this.bookmarks = await getBookmarks(this.userId)
    this.listeningStats = await getStats()
    let config = readConfig()
    this.jumpTime = config.jumpTime
    this.showProgressTransfer = false
  }

  async aboutToDisappear() {
    if (this.sessionId !== '') {
      let currentTime: number = 0
      for (let element of this.allProgress) {
        if (element.libraryItemId === this.nowPlayingItem.id) {
          currentTime = element.currentTime
          break
        }
      }
      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
      let updateSession: UpdateSession = {
        deviceInfo: {
          id: '00000000',
          userId: this.userId,
          deviceName: deviceInfo.productModel,
          clientName: 'Abs-HarmonyOS',
          clientVersion: bundleInfo.versionName
        },
        mediaPlayer: "avPlayer",
        currentTime: currentTime,
        timeListened: new Date().getTime() / 1000 - this.syncTime
      }
      console.log("会话当前时间", updateSession.currentTime)
      console.log("会话汇报间隔", updateSession.timeListened)
      await closeSession(this.sessionId, updateSession)
    }
    this.sleepTime = 0
    this.isPlayingTransfer = false
    this.showPlayTransfer = false
    this.startPlayingTransfer = false
    this.avPlayer!.stop()
    await this.session!.destroy()
    console.log("Session已销毁。")
  }

  onBackPress() {
    if (this.pageIndex > 2) {
      if (this.backPageIndex === this.pageIndex) {
        this.backPageIndex = 0
      }
      this.pageIndex = this.backPageIndex
      this.PageIndexTransfer = this.backPageIndex
      return true
    } else {
      return false
    }
  }

  onPageShow() {
    if (this.serverStatus === false) {
      promptAction.showToast({
        message: '连接服务器失败，请检查网络！',
        duration: 500
      });
    }
  }

  build() {
    Stack() {
      SideBarContainer(SideBarContainerType.Overlay) {
        Column() {
          Text("欢迎，" + this.params.username)
            .width("100%")
            .height(40)
            .fontSize(20)
            .textAlign(TextAlign.Start)
            .fontColor(Color.White)
            .margin({ left: 35, top: this.statusBarHeight + 7 })
          Row() {
            Image($rawfile("tabs/home.png"))
              .width(20)
              .height(20)
              .margin({ left: 20 })
            Text("首页")
              .width("auto")
              .height("30")
              .fontSize(20)
              .textAlign(TextAlign.Start)
              .fontColor(Color.White)
              .margin({ left: 15 })
          }
          .width("100%")
          .height(60)
          .margin({ top: 15 })
          .backgroundColor(this.pageIndex === 0 ? '#4F5052' : '#00000000')
          .onClick(() => {
            this.pageIndex = 0
            this.PageIndexTransfer = 0
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })

          Row() {
            Image($rawfile("tabs/home.png"))
              .width(20)
              .height(20)
              .margin({ left: 20 })
            Text("用户信息统计")
              .width("auto")
              .height("30")
              .fontSize(20)
              .textAlign(TextAlign.Start)
              .fontColor(Color.White)
              .margin({ left: 15 })
          }
          .width("100%")
          .height(60)
          .backgroundColor(this.pageIndex === 1 ? '#4F5052' : '#00000000')
          .onClick(() => {
            this.pageIndex = 1
            this.PageIndexTransfer = 1
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })

          Row() {
            Image($rawfile("tabs/home.png"))
              .width(20)
              .height(20)
              .margin({ left: 20 })
            Text("设置")
              .width("auto")
              .height("30")
              .fontSize(20)
              .textAlign(TextAlign.Start)
              .fontColor(Color.White)
              .margin({ left: 15 })
          }
          .width("100%")
          .height(60)
          .backgroundColor(this.pageIndex === 2 ? '#4F5052' : '#00000000')
          .onClick(() => {
            this.pageIndex = 2
            this.PageIndexTransfer = 2
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })

          Row() {
            Image($rawfile("tabs/home.png"))
              .width(20)
              .height(20)
              .margin({ left: 20 })
            Text("切换服务器/用户")
              .width("auto")
              .height("30")
              .fontSize(20)
              .textAlign(TextAlign.Start)
              .fontColor(Color.White)
              .margin({ left: 15 })
          }
          .width("100%")
          .height(60)
          .onClick(async () => {
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
            await getLogout()
            promptAction.showToast({
              message: '退出登录！',
              duration: 500
            });
            router.replaceUrl({
              url: 'pages/Login',
              params: {
                firstLogin: false
              }
            })
          })

          Column() {
            Row() {
              Text("项目地址")
                .fontSize(11)
                .fontColor(Color.Gray)
              Text('Harmshelf')
                .fontSize(11)
                .fontColor(Color.Gray)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .decoration({ type: TextDecorationType.Underline, color: Color.Gray })
                .onClick(() => {
                  animateTo({
                    duration: 300,
                    curve: Curve.EaseOut,
                  }, () => {
                    this.sidebarShow = false
                  })
                  let want: Want = {
                    action: 'ohos.want.action.viewData',
                    entities: ['entity.system.browsable'],
                    uri: 'https://github.com/shanyan-wcx/Harmshelf'
                  };
                  context.startAbility(want)
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            Row() {
              Text("隐私政策")
                .fontSize(11)
                .fontColor(Color.Gray)
              Text('https://privacy.shanyan.work')
                .fontSize(11)
                .fontColor(Color.Gray)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .decoration({ type: TextDecorationType.Underline, color: Color.Gray })
                .onClick(() => {
                  animateTo({
                    duration: 300,
                    curve: Curve.EaseOut,
                  }, () => {
                    this.sidebarShow = false
                  })
                  let want: Want = {
                    action: 'ohos.want.action.viewData',
                    entities: ['entity.system.browsable'],
                    uri: 'https://privacy.shanyan.work'
                  };
                  context.startAbility(want)
                })
            }
            .width('100%')
            .margin({ top: 10 })
            .justifyContent(FlexAlign.SpaceBetween)

            Row() {
              Text('v' + bundleInfo.versionName)
                .fontSize(11)
                .fontColor(Color.Gray)
              Text('浙ICP备2020037771号-3A')
                .fontSize(11)
                .fontColor(Color.Gray)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .margin({ top: 10 })
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .height('auto')
          .padding({ left: 20, right: 20 })
          .position({
            bottom: 25
          })
        }
        .width('100%')
        .height("100%")
        .backgroundColor("#383838")
        .shadow({
          radius: this.shadowRadius,
          color: '#95000000',
          offsetX: vp2px(-15),
          offsetY: vp2px(0)
        })

        Navigation(this.pageStack) {
          Stack() {
            Tabs({
              barPosition: BarPosition.Start,
              controller: this.controller
            }) {
              TabContent() {
                home({ libraryId: this.selectedLibraryId })
                  .backgroundImage($rawfile('background.jpg'))
                  .backgroundImageSize(ImageSize.Cover)
              }
              .width('100%')
              .height('100%')
              .tabBar(this.TabBuilder("首页", 0, $rawfile('tabs/home.png')))

              TabContent() {
                library({ libraryId: this.selectedLibraryId })
                  .backgroundImage($rawfile('background.jpg'))
                  .backgroundImageSize(ImageSize.Cover)
              }
              .width('100%')
              .height('100%')
              .tabBar(this.TabBuilder("媒体库", 1, $rawfile('tabs/library.png')))

              if (this.selectedLibraryMediaType === 'book') {
                TabContent() {
                  series({ libraryId: this.selectedLibraryId })
                }
                .width('100%')
                .height('100%')
                .backgroundImage($rawfile('background.jpg'))
                .backgroundImageSize(ImageSize.Cover)
                .tabBar(this.TabBuilder("系列", 2, $rawfile('tabs/series.png')))

                TabContent() {
                  collection({ libraryId: this.selectedLibraryId })
                }
                .width('100%')
                .height('100%')
                .backgroundImage($rawfile('background.jpg'))
                .backgroundImageSize(ImageSize.Cover)
                .tabBar(this.TabBuilder("收藏", 3, $rawfile('tabs/collections.png')))

                TabContent() {
                  author({ libraryId: this.selectedLibraryId })
                }
                .width('100%')
                .height('100%')
                .backgroundColor("#333333")
                .tabBar(this.TabBuilder("作者", 4, $rawfile('tabs/authors.png')))
              } else {
                TabContent() {
                  if (this.recentEpisodes.length > 0) {
                    newEpisode()
                  } else {
                    Column() {
                      Text("没有剧集")
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.White)
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                  }
                }
                .width('100%')
                .height('100%')
                .backgroundColor("#333333")
                .tabBar(this.TabBuilder("最新", 2, $rawfile('tabs/authors.png')))

                TabContent() {
                  add()
                }
                .width('100%')
                .height('100%')
                .backgroundColor("#333333")
                .tabBar(this.TabBuilder("增加", 3, $rawfile('tabs/authors.png')))
              }
            }
            .width("100%")
            .height('100%')
            .barHeight(40)
            .onChange((index: number) => {
              this.index = index
              this.searchPodcasts = false
              this.podcasts = []
              this.searchPodcastsValue = ''
            })
            .visibility(this.pageIndex === 0 ? Visibility.Visible : Visibility.None)

            Column() {
              Stats()
            }
            .backgroundColor("#333333")
            .width("100%")
            .height('100%')
            .visibility(this.pageIndex === 1 ? Visibility.Visible : Visibility.None)

            Column() {
              Setting()
            }
            .backgroundColor("#333333")
            .width("100%")
            .height('100%')
            .visibility(this.pageIndex === 2 ? Visibility.Visible : Visibility.None)

            Column() {
              Detail()
            }
            .backgroundColor("#333333")
            .width("100%")
            .height('100%')
            .visibility(this.pageIndex === 3 ? Visibility.Visible : Visibility.None)

            Column() {
              Items()
            }
            .backgroundImage($rawfile('background.jpg'))
            .backgroundImageSize(ImageSize.Cover)
            .width("100%")
            .height('100%')
            .visibility(this.pageIndex === 4 ? Visibility.Visible : Visibility.None)

            Column() {
              SearchItems()
            }
            .backgroundImage($rawfile('background.jpg'))
            .backgroundImageSize(ImageSize.Cover)
            .width("100%")
            .height('100%')
            .visibility(this.pageIndex === 5 ? Visibility.Visible : Visibility.None)

            Loading()

            Column()
              .width('100%')
              .height(5)
              .shadow({
                offsetX: 0,
                offsetY: 12,
                radius: 10,
                color: '#95000000'
              })
              .position({
                y: -5
              })

            Row() {
              Image(this.server + `/api/items/${this.nowPlayingItem.id}/cover?format=jpeg&width=1024` +
                `&token=${this.apitoken}`)
                .alt($rawfile('nocover.jpg'))
                .width(60)
                .aspectRatio(1)
                .borderRadius(10)
                .objectFit(ImageFit.Fill)
                .margin({ left: 15, right: 10, bottom: 10 })
              Column() {
                Marquee({
                  start: true,
                  step: 3,
                  src: this.playTitle
                })
                  .fontColor(Color.White)
                  .fontSize(18)
                  .width('auto')
                Text(this.nowPlayingItem.media.metadata.authorName)
                  .fontColor(Color.White)
                  .fontSize(16)
                  .width('auto')
                  .margin({ top: 5 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .margin({ bottom: 15 })
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .layoutWeight(1)

              Blank()
                .margin({ bottom: 10 })

              Button({ type: ButtonType.Circle }) {
                Image(this.jumpTime === 10 ? $rawfile('rewind_10.png') : $rawfile('rewind_30.png'))
                  .width(30)
                  .height(30)
              }
              .width(40)
              .height(40)
              .margin({ right: 5, bottom: 10 })
              .backgroundColor('#00000000')
              .onClick(() => {
                if (this.nowPlayedTime - this.jumpTime < 0) {
                  this.nowPlayedTime = 0
                } else {
                  this.nowPlayedTime -= this.jumpTime
                }
                this.nowPlayedProgress = this.nowPlayedTime / this.nowPlayingDuration * 100
                this.avPlayer!.seek(this.nowPlayedTime * 1000)
                this.isPlayingTransfer === true ?
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.nowPlayedTime) :
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.nowPlayedTime)
              })

              Button({ type: ButtonType.Circle }) {
                Image(this.isPlaying === true ? $rawfile('suspend.png') : $rawfile('play.png'))
                  .width(30)
                  .height(30)
              }
              .width(50)
              .height(50)
              .margin({ right: 5, bottom: 10 })
              .backgroundColor('#383838')
              .onClick(() => {
                this.isPlaying = !this.isPlaying
                this.isPlayingTransfer = this.isPlaying
                if (this.isPlaying === false) {
                  this.avPlayer!.pause()
                } else {
                  this.avPlayer!.play()
                }
                this.isPlayingTransfer === true ?
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.nowPlayedTime) :
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.nowPlayedTime)
              })

              Button({ type: ButtonType.Circle }) {
                Image(this.jumpTime === 10 ? $rawfile('forward_10.png') : $rawfile('forward_30.png'))
                  .width(30)
                  .height(30)
              }
              .width(40)
              .height(40)
              .margin({ right: 5, bottom: 10 })
              .backgroundColor('#00000000')
              .onClick(() => {
                if (this.nowPlayedTime + this.jumpTime > this.nowPlayingDuration) {
                  this.nowPlayedTime = this.nowPlayingDuration
                } else {
                  this.nowPlayedTime += this.jumpTime
                }
                this.nowPlayedProgress = this.nowPlayedTime / this.nowPlayingDuration * 100
                this.avPlayer!.seek(this.nowPlayedTime * 1000)
                this.isPlayingTransfer === true ?
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.nowPlayedTime) :
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.nowPlayedTime)
              })
            }
            .width('100%')
            .height(90)
            .backgroundColor('#232323')
            .position({
              bottom: 0
            })
            .shadow({
              offsetX: 0,
              offsetY: -12,
              radius: 10,
              color: '#95000000'
            })
            .bindContentCover(this.showPlayTransfer, this.bindContentCoverBuilder(), {
              modalTransition: ModalTransition.NONE,
            })
            .onClick(() => {
              if (this.showPlayTransfer === true) {
                this.showPlayTransfer = false
              }
              this.showPlayTransfer = true;
              animateTo({
                duration: 300,
                curve: Curve.EaseOut,
              }, () => {
                this.sidebarShow = false
              })
            })
            .visibility(this.startPlayingTransfer === true ? Visibility.Visible : Visibility.Hidden)
            .transition(TransitionEffect.translate({ y: 100 }).animation({ curve: curves.springMotion(0.6, 1) }))
          }
        }
        .mode(NavigationMode.Stack)
        .padding({ top: this.statusBarHeight })
        .title(this.titlebar())
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(true)
        .backgroundColor('#232323')
        .onClick(() => {
          animateTo({
            duration: 300,
            curve: Curve.EaseOut,
          }, () => {
            this.sidebarShow = false
          })
        })
      }
      .width("100%")
      .height('100%')
      .showSideBar(this.sidebarShow)
      .controlButton({
        top: this.statusBarHeight + 13,
        width: 26,
        height: 26,
        icons: {
          shown: $rawfile('sidebar.png'),
          hidden: $rawfile('sidebar.png')
        }
      })
      .sideBarPosition(SideBarPosition.End)
      .onChange((show: boolean) => {
        if (show === true) {
          this.shadowRadius = 50
          this.sidebarShow = true
        } else {
          setTimeout(() => {
            this.shadowRadius = 0
            this.sidebarShow = false
          }, 300)
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}