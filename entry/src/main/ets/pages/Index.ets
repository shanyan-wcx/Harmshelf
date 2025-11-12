import app from '@system.app';
import { HdsSideBar, HdsSideMenu, HdsSideMenuMainItem } from '@kit.UIDesignKit';
import { common, ConfigurationConstant, WantAgent, wantAgent } from '@kit.AbilityKit';
import { PersistenceV2, SymbolGlyphModifier, Type, window } from '@kit.ArkUI';
import { MyNavigation } from '../utils/Component';
import {
  Episode,
  Library,
  LibraryItem,
  PlayItem,
  SearchResult,
  Series,
  Progress,
  LoginInfo,
  User,
  Bookmark,
  UpdateSession,
  Playlist,
  Collection
} from '../utils/Interface';
import { Play } from './Play';
import { deviceInfo } from '@kit.BasicServicesKit';
import { avSession } from '@kit.AVSessionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { audio } from '@kit.AudioKit';
import { CountdownTimer } from '../utils/Class';
import { getUser, syncSession } from '../utils/Api';
import { bundleManager } from '@kit.AbilityKit';

let deviceTypeInfo: string = deviceInfo.deviceType;

@ObservedV2
export class LoginInfoType {
  @Trace name: string = ''
  @Trace server: string = ''
  @Trace username: string = ''
  @Trace password: string = ''
}

@ObservedV2
export class ServerIndex {
  @Trace serverIndex: number = -1
}


@ObservedV2
export class ServerSetting {
  @Trace @Type(LoginInfoType) loginInfos: LoginInfo[] = []
}

@ObservedV2
export class ColorMode {
  @Trace colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
}

@ObservedV2
export class PlaySetting {
  @Trace fadeInOut: boolean = false
  @Trace skipIntervals: number = 10
}

@Entry
@ComponentV2
struct Index {
  @Provider() serverIndex: ServerIndex | undefined = PersistenceV2.connect(ServerIndex, () => new ServerIndex());
  @Provider() serverSetting: ServerSetting | undefined = PersistenceV2.connect(ServerSetting, () => new ServerSetting());
  @Provider() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Provider() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Provider() displayWidth: number = 0
  @Provider() displayHeight: number = 0
  @Provider() selectThemeIndex: number = 0
  @Provider() isOnFocus: boolean = true
  @Provider() themeIcon: Resource = $r('sys.symbol.circle_righthalf_inset_filled')
  @Provider() pageInfos: NavPathStack = new NavPathStack();
  @Provider() statusBarHeight: number = 0;
  @Provider() context: common.UIAbilityContext | undefined = undefined
  @Provider() sideBarWidth: number = 240
  @Provider() sidebarType: number = deviceTypeInfo === '2in1' ? SideBarContainerType.Embed : SideBarContainerType.Overlay
  @Provider() pageIndex: number = 0;
  @Provider() isIndex: boolean = true
  @Provider() selectLibraryIndex: number = 0
  @Provider() topTabIndex: number = 0
  @Provider() needUpdate: boolean = false
  @Provider() sideBarContentWidth: number = 0
  @Provider() user: User | undefined = undefined
  @Provider() series: Series[] = []
  @Provider() progress: Progress[] = []
  @Provider() libraries: Library[] = []
  @Provider() playlists: Playlist[] = []
  @Provider() library: Library | undefined = undefined
  @Provider() libraryItems: LibraryItem[] = []
  @Provider() libraryItem: LibraryItem | undefined = undefined
  @Provider() bookmarks: Bookmark[] = []
  @Provider() series1: Series | undefined = undefined
  @Provider() collection1: Collection | undefined = undefined
  @Provider() playlist1: Playlist | undefined = undefined
  @Provider() episode: Episode | undefined = undefined
  @Provider() searchResult: SearchResult | undefined = undefined
  @Provider() showLoadingProgress: boolean = false
  @Provider() firstAppear: boolean = false
  @Provider() serverName: string =
    this.serverSetting && this.serverSetting?.loginInfos.length > 0 && this.serverIndex?.serverIndex !== -1 ?
      this.serverSetting?.loginInfos[this.serverIndex?.serverIndex!].name : ""
  @Provider() baseUrl: string =
    this.serverSetting && this.serverSetting?.loginInfos.length > 0 && this.serverIndex?.serverIndex !== -1 ?
      this.serverSetting?.loginInfos[this.serverIndex?.serverIndex!].server : ""
  @Provider() username: string =
    this.serverSetting && this.serverSetting?.loginInfos.length > 0 && this.serverIndex?.serverIndex !== -1 ?
      this.serverSetting?.loginInfos[this.serverIndex?.serverIndex!].username : ""
  @Provider() password: string =
    this.serverSetting && this.serverSetting?.loginInfos.length > 0 && this.serverIndex?.serverIndex !== -1 ?
      this.serverSetting?.loginInfos[this.serverIndex?.serverIndex!].password : ""
  @Provider() apiToken: string = ""
  @Provider() selectOptions: SelectOption[] = []
  @Provider() isConnect: boolean = false
  @Provider() isShowSidebar: boolean = deviceTypeInfo === '2in1' ? true : false
  @Provider() isStartPlaying: boolean = false
  @Provider() isPlaying: boolean = false
  @Provider() showPlay: boolean = false
  @Provider() playingItem: PlayItem | undefined = undefined
  @Provider() playingTitle: string = "-"
  @Provider() playingIndex: number = 0
  @Provider() showAddServer: boolean = false
  @Provider() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Provider() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Provider() statsScroller: Scroller = new Scroller()
  @Provider() LocalMediaScroller: Scroller = new Scroller()
  @Provider() playStartTime: number = 0
  @Provider() playedTime: number = 0
  @Provider() playedPercent: number = 0
  @Provider() avPlayer: media.AVPlayer | undefined = undefined
  @Provider() session: avSession.AVSession | undefined = undefined
  @Provider() sleepTime: number = 0
  @Provider() sliderMoving: boolean = false
  @Provider() sleepController: CountdownTimer | undefined = undefined
  @Provider() syncTime: number = 0
  @Local uiContext: UIContext | undefined = undefined
  @Local mainWindow: window.Window | undefined = undefined
  @Local elapsedTime: number = 0
  @Local isSyncing: boolean = false
  pages?: HdsSideMenuMainItem[] = [
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.house')),
      label: '首页',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.arrow_counterclockwise_clock')),
      label: '统计',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.folder')),
      label: '本地',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.doc_text')),
      label: '日志',
    }),
    new HdsSideMenuMainItem({
      symbol: new SymbolGlyphModifier($r('sys.symbol.slider_vertical_3')),
      label: '设置',
    }),
  ]

  registerInterception() {
    this.pageInfos.setInterception({
      willShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
        operation: NavigationOperation, animated: boolean) => {
        if (typeof to === "string") {
          this.isIndex = true
        } else {
          this.isIndex = false
        }
      }
    })
  }

  private getStatusBarHeight() {
    window.getLastWindow(this.context, (error, topWindow) => {
      if (topWindow) {
        let area = topWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = this.uiContext!.px2vp(area.topRect.height)
      }
    });
  }

  fadeIn() {
    this.isPlaying = true
    let duration = 1000
    let volume = 0;
    const step = 50; // 调整间隔时间，单位 ms
    const increment = step / duration; // 每次增加的音量比例
    this.avPlayer!.setVolume(volume);
    this.avPlayer!.play();
    const interval = setInterval(() => {
      volume += increment;
      if (volume >= 1.0) {
        this.avPlayer!.setVolume(1.0);
        clearInterval(interval);
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
  }

  fadeOut() {
    this.isPlaying = false
    let duration = 1000
    let volume = 1.0; // 假设当前音量是最大值
    const step = 50; // 调整间隔时间，单位 ms
    const decrement = step / duration; // 每次减少的音量比例
    const interval = setInterval(() => {
      volume -= decrement;
      if (volume <= 0.0) {
        this.avPlayer!.setVolume(0.0);
        clearInterval(interval);
        this.avPlayer!.pause(); // 在音量完全降为 0 后暂停
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
  }

  async syncProgress() {
    if (!this.isSyncing) {
      this.isSyncing = true
      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
      let updateSession: UpdateSession = {
        deviceInfo: {
          id: deviceInfo.displayVersion,
          userId: this.playingItem!.userId,
          deviceName: deviceInfo.marketName,
          clientName: "Harmshelf",
          clientVersion: bundleInfo.versionName
        },
        mediaPlayer: "avPlayer",
        currentTime: this.playingItem!.audioTracks[this.playingIndex].startOffset + this.playedTime,
        timeListened: new Date().getTime() / 1000 - this.syncTime
      }
      for (let element of this.progress) {
        if (this.playingItem!.mediaType === 'book' ? element.libraryItemId === this.playingItem!.libraryItemId : element.episodeId === this.playingItem!.episodeId) {
          element.duration = this.playingItem!.duration
          element.currentTime = this.playingItem!.audioTracks[this.playingIndex].startOffset + this.playedTime
          element.progress = element.currentTime / (Math.trunc(element.duration * 1000) / 1000)
          element.isFinished = element.progress >= 1 ? true : false
          break
        }
      }
      let status = await syncSession(this.playingItem!.id, updateSession)
      if (status) {
        this.isConnect = true
        console.log("会话当前时间", updateSession.currentTime)
        console.log("会话汇报间隔", updateSession.timeListened)
        this.syncTime = new Date().getTime() / 1000
        this.user = await getUser()
        this.progress = this.user?.mediaProgress??[]
      } else {
        this.isConnect = false
        this.getUIContext().getPromptAction().showToast({
          message: '同步进度失败，请检查网络！',
          duration: 500
        });
      }
      this.elapsedTime = 0
      this.isSyncing = false
    }
  }

  async startContinuousTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: "com.shanyan.harmshelf",
          abilityName: "EntryAbility"
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
      backgroundTaskManager.startBackgroundRunning(this.context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, wantAgentObj).then(() => {
        console.info(`启动长时任务。`);
      }).catch((err: BusinessError) => {
        console.error(`启动长时任务出错，代码 ${err.code}，错误信息 ${err.message}`);
      });
    });
  }

  async stopContinuousTask() {
    backgroundTaskManager.stopBackgroundRunning(this.context).then(() => {
      console.info(`停止长时任务。`);
    }).catch((err: BusinessError) => {
      console.error(`停止长时任务出错，代码 ${err.code}，错误信息 ${err.message}`);
    });
  }

  async setSessionInfo() {
    let metadata: avSession.AVMetadata = {
      assetId: this.playingIndex.toString(),
      title: this.playingTitle,
      subtitle: this.playingItem!.displayAuthor,
      duration: this.playingItem!.audioTracks[this.playingIndex].duration * 1000,
      mediaImage: this.baseUrl + `/api/items/${this.playingItem!.libraryItemId}/cover?token=${this.apiToken}`,
      skipIntervals: this.playSetting!.skipIntervals
    };
    this.session!.setAVMetadata(metadata).then(() => {
      console.info(`SetAVMetadata successfully`);
    }).catch((err: BusinessError) => {
      console.error(`Failed to set AVMetadata. Code: ${err.code}, message: ${err.message}`);
    });
  }

  async setPlaybackState(state: number) {
    let playbackState: avSession.AVPlaybackState = {
      state: state,
      position: {
        elapsedTime: this.playedTime * 1000,
        updateTime: new Date().getTime(),
      }
    };
    this.session!.setAVPlaybackState(playbackState, (err) => {
      if (err) {
        console.error(`设置Session状态失败，Code: ${err.code}, message: ${err.message}`);
      } else {
        console.info("设置Session状态", state);
      }
    });
  }

  async setSessionCallback() {
    this.session!.on('play', () => {
      if (this.playSetting?.fadeInOut) {
        this.fadeIn()
      } else {
        this.avPlayer!.play()
      }
    });
    this.session!.on('pause', () => {
      if (this.playSetting?.fadeInOut) {
        this.fadeOut()
      } else {
        this.avPlayer!.pause()
      }
    });
    this.session!.on('stop', async () => {
      this.avPlayer!.stop()
    });
    this.session!.on('seek', async (time: number) => {
      await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_BUFFERING)
      this.avPlayer!.seek(time)
    });
    this.session!.on('rewind', () => {
      this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
    })
    this.session!.on('fastForward', () => {
      this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < this.playingItem!.audioTracks[this.playingIndex].duration ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : this.playingItem!.audioTracks[this.playingIndex].duration * 1000)
    })
    if (this.playingIndex > 0) {
      this.session!.on('playPrevious', async () => {
        await this.avPlayer!.reset();
        this.playingIndex--
        this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
        this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
      });
    } else {
      this.session!.off('playPrevious')
    }
    if (this.playingIndex < this.playingItem!.audioTracks.length - 1) {
      this.session!.on('playNext', async () => {
        await this.avPlayer!.reset();
        this.playingIndex++
        this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
        this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
      });
    } else {
      this.session!.off('playNext');
    }
    this.session!.off('setLoopMode');
    this.session!.off('toggleFavorite');
    this.session!.off('setSpeed');
  }

  setAVPlayerCallback(avPlayer: media.AVPlayer) {
    avPlayer.on('timeUpdate', async (time: number) => {
      this.elapsedTime += 100
      this.playedTime = time / 1000
      if (this.sliderMoving === false) {
        this.playedPercent = this.playedTime / this.playingItem!.audioTracks[this.playingIndex].duration * 100
      }
      if (this.elapsedTime >= 10000) {
        this.syncProgress()
      }
    })
    avPlayer.on('seekDone', async (seekDoneTime: number) => {
      console.info(`播放器跳转成功，当前时间为 ${seekDoneTime}`);
      this.playedTime = seekDoneTime / 1000
      if (this.isPlaying === true) {
        await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
      } else {
        await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
      }
      this.sliderMoving = false
      this.syncProgress()
    })
    avPlayer.on('speedDone', (data: number) => {
      switch(data) {
        case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
          console.info("设置速度 " + 0.5);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
          console.info("设置速度 " + 0.75);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
          console.info("设置速度 " + 1);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
          console.info("设置速度 " + 1.25);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
          console.info("设置速度 " + 1.5);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
          console.info("设置速度 " + 1.75);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
          console.info("设置速度 " + 2);
          break;
        default :
          console.info("设置速度 未知");
          break;
      }
    })
    avPlayer.on('volumeChange', (vol: number) => {
      console.info('设置播放音量' + vol)
    })
    avPlayer.on('error', async (err: BusinessError) => {
      await avPlayer.reset();
      console.error(`播放器出现错误，code is ${err.code}, message is ${err.message}`);
      if (err.code === 5400106 || err.code === 5400103 || err.code === 5411007) {
        this.uiContext!.getPromptAction().showToast({
          message: '播放失败，格式不支持或文件不存在！',
          duration: 500
        });
      } else if (err.code === 5400104 || err.code === 5411002 || err.code === 5411004) {
        this.uiContext!.getPromptAction().showToast({
          message: '播放失败，请检查网络连接！',
          duration: 500
        });
      } else {
        this.uiContext!.getPromptAction().showToast({
          message: '播放失败，未知错误！',
          duration: 500
        });
      }
    })
    avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'idle':
          console.info('播放器重置。');
          this.stopContinuousTask()
          this.playedTime = 0
          break;
        case 'initialized':
          console.info('播放器初始化。');
          avPlayer.prepare();
          break;
        case 'prepared':
          console.info('播放器就绪。');
          this.playedTime = 0
          if (this.session === undefined) {
            this.session = await avSession.createAVSession(this.context!, 'AUDIO_PLAY', 'video');
            await this.setSessionCallback()
            await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_INITIAL)
          }
          await this.session!.activate()
          await this.setSessionInfo()
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PREPARE)
          if (this.playStartTime !== 0) {
            this.avPlayer!.seek(this.playStartTime * 1000)
            this.playStartTime = 0
          }
          if (this.isPlaying === true) {
            if (this.playSetting?.fadeInOut) {
              this.fadeIn()
            } else {
              this.avPlayer!.play()
            }
          } else {
            if (this.playSetting?.fadeInOut) {
              this.fadeOut()
            } else {
              this.avPlayer!.pause()
            }
          }
          this.elapsedTime = 10000
          this.syncTime = new Date().getTime() / 1000
          break;
        case 'playing':
          console.info('播放器开始播放。');
          this.isPlaying = true
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
          this.startContinuousTask()
          this.sleepController?.start()
          break;
        case 'paused':
          console.info('播放器暂停。');
          this.isPlaying = false
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
          this.stopContinuousTask()
          this.sleepController?.pause()
          break;
        case 'completed':
          console.info('播放完毕。');
          this.syncProgress()
          if (this.playingIndex < this.playingItem!.audioTracks.length - 1) {
            await this.avPlayer!.reset()
            this.playingIndex++
            this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
          } else {
            this.isPlaying = false
          }
          break;
        case 'stopped':
          console.info('播放器停止。');
          this.syncProgress()
          this.showPlay = false
          await this.session!.destroy()
          this.session = undefined
          await avPlayer.reset();
          this.playedTime = 0
          this.playedPercent = 0
          this.sleepTime = 0
          this.sleepController?.clear()
          setTimeout(() => {
            this.isStartPlaying = false
            this.isPlaying = false
          }, 100)
          break;
        case 'released':
          console.info('播放器释放。');
          break;
        default:
          console.info('播放器状态未知。');
          break;
      }
    })
    avPlayer.on('audioInterrupt', async (interruptEvent: audio.InterruptEvent) => {
      if (interruptEvent.forceType === audio.InterruptForceType.INTERRUPT_FORCE) {
        switch (interruptEvent.hintType) {
          case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
            if (this.playSetting?.fadeInOut) {
              this.fadeOut()
            } else {
              this.avPlayer!.pause()
            }
            break;
          case audio.InterruptHint.INTERRUPT_HINT_STOP:
            if (this.playSetting?.fadeInOut) {
              this.fadeOut()
            } else {
              this.avPlayer!.pause()
            }
            break;
          default:
            break;
        }
      } else if (interruptEvent.forceType === audio.InterruptForceType.INTERRUPT_SHARE) {
        switch (interruptEvent.hintType) {
          case audio.InterruptHint.INTERRUPT_HINT_RESUME:
            if (this.playSetting?.fadeInOut) {
              this.fadeIn()
            } else {
              this.avPlayer!.play()
            }
            break;
          default:
            break;
        }
      }
    })
  }

  async aboutToAppear() {
    this.firstAppear = true
    app.setImageCacheCount(512);
    app.setImageRawDataCacheSize(100 * 1024 * 1024);
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      console.warn("no uiContext");
      return;
    }
    this.context = this.uiContext.getHostContext() as common.UIAbilityContext;
    this.context.getApplicationContext().setColorMode(this.colorMode?.colorMode)
    this.mainWindow = await window.getLastWindow(this.context)
    this.mainWindow.on('windowEvent', (data) => {
      if (data === window.WindowEventType.WINDOW_ACTIVE) {
        this.isOnFocus = true
      } else if (data === window.WindowEventType.WINDOW_INACTIVE) {
        this.isOnFocus = false
      }
    });
    this.displayWidth = this.uiContext!.px2vp(this.mainWindow.getWindowProperties().windowRect.width)
    this.displayHeight = this.uiContext!.px2vp(this.mainWindow.getWindowProperties().windowRect.height)
    if (this.displayWidth >= 1400) {
      this.sideBarWidth = 300
    } else {
      this.sideBarWidth = 240
    }
    if (this.displayWidth / this.displayHeight >= 2 / 3 && this.displayHeight >= 700) {
      this.sidebarType = SideBarContainerType.Embed
    } else {
      this.sidebarType = SideBarContainerType.Overlay
    }
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = this.uiContext!.px2vp(size.width)
      this.displayHeight = this.uiContext!.px2vp(size.height)
      if (this.displayWidth >= 1400) {
        this.sideBarWidth = 300
      } else {
        this.sideBarWidth = 240
      }
      if (this.displayWidth / this.displayHeight >= 2 / 3 && this.displayHeight >= 700) {
        this.sidebarType = SideBarContainerType.Embed
      } else {
        this.sidebarType = SideBarContainerType.Overlay
      }
    })
    this.getStatusBarHeight()
    if (this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      this.themeIcon = $r('sys.symbol.circle_righthalf_inset_filled')
      this.selectThemeIndex = 0
    } else if (this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      this.themeIcon = $r('sys.symbol.sun_max_fill')
      this.selectThemeIndex = 1
    } else if (this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      this.themeIcon = $r('sys.symbol.moon_fill')
      this.selectThemeIndex = 2
    }
    if (this.playSetting) {
      if (this.playSetting.skipIntervals === 10) {
        this.gobackwardIcon = $r('sys.symbol.gobackward_10')
        this.goforwardIcon = $r('sys.symbol.goforward_10')
      } else if (this.playSetting.skipIntervals === 15) {
        this.gobackwardIcon = $r('sys.symbol.gobackward_15')
        this.goforwardIcon = $r('sys.symbol.goforward_15')
      } else {
        this.gobackwardIcon = $r('sys.symbol.gobackward_30')
        this.goforwardIcon = $r('sys.symbol.goforward_30')
      }
    }
    this.registerInterception()
    this.avPlayer = await media.createAVPlayer();
    this.setAVPlayerCallback(this.avPlayer!);
  }

  aboutToDisappear() {
    this.avPlayer?.release()
  }

  //侧边栏区
  @Builder
  SideBarPanelBuilder() {
    Column() {
      Row() {
        Text("欢迎，" + (this.user?.username ?? "——") + "~")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .margin({ bottom: 20, top: deviceTypeInfo === '2in1' ? 5 : 0 })
      .padding({ left: 20, right: 20 })

      HdsSideMenu({
        items: this.pages,
        selectedIndex: this.pageIndex,
        $selectedIndex: (pageIndex: number) => {
          this.pageIndex = pageIndex;
          this.isShowSidebar = false
          this.pageInfos.clear()
        },
      })
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarHeight + 20 })
  }

  //内容区
  @Builder
  ContentPanelBuilder() {
    Stack() {
      MyNavigation()

      if (this.isStartPlaying) {
        Play()
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

  @BuilderParam contentBuilder: () => void = this.ContentPanelBuilder
  @BuilderParam sideBarBuilder: () => void = this.SideBarPanelBuilder

  @Builder
  build() {
    Stack() {
      HdsSideBar({
        sideBarPanelBuilder: (): void => {
          this.sideBarBuilder()
        },
        contentPanelBuilder: (): void => {
          this.contentBuilder()
        },
        autoHide: false,
        contentAreaMask: this.sidebarType === SideBarContainerType.Embed ? false : true,
        sideBarContainerType: this.sidebarType,
        isShowSideBar: this.sidebarType === SideBarContainerType.Embed ? true : this.isShowSidebar,
        $isShowSideBar: (isShowSidebar: boolean) => {
          this.isShowSidebar = !isShowSidebar
        },
        minSideBarWidth: this.sideBarWidth,
        maxSideBarWidth: this.sideBarWidth,
        sideBarPosition: this.sidebarType === SideBarContainerType.Embed ? SideBarPosition.Start : SideBarPosition.End
      })
    }
    .width('100%')
    .height('100%')
  }
}