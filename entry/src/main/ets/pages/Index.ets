import app from '@system.app';
import { HdsSideBar, HdsSideMenu, HdsSideMenuMainItem } from '@kit.UIDesignKit';
import { common, ConfigurationConstant, WantAgent, wantAgent } from '@kit.AbilityKit';
import { PersistenceV2, SymbolGlyphModifier, Type, window } from '@kit.ArkUI';
import { MyNavigation } from '../utils/Component';
import {
  Episode,
  Library,
  LibraryItem,
  LocalPlayItem,
  PlayItem,
  SearchResult,
  Series,
  Progress,
  LoginInfo,
  User,
  Bookmark,
  UpdateSession,
  Playlist,
  Collection,
  SkipSettings
} from '../utils/Interface';
import { Play } from './Play';
import { deviceInfo } from '@kit.BasicServicesKit';
import { avSession } from '@kit.AVSessionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { audio } from '@kit.AudioKit';
import { closeSession, getUser, initToastContext, syncSession } from '../utils/Api';
import { bundleManager } from '@kit.AbilityKit';
import { fileIo as fs, fileUri, picker } from '@kit.CoreFileKit';
import { DownloadManager, DownloadTaskInfo } from '../utils/Class';
import { LogEntry, Logger } from '../utils/Logger';

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
  @Trace rememberSpeed: boolean = false
  @Trace globalSpeed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @Trace skipIntervals: number = 10
  @Trace shareAudio: boolean = false
}

@ObservedV2
export class OtherSetting {
  @Trace hideReport: boolean = false
}

@ObservedV2
export class DownloadSetting {
  @Trace skipExistingFiles: boolean = false
}

@ObservedV2
export class ProjectSkipSettings {
  @Trace settingsJson: string = '{}'

  getSkipSettings(id: string): SkipSettings | undefined {
    const data: Record<string, SkipSettings> = JSON.parse(this.settingsJson)
    return data[id]
  }

  setSkipSettings(id: string, settings: SkipSettings): void {
    const data: Record<string, SkipSettings> = JSON.parse(this.settingsJson)
    data[id] = settings
    this.settingsJson = JSON.stringify(data)
  }

  removeSkipSettings(id: string): void {
    const data: Record<string, SkipSettings> = JSON.parse(this.settingsJson)
    const newData: Record<string, SkipSettings> = {}
    for (const key of Object.keys(data)) {
      if (key !== id) {
        newData[key] = data[key]
      }
    }
    this.settingsJson = JSON.stringify(newData)
  }
}

@Entry
@ComponentV2
struct Index {
  @Provider() serverIndex: ServerIndex | undefined = PersistenceV2.connect(ServerIndex, () => new ServerIndex());
  @Provider() serverSetting: ServerSetting | undefined = PersistenceV2.connect(ServerSetting, () => new ServerSetting());
  @Provider() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Provider() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Provider() otherSetting: OtherSetting | undefined = PersistenceV2.connect(OtherSetting, () => new OtherSetting());
  @Provider() downloadSetting: DownloadSetting | undefined = PersistenceV2.connect(DownloadSetting, () => new DownloadSetting());
  @Provider() projectSkipSettings: ProjectSkipSettings | undefined = PersistenceV2.connect(ProjectSkipSettings, () => new ProjectSkipSettings());
  @Provider() displayWidth: number = 0
  @Provider() displayHeight: number = 0
  @Provider() selectThemeIndex: number = 0
  @Provider() isOnFocus: boolean = true
  @Provider() themeIcon: Resource = $r('sys.symbol.circle_righthalf_inset_filled')
  @Provider() pageInfos: NavPathStack = new NavPathStack();
  @Provider() statusBarHeight: number = 0;
  @Provider() context: common.UIAbilityContext | undefined = undefined
  @Provider() downloadManager: DownloadManager | undefined = undefined
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
  @Provider() collections: Collection[] = []
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
  @Provider() speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
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
  @Provider() localPlayItem: LocalPlayItem | undefined = undefined
  @Provider() isLocalPlaying: boolean = false
  @Provider() playingTitle: string = "-"
  @Provider() playingIndex: number = 0
  @Provider() showAddServer: boolean = false
  @Provider() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Provider() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Provider() statsScroller: Scroller = new Scroller()
  @Provider() LocalMediaScroller: Scroller = new Scroller()
  @Provider() logScroller: Scroller = new Scroller()
  @Provider() settingScroller: Scroller = new Scroller()
  @Provider() playStartTime: number = 0
  @Provider() playedTime: number = 0
  @Provider() playedPercent: number = 0
  @Provider() currentTrackDuration: number = 0
  @Provider() avPlayer: media.AVPlayer | undefined = undefined
  @Provider() session: avSession.AVSession | undefined = undefined
  @Provider() sleepTime: number = 0
  @Provider() sliderMoving: boolean = false
  @Provider() syncTime: number = 0
  @Provider() logs: LogEntry[] = []
  @Provider() downloadUri: string = ""
  @Provider() downloadTasks: DownloadTaskInfo[] = []
  @Provider() downloadCount: number = 0
  @Provider() toCloseSession: PlayItem | undefined = undefined
  @Provider() toCloseIndex: number = 0
  @Local uiContext: UIContext | undefined = undefined
  @Local mainWindow: window.Window | undefined = undefined
  @Local elapsedTime: number = 0
  @Local isSyncing: boolean = false
  @Local playerState: string = 'idle'
  @Local consecutiveErrors: number = 0
  @Local syncInterval: number = 10000
  @Local errorRetryTimer: number = -1
  @Local errorResetTimer: number = -1
  @Local continuousTaskRunning: boolean = false
  @Local sleepTimerId: number = -1
  @Local fadeInterval: number = -1
  @Local stopTimeoutId: number = -1
  @Local audioSessionManager: audio.AudioSessionManager | undefined = undefined
  @Local audioSessionActivated: boolean = false
  @Monitor('toCloseSession')
  async closeEndSession(_: IMonitor) {
    if (this.toCloseSession) {
      this.syncProgress(this.toCloseSession, this.toCloseIndex)
      this.toCloseSession = undefined
      this.toCloseIndex = 0
    }
  }

  @Monitor('playingItem')
  onPlayingItemChange(_: IMonitor) {
    if (this.playingItem !== undefined) {
      this.isLocalPlaying = false
      this.localPlayItem = undefined
      this.currentTrackDuration = 0
    }
  }

  async findCoverInFolder(folderPath: string): Promise<string | undefined> {
    const candidates = ['cover.jpg', 'cover.jpeg', 'cover.png', 'cover.webp', 'folder.jpg']
    try {
      const entries = await fs.listFile(folderPath)
      for (let c of candidates) {
        if (entries.includes(c)) {
          return `${folderPath}/${c}`
        }
      }
    } catch (_) {}
    return undefined
  }

  async playLocal(localItem: LocalPlayItem, index: number) {
    if (this.avPlayer === undefined) return
    try { await this.avPlayer.reset() } catch (_) {}
    if (!localItem.coverPath) {
      localItem.coverPath = await this.findCoverInFolder(localItem.folderPath)
    }
    this.isLocalPlaying = true
    this.localPlayItem = localItem
    this.playingItem = undefined
    this.playingIndex = index
    this.playingTitle = localItem.tracks[index].title
    this.playStartTime = 0
    this.isPlaying = true
    this.isStartPlaying = true
    this.showPlay = true
    try {
      const file = fs.openSync(localItem.tracks[index].filePath, fs.OpenMode.READ_ONLY)
      try {
        this.avPlayer.fdSrc = { fd: file.fd, offset: 0, length: -1 }
      } catch (_) {
        fs.closeSync(file)
      }
    } catch (_) {}
  }

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
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let duration = 1000
    let volume = 0;
    const step = 50;
    const increment = step / duration;
    this.avPlayer!.setVolume(volume);
    try { this.avPlayer!.play() } catch (_) {}
    const interval = setInterval(() => {
      try {
        volume += increment;
        if (volume >= 1.0) {
          this.avPlayer!.setVolume(1.0);
          clearInterval(interval);
          this.fadeInterval = -1
        } else {
          this.avPlayer!.setVolume(volume);
        }
      } catch (_) {}
    }, step);
    this.fadeInterval = interval
  }

  fadeOut() {
    this.isPlaying = false
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let duration = 1000
    let volume = 1.0;
    const step = 50;
    const decrement = step / duration;
    const interval = setInterval(() => {
      try {
        volume -= decrement;
        if (volume <= 0.0) {
          this.avPlayer!.setVolume(0.0);
          clearInterval(interval);
          this.fadeInterval = -1
          this.avPlayer!.pause();
        } else {
          this.avPlayer!.setVolume(volume);
        }
      } catch (_) {}
    }, step);
    this.fadeInterval = interval
  }

  async syncProgress(closeItem?: PlayItem, closeIndex?: number) {
    if (!this.isSyncing) {
      this.isSyncing = true
      let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
      let updateSession: UpdateSession | undefined = undefined
      let status = false
      if (closeItem) {
        updateSession = {
          deviceInfo: {
            id: deviceInfo.displayVersion,
            userId: this.user!.id,
            deviceName: deviceInfo.marketName,
            clientName: "Harmshelf",
            clientVersion: bundleInfo.versionName
          },
          mediaPlayer: "avPlayer",
          currentTime: closeItem.audioTracks[closeIndex!].startOffset + this.playedTime,
          timeListened: new Date().getTime() / 1000 - this.syncTime
        }
        for (let element of this.progress) {
          if (closeItem.mediaType === 'book' ? element.libraryItemId === closeItem.libraryItemId : element.episodeId === closeItem.episodeId) {
            element.duration = closeItem.duration
            element.currentTime = closeItem.audioTracks[closeIndex!].startOffset + this.playedTime
            element.progress = element.currentTime / (Math.trunc(element.duration * 1000) / 1000)
            element.isFinished = element.progress >= 1 ? true : false
            break
          }
        }
        status = await closeSession(closeItem!.id, updateSession)
      } else {
        updateSession = {
          deviceInfo: {
            id: deviceInfo.displayVersion,
            userId: this.user!.id,
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
        status = await syncSession(this.playingItem!.id, updateSession)
      }
      if (status) {
        this.isConnect = true
        Logger.info(`会话当前时间${updateSession.currentTime}`)
        Logger.info(`会话汇报间隔${updateSession.timeListened}`)
        this.syncTime = new Date().getTime() / 1000
        this.syncInterval = 10000
        this.user = await getUser()
        this.progress = this.user?.mediaProgress??[]
      } else {
        this.isConnect = false
        this.syncInterval = Math.min(this.syncInterval * 1.5, 60000)
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
    if (this.continuousTaskRunning) return
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context!.abilityInfo.bundleName,
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
        this.continuousTaskRunning = true
        Logger.info(`启动长时任务。`);
      }).catch((err: BusinessError) => {
        Logger.error(`启动长时任务出错，代码 ${err.code}，错误信息 ${err.message}`);
      });
    }).catch((err: BusinessError) => {
      Logger.error(`获取WantAgent失败，代码 ${err.code}，错误信息 ${err.message}`);
    });
  }

  async stopContinuousTask() {
    if (!this.continuousTaskRunning) return
    backgroundTaskManager.stopBackgroundRunning(this.context).then(() => {
      this.continuousTaskRunning = false
      Logger.info(`停止长时任务。`);
    }).catch((err: BusinessError) => {
      Logger.error(`停止长时任务出错，代码 ${err.code}，错误信息 ${err.message}`);
    });
  }

  async activateAudioSession() {
    if (!this.playSetting?.shareAudio) return
    if (!this.audioSessionManager) {
      this.audioSessionManager = audio.getAudioManager().getSessionManager()
    }
    if (this.audioSessionActivated) return
    try {
      await this.audioSessionManager!.activateAudioSession({
        concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_MIX_WITH_OTHERS
      })
      this.audioSessionActivated = true
      Logger.info('已激活混音模式，允许与其他应用同时播放。');
    } catch (err) {
      Logger.error('激活混音模式失败：' + JSON.stringify(err));
    }
  }

  async deactivateAudioSession() {
    if (!this.audioSessionManager || !this.audioSessionActivated) return
    try {
      await this.audioSessionManager!.deactivateAudioSession()
      this.audioSessionActivated = false
      Logger.info('已停用混音模式。');
    } catch (err) {
      Logger.error('停用混音模式失败：' + JSON.stringify(err));
    }
  }

  async setSessionInfo() {
    let metadata: avSession.AVMetadata = {
      assetId: this.playingIndex.toString(),
      title: this.playingTitle,
      subtitle: this.isLocalPlaying ? "本地文件" : this.playingItem!.displayAuthor,
      duration: this.isLocalPlaying
        ? this.localPlayItem!.tracks[this.playingIndex].duration * 1000
        : this.playingItem!.audioTracks[this.playingIndex].duration * 1000,
      mediaImage: this.isLocalPlaying ? "" : (this.baseUrl + `/api/items/${this.playingItem!.libraryItemId}/cover?token=${this.apiToken}`),
      skipIntervals: this.playSetting!.skipIntervals
    };
    this.session!.setAVMetadata(metadata).then(() => {
      Logger.info(`SetAVMetadata successfully`);
    }).catch((err: BusinessError) => {
      Logger.error(`Failed to set AVMetadata. Code: ${err.code}, message: ${err.message}`);
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
        Logger.error(`设置Session状态失败，Code: ${err.code}, message: ${err.message}`);
      } else {
        Logger.info(`设置Session状态${state}`);
      }
    });
  }

  async setSessionCallback() {
    this.session!.on('play', () => {
      try {
        const playable = ['prepared', 'paused', 'completed']
        if (!playable.includes(this.playerState)) return
        if (this.playSetting?.fadeInOut) {
          this.fadeIn()
        } else {
          this.avPlayer!.play()
        }
      } catch (_) {}
    });
    this.session!.on('pause', () => {
      try {
        if (this.playerState !== 'playing') return
        if (this.playSetting?.fadeInOut) {
          this.fadeOut()
        } else {
          this.avPlayer!.pause()
        }
      } catch (_) {}
    });
    this.session!.on('stop', async () => {
      try {
        const stoppable = ['prepared', 'playing', 'paused', 'completed']
        if (!stoppable.includes(this.playerState)) return
        this.avPlayer!.stop()
      } catch (_) {}
    });
    this.session!.on('seek', async (time: number) => {
      try {
        const seekable = ['prepared', 'playing', 'paused', 'completed']
        if (!seekable.includes(this.playerState)) return
        await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_BUFFERING)
        this.avPlayer!.seek(time)
      } catch (_) {}
    });
    this.session!.on('rewind', () => {
      try {
        const seekable = ['prepared', 'playing', 'paused', 'completed']
        if (!seekable.includes(this.playerState)) return
        this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
      } catch (_) {}
    })
    this.session!.on('fastForward', () => {
      try {
        const seekable = ['prepared', 'playing', 'paused', 'completed']
        if (!seekable.includes(this.playerState)) return
        let dur = this.isLocalPlaying
          ? this.localPlayItem!.tracks[this.playingIndex].duration
          : this.playingItem!.audioTracks[this.playingIndex].duration
        this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < dur ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : dur * 1000)
      } catch (_) {}
    })
    if (this.isLocalPlaying || this.playingIndex > 0) {
      this.session!.on('playPrevious', async () => {
        try {
          await this.avPlayer!.reset();
          this.playingIndex--
          this.playingTitle = this.isLocalPlaying
            ? this.localPlayItem!.tracks[this.playingIndex].title
            : (this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle)
          if (this.isLocalPlaying) {
            try {
              const prevFile = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
              this.avPlayer!.fdSrc = { fd: prevFile.fd, offset: 0, length: -1 }
            } catch (_) {
              this.uiContext?.getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
            }
          } else {
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
          }
        } catch (_) {}
      });
    } else {
      this.session!.off('playPrevious')
    }
    let trackCount = this.isLocalPlaying ? this.localPlayItem!.tracks.length : this.playingItem!.audioTracks.length
    if (this.playingIndex < trackCount - 1) {
      this.session!.on('playNext', async () => {
        try {
          await this.avPlayer!.reset();
          this.playingIndex++
          this.playingTitle = this.isLocalPlaying
            ? this.localPlayItem!.tracks[this.playingIndex].title
            : (this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle)
          if (this.isLocalPlaying) {
            try {
              const nextFile = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
              this.avPlayer!.fdSrc = { fd: nextFile.fd, offset: 0, length: -1 }
            } catch (_) {
              this.uiContext?.getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
            }
          } else {
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
          }
        } catch (_) {}
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
      if (this.isLocalPlaying === false && this.sleepTime !== 0 && (this.sleepTime + 0.2) <= (this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset)) {
        if (this.sleepTimerId !== -1) {
          clearTimeout(this.sleepTimerId)
        }
        this.sleepTimerId = setTimeout(() => {
          if (this.playSetting?.fadeInOut) {
            this.fadeOut()
          } else {
            this.avPlayer!.pause()
          }
          this.sleepTime = 0
          this.sleepTimerId = -1
        }, 200);
      }
      // 跳过结尾检测
      if (!this.isLocalPlaying && this.playingItem) {
        const skipSettings = this.projectSkipSettings?.getSkipSettings(this.playingItem.libraryItemId)
        if (skipSettings && skipSettings.skipEnd > 0) {
          const trackDuration = this.playingItem.audioTracks[this.playingIndex]?.duration ?? this.currentTrackDuration
          if (trackDuration > skipSettings.skipEnd && this.playedTime >= trackDuration - skipSettings.skipEnd) {
            // 到达跳过结尾位置，自动跳到下一首
            if (this.playingIndex < this.playingItem.audioTracks.length - 1) {
              Logger.info('跳过结尾：切换到下一首')
              await this.avPlayer!.reset()
              this.playingIndex++
              this.playingTitle = this.playingItem.chapters?.[this.playingIndex]?.title ?? this.playingItem.displayTitle
              this.avPlayer!.url = this.baseUrl + this.playingItem.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
              this.playStartTime = 0
            } else {
              Logger.info('跳过结尾：最后一首，暂停')
              await this.avPlayer!.pause()
              this.isPlaying = false
            }
          }
        }
      }
      if (this.sliderMoving === false) {
        let dur = this.isLocalPlaying ? this.currentTrackDuration : this.playingItem!.audioTracks[this.playingIndex].duration
        this.playedPercent = dur > 0 ? this.playedTime / dur * 100 : 0
      }
      if (!this.isLocalPlaying && this.elapsedTime >= this.syncInterval) {
        this.syncProgress()
      }
    })
    avPlayer.on('seekDone', async (seekDoneTime: number) => {
      Logger.info(`播放器跳转成功，当前时间为 ${seekDoneTime}`);
      this.playedTime = seekDoneTime / 1000
      if (this.isPlaying === true) {
        await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
      } else {
        await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
      }
      this.sliderMoving = false
      if (!this.isLocalPlaying) {
        this.syncProgress()
      }
    })
    avPlayer.on('speedDone', (data: number) => {
      switch(data) {
        case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
          Logger.info("设置速度 " + 0.5);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
          Logger.info("设置速度 " + 0.75);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
          Logger.info("设置速度 " + 1);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
          Logger.info("设置速度 " + 1.25);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
          Logger.info("设置速度 " + 1.5);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
          Logger.info("设置速度 " + 1.75);
          break;
        case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
          Logger.info("设置速度 " + 2);
          break;
        default :
          Logger.info("设置速度 未知");
          break;
      }
      if (this.playSetting?.rememberSpeed === true) {
        this.playSetting.globalSpeed = data
      }
    })
    avPlayer.on('volumeChange', (vol: number) => {
      Logger.info('设置播放音量' + vol)
    })
    avPlayer.on('durationUpdate', (duration: number) => {
      this.currentTrackDuration = duration / 1000
    })
    avPlayer.on('error', async (err: BusinessError) => {
      this.consecutiveErrors++
      Logger.error(`播放器出现错误，code is ${err.code}, message is ${err.message}`);
      if (err.code === 5400102) {
        return;
      }
      if (this.consecutiveErrors >= 2) {
        this.stopContinuousTask()
        this.uiContext!.getPromptAction().showToast({
          message: '播放出错，请稍后重试！',
          duration: 1500
        });
        if (this.errorResetTimer !== -1) {
          clearTimeout(this.errorResetTimer)
        }
        this.errorResetTimer = setTimeout(() => {
          this.consecutiveErrors = 0
          this.errorResetTimer = -1
        }, 30000)
        return;
      }
      const wasPlaying = this.playerState === 'playing'
      if (this.fadeInterval !== -1) {
        clearInterval(this.fadeInterval)
        this.fadeInterval = -1
      }
      await avPlayer.reset();
      const savedPosition = this.playedTime
      if (this.isLocalPlaying) {
        try {
          const file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
          avPlayer.fdSrc = { fd: file.fd, offset: 0, length: -1 }
        } catch (_) {
          this.uiContext?.getPromptAction().showToast({
            message: '播放失败，本地文件不存在或格式不支持！',
            duration: 500
          })
          this.isPlaying = false
          return
        }
      } else {
        avPlayer.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
      }
      this.isPlaying = wasPlaying
      this.playStartTime = savedPosition
      if (this.errorRetryTimer !== -1) {
        clearTimeout(this.errorRetryTimer)
      }
      this.errorRetryTimer = setTimeout(() => {
        if (this.avPlayer?.state === 'initialized') {
          avPlayer.prepare()
        }
        this.errorRetryTimer = -1
      }, 1500)
      if (err.code === 5400106 || err.code === 5411007) {
        this.uiContext!.getPromptAction().showToast({
          message: '播放失败，格式不支持或文件不存在！',
          duration: 500
        });
      } else if (err.code === 5400104 || err.code === 5400103 || err.code === 5411002 || err.code === 5411004) {
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
      this.playerState = state
      switch (state) {
        case 'idle':
          Logger.info('播放器重置。');
          this.stopContinuousTask()
          this.playedTime = 0
          this.playedPercent = 0
          if (this.audioSessionActivated) {
            await this.deactivateAudioSession()
          }
          break;
        case 'initialized':
          Logger.info('播放器初始化。');
          avPlayer.prepare();
          break;
        case 'prepared':
          Logger.info('播放器就绪。');
          this.consecutiveErrors = 0
          this.playedTime = 0
          if (this.session === undefined) {
            this.session = await avSession.createAVSession(this.context!, 'AUDIO_PLAY', 'video');
            await this.setSessionCallback()
            await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_INITIAL)
          }
          await this.session!.activate()
          await this.setSessionInfo()
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PREPARE)
          // 应用跳过开头/结尾
          let seekTarget = this.playStartTime
          if (!this.isLocalPlaying && this.playingItem) {
            const skipSettings = this.projectSkipSettings?.getSkipSettings(this.playingItem.libraryItemId)
            if (skipSettings) {
              // 使用 server 端已知的 track duration（比 currentTrackDuration 更可靠，后者在 prepared 时可能尚未更新）
              const trackDuration = this.playingItem.audioTracks[this.playingIndex]?.duration ?? 0
              // 跳过开头：只有从开头起播（playStartTime === 0）时才应用跳过
              if (skipSettings.skipStart > 0 && trackDuration > skipSettings.skipStart) {
                if (seekTarget === 0) {
                  seekTarget = skipSettings.skipStart
                  Logger.info('跳过开头：跳至' + skipSettings.skipStart + '秒')
                }
                // 如果 >0 且 < skipStart，说明用户在跳过范围内续播，忽略跳过
              }
              // 跳过结尾：由 timeUpdate 运行时检测，此处不做调整
            }
          }
          if (seekTarget !== 0) {
            this.avPlayer!.seek(seekTarget * 1000)
          }
          this.playStartTime = 0
          this.avPlayer!.setSpeed(this.speed)
          if (this.isPlaying === true) {
            if (this.playSetting?.fadeInOut) {
              this.fadeIn()
            } else {
              this.avPlayer!.play()
            }
          }
          this.elapsedTime = 10000
          this.syncTime = new Date().getTime() / 1000
          break;
        case 'playing':
          Logger.info('播放器开始播放。');
          this.isPlaying = true
          this.syncInterval = 10000
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY)
          this.startContinuousTask()
          if (this.playSetting?.shareAudio) {
            await this.activateAudioSession()
          }
          break;
        case 'paused':
          Logger.info('播放器暂停。');
          this.isPlaying = false
          await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
          this.stopContinuousTask()
          if (this.audioSessionActivated) {
            await this.deactivateAudioSession()
          }
          break;
        case 'completed':
          Logger.info('播放完毕。');
          if (!this.isLocalPlaying) {
            this.syncProgress()
          }
          if (this.isLocalPlaying) {
            if (this.playingIndex < this.localPlayItem!.tracks.length - 1) {
              const newIndex = this.playingIndex + 1
              try {
                await this.avPlayer!.reset()
                this.playingIndex = newIndex
                this.playingTitle = this.localPlayItem!.tracks[newIndex].title
                const nextFile = fs.openSync(this.localPlayItem!.tracks[newIndex].filePath, fs.OpenMode.READ_ONLY)
                this.avPlayer!.fdSrc = { fd: nextFile.fd, offset: 0, length: -1 }
              } catch (_) {
                this.isPlaying = false
                this.uiContext?.getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
              }
            } else {
              this.isPlaying = false
            }
          } else if (this.sleepTime !== 0 && Number(this.sleepTime.toFixed(3)) <= Number((this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset).toFixed(3))) {
            this.sleepTime = 0
            this.isPlaying = false
            this.stopContinuousTask()
            await this.setPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE)
            if (this.playingIndex < this.playingItem!.audioTracks.length - 1) {
              await this.avPlayer!.reset()
              this.playingIndex++
              this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
              this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
            }
          } else {
            if (this.playingIndex < this.playingItem!.audioTracks.length - 1) {
              await this.avPlayer!.reset()
              this.playingIndex++
              this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
              this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
            } else {
              this.isPlaying = false
            }
          }
          break;
        case 'stopped':
          Logger.info('播放器停止。');
          await this.stopContinuousTask()
          if (this.audioSessionActivated) {
            await this.deactivateAudioSession()
          }
          this.toCloseIndex = this.playingIndex
          if (!this.isLocalPlaying) {
            this.toCloseSession = this.playingItem
          }
          this.showPlay = false
          await this.session!.destroy()
          this.session = undefined
          await avPlayer.reset();
          this.playedTime = 0
          this.playedPercent = 0
          this.sleepTime = 0
          this.playingItem = undefined
          this.localPlayItem = undefined
          this.isLocalPlaying = false
          this.playingIndex = 0
          this.stopTimeoutId = setTimeout(() => {
            this.isStartPlaying = false
            this.isPlaying = false
            this.stopTimeoutId = -1
          }, 100)
          break;
        case 'released':
          Logger.info('播放器释放。');
          break;
        case 'error':
          Logger.info('播放器进入错误状态。');
          this.isPlaying = false
          if (this.audioSessionActivated) {
            await this.deactivateAudioSession()
          }
          break;
        default:
          Logger.info('播放器状态未知。');
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
    Logger.setCallback((entries) => {
      this.logs = entries
    })
    this.firstAppear = true
    app.setImageCacheCount(512);
    app.setImageRawDataCacheSize(100 * 1024 * 1024);
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      Logger.warn("no uiContext");
      return;
    }
    initToastContext(this.uiContext)
    this.context = this.uiContext.getHostContext() as common.UIAbilityContext;
    this.context.getApplicationContext().setColorMode(this.colorMode?.colorMode)
    Logger.startFileLogging(this.context.filesDir + '/logs')
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
    this.speed = this.playSetting?.globalSpeed??media.PlaybackSpeed.SPEED_FORWARD_1_00_X
    this.downloadManager = new DownloadManager(this.context!);
    try {
      const documentViewPicker = new picker.DocumentViewPicker(this.context!);
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
      documentViewPicker.save(documentSaveOptions).then(async (documentSaveResult: Array<string>) => {
        this.downloadUri = documentSaveResult[0];
        Logger.debug('documentViewPicker.save succeed and uri is:' + this.downloadUri);
        const downloadPath = new fileUri.FileUri(this.downloadUri).path
        if (!fs.accessSync(downloadPath + "/有声书")) {
          fs.mkdirSync(downloadPath + "/有声书")
        }
        if (!fs.accessSync(downloadPath + "/播客")) {
          fs.mkdirSync(downloadPath + "/播客")
        }
      }).catch((err: BusinessError) => {
        Logger.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
      })
    } catch (err) {
      Logger.error(`Failed to create a documentSaveOptions, err: ${err}`);
      return;
    }
  }

  aboutToDisappear() {
    if (!this.isLocalPlaying && this.playingItem) {
      try { this.syncProgress(this.playingItem, this.playingIndex) } catch (_) {}
    }
    if (this.errorRetryTimer !== -1) {
      clearTimeout(this.errorRetryTimer)
      this.errorRetryTimer = -1
    }
    if (this.errorResetTimer !== -1) {
      clearTimeout(this.errorResetTimer)
      this.errorResetTimer = -1
    }
    if (this.sleepTimerId !== -1) {
      clearTimeout(this.sleepTimerId)
      this.sleepTimerId = -1
    }
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
      this.fadeInterval = -1
    }
    if (this.stopTimeoutId !== -1) {
      clearTimeout(this.stopTimeoutId)
      this.stopTimeoutId = -1
    }
    this.stopContinuousTask()
    this.session?.destroy()
    this.session = undefined
    Logger.stopFileLogging()
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
          try {
            this.pageIndex = pageIndex;
            this.isShowSidebar = false
            this.pageInfos.clear()
          } catch (_) {}
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