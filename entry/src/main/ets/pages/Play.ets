import { BlurStrategy, HdsActionBar, ActionBarButton, HdsListItem, ActionBarStyle } from '@kit.UIDesignKit'
import { Bookmark, Chapter, LocalPlayItem, LocalTrack, PlayItem, User } from '../utils/Interface'
import { ColorMetrics, CircleShape, LengthMetrics, PersistenceV2, SymbolGlyphModifier, uiMaterial, window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { createBookmark, deleteBookmark, getBookmarks } from '../utils/Api';
import { PlaySetting } from './Index';
import { media } from '@kit.MediaKit';
import { Logger } from '../utils/Logger';
import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { rcp } from '@kit.RemoteCommunicationKit';
import { ImmersiveActionButton } from '../utils/Component';

interface PlayColorPalette {
  primary: string
  secondary: string
  sliderBlock: string
  sliderTrack: string
}

@ComponentV2
export struct Play {
  private chapterScroller: Scroller = new Scroller();
  @Env(SystemProperties.WINDOW_AVOID_AREA)
  windowAvoidArea: window.UIEnvWindowAvoidAreaInfoVP
  @Consumer() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Consumer() displayWidth: number = 0
  @Consumer() displayHeight: number = 0
  @Consumer() isPlaying: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() showPlay: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() localPlayItem: LocalPlayItem | undefined = undefined
  @Consumer() isLocalPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Consumer() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Consumer() bookmarks: Bookmark[] = []
  @Consumer() user: User | undefined = undefined
  @Consumer() playStartTime: number = 0
  @Consumer() playedTime: number = 0
  @Consumer() playedPercent: number = 0
  @Consumer() currentTrackDuration: number = 0
  @Consumer() sleepTime: number = 0
  @Consumer() sliderMoving: boolean = false
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @Local rotateAngle: number = 0
  @Local rotateTimer: number = -1
  @Local sliderValue: number = 0
  @Local fadeInterval: number = -1
  @Local coverColor: number = 0xff181818
  private coverColorKey: string = ''
  private coverColorRequest: number = 0
  private previousStatusBarContentColor: string = ''

  private get playControlColor(): Color {
    const red = (this.coverColor >>> 16) & 0xff
    const green = (this.coverColor >>> 8) & 0xff
    const blue = this.coverColor & 0xff
    return red * 0.299 + green * 0.587 + blue * 0.114 > 160 ? Color.Black : Color.White
  }

  private get playColorPalette(): PlayColorPalette {
    return this.playControlColor === Color.Black ? {
      primary: '#182431',
      secondary: '#99182431',
      sliderBlock: '#3A3A3B',
      sliderTrack: '#19182431'
    } : {
      primary: '#FFFFFF',
      secondary: '#99FFFFFF',
      sliderBlock: '#BCBCBC',
      sliderTrack: '#19FFFFFF'
    }
  }

  private async updateStatusBarContentColor() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      await mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: this.playControlColor === Color.Black ? '#000000' : '#FFFFFF'
      })
    } catch (_) {
    }
  }

  private async restoreStatusBarContentColor() {
    if (!this.previousStatusBarContentColor) {
      return
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      await mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: this.previousStatusBarContentColor
      })
    } catch (_) {
    }
  }
  @Consumer() isOnFocus: boolean = true
  @Monitor('isOnFocus')
  onFocusChange() {
    if (!this.isOnFocus) {
      this.stopRotate()
    } else if (this.isPlaying) {
      this.startRotate()
    }
  }

  async aboutToAppear() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      this.previousStatusBarContentColor = mainWindow.getWindowSystemBarProperties().statusBarContentColor ?? ''
      if (this.showPlay) {
        await this.updateStatusBarContentColor()
      }
    } catch (_) {
    }
  }

  aboutToDisappear() {
    this.stopRotate()
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    this.coverColorRequest++
    this.restoreStatusBarContentColor()
  }
  @Local shouldClosePlayer: boolean = false
  @Local lockPlayer: boolean = false
  @Local showProgress: boolean = false
  @Local showBookmark: boolean = false
  @Local showSpeed: boolean = false
  @Local showSleep: boolean = false
  @Local showChapter: boolean = false
  @Local speedIcon: Resource = $r('sys.symbol.speed_100percent')
  @Local tmpBookmarkTitle: string = ""
  @Local tmpBookmarkTime: number = 0
  @Local showEditBookmark: boolean = false
  @Local editBookmarkIndex: number = 0
  @Local maxIntroLine: number = 5
  @Local showMoreIntro: boolean = false
  @Monitor('playingItem')
  async setSpeed(_: IMonitor) {
    this.sleepTime = 0
    if (this.playSetting?.rememberSpeed === true) {
      this.speed = this.playSetting.globalSpeed
    } else {
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
    }
  }
  @Monitor('playingItem')
  async refreshPlayingCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('localPlayItem')
  async refreshLocalCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('isLocalPlaying')
  async refreshLocalModeCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('showPlay')
  async refreshShownCoverColor(_: IMonitor) {
    if (this.showPlay) {
      await this.updateStatusBarContentColor()
      await this.refreshCoverColor()
    } else {
      await this.restoreStatusBarContentColor()
    }
  }

  private getCoverSource(): string {
    if (this.isLocalPlaying) {
      const coverPath = this.localPlayItem?.coverPath ?? ''
      return coverPath ? fileUri.getUriFromPath(coverPath) : ''
    }
    if (!this.baseUrl || !this.playingItem?.libraryItemId) {
      return ''
    }
    return this.baseUrl + `/api/items/${this.playingItem.libraryItemId}/cover?token=${this.apiToken}`
  }

  private async refreshCoverColor(): Promise<void> {
    const coverSource = this.getCoverSource()
    if (!coverSource || coverSource === this.coverColorKey) {
      return
    }
    this.coverColorKey = coverSource
    const requestId = ++this.coverColorRequest
    let session: rcp.Session | undefined = undefined
    let imageSource: image.ImageSource | undefined = undefined
    let pixelMap: image.PixelMap | undefined = undefined
    try {
      if (coverSource.startsWith('http://') || coverSource.startsWith('https://')) {
        session = rcp.createSession()
        const response = await session.fetch(new rcp.Request(coverSource, 'GET'))
        if (!response.body) {
          return
        }
        imageSource = image.createImageSource(response.body)
      } else {
        imageSource = image.createImageSource(coverSource)
      }
      if (!imageSource) {
        return
      }
      pixelMap = await imageSource.createPixelMap({
        desiredSize: { width: 32, height: 32 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      })
      const picker = await effectKit.createColorPicker(pixelMap)
      let color: effectKit.Color | undefined = undefined
      try {
        color = await picker.getMainColor()
      } catch (_) {
        color = picker.getAverageColor()
      }
      if (color && requestId === this.coverColorRequest && coverSource === this.getCoverSource()) {
        this.coverColor = 0xff000000 +
          Math.round(color.red) * 0x10000 + Math.round(color.green) * 0x100 + Math.round(color.blue)
        await this.updateStatusBarContentColor()
      }
    } catch (_) {
      Logger.error('提取封面主色失败')
    } finally {
      if (pixelMap) {
        try {
          await pixelMap.release()
        } catch (_) {
        }
      }
      if (imageSource) {
        try {
          await imageSource.release()
        } catch (_) {
        }
      }
      if (session) {
        try {
          session.close()
        } catch (_) {
        }
      }
    }
  }
  @Monitor('speed')
  async speedMonitoring(_: IMonitor) {
    this.changeSpeedIcon()
  }
  @Monitor('gobackwardIcon')
  async changeIcon(_: IMonitor) {
    this.goBackwardButton.baseIcon = this.gobackwardIcon
    this.goForwardButton.baseIcon = this.goforwardIcon
  }
  @Monitor('isPlaying')
  async changeIcon2(_: IMonitor) {
    this.playPauseButton.baseIcon = this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill');
  }

  changeSpeedIcon() {
    switch(this.speed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
        this.speedIcon = $r('sys.symbol.speed_50percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        this.speedIcon = $r('sys.symbol.speed_75percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        this.speedIcon = $r('sys.symbol.speed_100percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        this.speedIcon = $r('sys.symbol.speed_125percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
        this.speedIcon = $r('sys.symbol.speed_150percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        this.speedIcon = $r('sys.symbol.speed_175percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        this.speedIcon = $r('sys.symbol.speed_200percent')
        break;
      default :
        break;
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${month}月 ${day}, ${year} ${hours}:${minutes}`
  }

  formatSeconds(seconds: number): string {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
    } else if (m > 0) {
      return `${m}:${s.toString().padStart(2, '0')}`
    } else {
      return `0:${s.toString().padStart(2, '0')}`
    }
  }

  formatSleepTime(seconds: number): string {
    if (seconds <= 0) {
      return "0 sec"
    }
    if (seconds >= 60) {
      const minutes = Math.round(seconds / 60)
      return `${minutes} min`
    } else {
      const secs = Math.round(seconds)
      return `${secs} sec`
    }
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

  getCurrentDuration(): number {
    if (this.isLocalPlaying) {
      return this.currentTrackDuration
    }
    return this.playingItem?.audioTracks[this.playingIndex]?.duration ?? 0
  }

  fadeIn() {
    this.isPlaying = true
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
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
        this.fadeInterval = -1
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
    this.fadeInterval = interval
  }

  fadeOut() {
    this.isPlaying = false
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let duration = 1000
    let volume = 1.0; // 假设当前音量是最大值
    const step = 50; // 调整间隔时间，单位 ms
    const decrement = step / duration; // 每次减少的音量比例
    const interval = setInterval(() => {
      volume -= decrement;
      if (volume <= 0.0) {
        this.avPlayer!.setVolume(0.0);
        clearInterval(interval);
        this.fadeInterval = -1
        this.avPlayer!.pause(); // 在音量完全降为 0 后暂停
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
    this.fadeInterval = interval
  }

  async getPlayContent(playItem: PlayItem, time: number) {
    let index: number = 0
    for (let i = 0; i < playItem.audioTracks.length; i++) {
      if (playItem.audioTracks[i].startOffset > time) {
        index = i > 0 ? i - 1 : 0
        break
      }
    }
    this.playingIndex = index
    this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
    this.playStartTime = time - playItem.audioTracks[index].startOffset
    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
    Logger.info(`共playItem.audioTracks.length条音轨`)
    Logger.info(`播放序号为this.playingIndex`)
    Logger.info(`起始位置为this.playStartTime`)
  }

  startRotate() {
    if (this.rotateTimer !== -1) {
      return
    }
    this.rotateTimer = setInterval(() => {
      this.rotateAngle += 0.1
    }, 10)
  }

  stopRotate() {
    if (this.rotateTimer === -1) {
      return
    }
    clearInterval(this.rotateTimer)
    this.rotateTimer = -1
  }

  @Builder
  editBookmarkBuilder() {
    Column() {
      TextInput({
        placeholder: "书签标题",
        text: this.tmpBookmarkTitle
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
          this.tmpBookmarkTitle = value
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
          this.showEditBookmark = false
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
          let bookmark: Bookmark = {
            libraryItemId: this.playingItem!.libraryItemId,
            title: this.tmpBookmarkTitle,
            time: this.tmpBookmarkTime,
            createdAt: Date.now()
          }
          let status = await createBookmark(this.playingItem!.libraryItemId, bookmark)
          if (status) {
            this.showEditBookmark = false
            this.getUIContext().getPromptAction().showToast({
              message: '编辑书签成功！',
              duration: 500
            });
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '编辑书签失败，请检查网络！',
              duration: 500
            });
          }
        })
      }
    }
    .padding({ left: 20, right: 20, bottom: 25 })
  }

  @Builder
  bookmarkItemBuilder(bookmark: Bookmark, index: number) {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.bookmark'))
          .fontSize(20)
        Column() {
          Text(bookmark.title.length === 0 ? this.formatTime(bookmark.createdAt) : bookmark.title)
            .fontSize(16)
          Text(this.formatSeconds(bookmark.time))
            .fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ top: 4 })
        }
        .margin({ left: 12 })
      }
      .layoutWeight(1)
      .onClick(async () => {
        this.showBookmark = false
        await this.avPlayer!.reset();
        this.isPlaying = true
        await this.getPlayContent(this.playingItem!, bookmark.time)
        this.getUIContext().getPromptAction().showToast({
          message: '跳转书签成功！',
          duration: 500
        });
      })

      ImmersiveActionButton({
        barWidth: 40,
        barHeight: 40,
        barRadius: 20,
        onButtonClick: async () => {
          let status = await deleteBookmark(this.playingItem!.libraryItemId, bookmark.time)
          if (status) {
            this.showBookmark = false
            this.getUIContext().getPromptAction().showToast({
              message: '删除书签成功！',
              duration: 500
            });
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '删除书签失败，请检查网络！',
              duration: 500
            });
          }
        }
      }) {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(18)
          .fontColor([Color.Red])
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 15, right: 15 })
    .borderRadius(10)
  }

  @Builder
  bookmarkBuilder() {
    Column() {
      Stack() {
        List() {
          ForEach(this.bookmarks, (bookmark: Bookmark, index) => {
            HdsListItem({
              swipeActionOptions: {
                icons: [
                  {
                    icon: new SymbolGlyphModifier($r('sys.symbol.square_and_pencil')).fontSize(18)
                      .fontColor([$r('sys.color.font')]),
                    backgroundColor: $r('sys.color.comp_background_tertiary'),
                    onAction: () => {
                      this.showBookmark = false
                      this.editBookmarkIndex = index
                      this.tmpBookmarkTitle = bookmark.title
                      this.tmpBookmarkTime = bookmark.time
                      this.showEditBookmark = true
                    }
                  }
                ]
              },
              customItemBuilder: () => this.bookmarkItemBuilder(bookmark, index)
          })
          })

          if (this.bookmarks.length === 0) {
            ListItem() {
              Column() {
                Text("没有书签")
                  .fontSize(24)
              }
            }
            .width('100%')
            .height('100%')
          }
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
        .visibility(!this.showProgress ? Visibility.Visible : Visibility.None)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(45)
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
      .hitTestBehavior(HitTestMode.None)

      Row() {
        TextInput({
          placeholder: this.formatTime(Date.now())
        })
          .width("100%")
          .height(45)
          .layoutWeight(1)
          .borderRadius(10)
          .margin({ right: 15 })
          .caretColor($r('sys.color.font_secondary'))
          .fontSize(18)
          .placeholderFont({
            size: 18
          })
          .type(InputType.Normal)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value) => {
            this.tmpBookmarkTitle = value
          })

        ImmersiveActionButton({
          barWidth: 110,
          barHeight: 45,
          barRadius: 22.5,
          onButtonClick: async () => {
            let time = Date.now()
            let bookmark: Bookmark = {
              libraryItemId: this.playingItem!.libraryItemId,
              title: this.tmpBookmarkTitle.length === 0 ? this.formatTime(time) : this.tmpBookmarkTitle,
              time: this.playingItem!.audioTracks[this.playingIndex].startOffset + this.playedTime,
              createdAt: time
            }
            let status = await createBookmark(this.playingItem!.libraryItemId, bookmark)
            if (status) {
              this.showBookmark = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建书签成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '创建书签失败，请检查网络！',
                duration: 500
              });
            }
          }
        }) {
          Text("创建书签")
            .fontSize(18)
        }
      }
      .padding({ top: 10, bottom: 5 })
      .margin({ left: 20, right: 20, bottom: 20 })
      .borderRadius(10)
    }
  }

  @Builder
  speedBuilder() {
    Scroll() {
      Column() {
        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_50_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("0.5x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("0.5x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_75_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("0.75x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("0.75x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_00_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("1x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_25_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("1.25x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.25x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_50_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("1.5x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.5x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_75_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("1.75x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.75x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_2_00_X) {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            barRadius: 25,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            }
          }) {
            Text("2x")
              .fontSize(18)
          }
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("2x")
              .fontSize(18)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }
      }
      .padding({ left: 20, right: 20, bottom: 25 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  sleepBuilder() {
    Scroll() {
      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("5 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 5 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("10 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 10 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("15 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 15 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("30 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 30 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("45 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 45 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("60 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 60 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("90 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + 90 * 60
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("章节结束")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            this.sleepTime = this.playingItem!.audioTracks[this.playingIndex].startOffset + this.playingItem!.audioTracks[this.playingIndex].duration
            this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("清除定时")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(25)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(() => {
          this.sleepTime = 0
          this.showSleep = false
        })
      }
      .padding({ left: 20, right: 20, bottom: 25 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  chapterBuilder() {
    Column() {
      if (this.isLocalPlaying) {
        List({ scroller: this.chapterScroller }) {
          ForEach(this.localPlayItem!.tracks, (track: LocalTrack, index: number) => {
            ListItem() {
              if (this.playingIndex === index) {
                ImmersiveActionButton({
                  barWidth: '100%',
                  barHeight: 50,
                  barRadius: 25,
                  monopolizeActionEvents: false,
                  onButtonClick: async () => {
                    this.showChapter = false
                    await this.avPlayer!.reset();
                    this.playingIndex = index
                    this.playingTitle = track.title
                    try {
                      const file = fs.openSync(track.filePath, fs.OpenMode.READ_ONLY)
                      try {
                        this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                      } catch (_) {
                        fs.closeSync(file)
                      }
                    } catch (_) {
                      this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                    }
                  }
                }) {
                  Row() {
                    Text(track.title)
                      .fontSize(16)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .padding({ left: 15, right: 15 })
                }
              } else {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Text(track.title)
                      .fontSize(16)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .width('100%')
                .height(50)
                .borderRadius(25)
                .padding({ left: 15, right: 15 })
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  this.showChapter = false
                  await this.avPlayer!.reset();
                  this.playingIndex = index
                  this.playingTitle = track.title
                  try {
                    const file = fs.openSync(track.filePath, fs.OpenMode.READ_ONLY)
                    try {
                      this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                    } catch (_) {
                      fs.closeSync(file)
                    }
                  } catch (_) {
                    this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                  }
                })
              }
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
      } else {
        List({ scroller: this.chapterScroller }) {
          ForEach(this.playingItem!.chapters, (chapter: Chapter, index) => {
            ListItem() {
              if (this.playingIndex === index) {
                ImmersiveActionButton({
                  barWidth: '100%',
                  barHeight: 50,
                  barRadius: 25,
                  monopolizeActionEvents: false,
                  onButtonClick: async () => {
                    this.showChapter = false
                    await this.avPlayer!.reset();
                    this.isPlaying = true
                    this.playingIndex = index
                    this.playingTitle = chapter.title
                    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                  }
                }) {
                  Row() {
                    Text(chapter.title)
                      .fontSize(16)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatSeconds(chapter.start))
                      .fontSize(16)
                      .fontColor($r('sys.color.font_secondary'))
                      .margin({ left: 10 })
                  }
                  .padding({ left: 15, right: 15 })
                }
              } else {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Text(chapter.title)
                      .fontSize(16)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatSeconds(chapter.start))
                      .fontSize(16)
                      .fontColor($r('sys.color.font_secondary'))
                      .margin({ left: 10 })
                  }
                }
                .width('100%')
                .height(50)
                .borderRadius(25)
                .padding({ left: 15, right: 15 })
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  this.showChapter = false
                  await this.avPlayer!.reset();
                  this.isPlaying = true
                  this.playingIndex = index
                  this.playingTitle = chapter.title
                  this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                })
              }
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
      }
    }
  }

  @Builder
  playBuilder() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
            Stack({ alignContent: Alignment.Bottom }) {
              if (!this.isLocalPlaying) {
                Image(this.baseUrl + `/api/items/${this.playingItem?.libraryItemId}/cover?token=${this.apiToken}`)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .geometryTransition("cover")
              } else if (this.localPlayItem?.coverPath) {
                Image(fileUri.getUriFromPath(this.localPlayItem.coverPath))
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .geometryTransition("cover")
              } else {
                Image($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .geometryTransition("cover")
              }

              Stack({ alignContent: Alignment.Bottom }) {
                Column()
                .width('100%')
                .height(200)
                .linearGradient({
                  direction: GradientDirection.Bottom,
                  colors: [[ColorMetrics.rgba(
                    (this.coverColor >>> 16) & 0xff,
                    (this.coverColor >>> 8) & 0xff,
                    this.coverColor & 0xff,
                    0
                  ).color, 0], [this.coverColor, 1]]
                })

              }
              .width('100%')
              .height(200)
            }
            .width('100%')
            .aspectRatio(1)
            .clip(false)

            Stack({ alignContent: Alignment.TopStart }) {
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(this.coverColor)
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

              Column() {
                Column() {
                  Text(this.playingTitle)
                    .width('100%')
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.playColorPalette.primary)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.isLocalPlaying ? "本地文件" :
                    (this.playingItem?.mediaType === 'book' ?
                    this.playingItem?.mediaMetadata.authors?.map(item => item.name).join(", ") :
                    this.playingItem?.displayAuthor))
                    .width('100%')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.playColorPalette.secondary)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 6 })

                  Column() {
                  Row() {
                    Text(this.formatSeconds(this.playedPercent * this.getCurrentDuration() / 100))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.playColorPalette.primary)

                    Text(this.formatSeconds(this.getCurrentDuration()))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.playColorPalette.primary)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ left: 20, right: 20 })

                  Slider({
                    value: this.playedPercent,
                    min: 0,
                    max: 100,
                    step: 0.01,
                    style: this.lockPlayer ? SliderStyle.NONE : SliderStyle.OutSet
                  })
                    .width('100%')
                    .trackThickness(5)
                    .selectedBorderRadius(5)
                    .blockSize({
                      width: 14,
                      height: 14
                    })
                    .padding({ left: this.lockPlayer ? 20 : 10, right: this.lockPlayer ? 20 : 10 })
                    .blockColor(this.playColorPalette.sliderBlock)
                    .trackColor(this.playColorPalette.sliderTrack)
                    .selectedColor(this.playColorPalette.secondary)
                    .sliderInteractionMode(SliderInteraction.SLIDE_AND_CLICK_UP)
                    .onChange((value: number, mode: SliderChangeMode) => {
                      if (mode === SliderChangeMode.Begin) {
                        this.sliderMoving = true
                      }
                      if (mode === SliderChangeMode.End && this.sliderMoving === true) {
                        let dur = this.getCurrentDuration()
                        let seekTime = value * dur * 10
                        if (seekTime < 0) {
                          seekTime = 0
                        } else if (seekTime > dur * 1000) {
                          seekTime = dur * 1000
                        }
                        if (['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) {
                          this.avPlayer!.seek(seekTime)
                        }
                        this.sliderMoving = false
                      }
                    })
                    .hitTestBehavior(this.lockPlayer ? HitTestMode.None : HitTestMode.Default)
                }
                .width('100%')
                }
                .width('100%')

                Row() {
                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.backward_end_fill'))
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex > 0 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex--
                    if (this.isLocalPlaying) {
                      this.playingTitle = this.localPlayItem!.tracks[this.playingIndex].title
                      try {
                        let file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                        this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                      } catch (_) {
                        this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                      }
                    } else {
                      this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
                      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                    }
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.gobackwardIcon)
                      .fontSize(34)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
                    this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
                      .fontSize(34)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(78)
                  .width(78)
                  .margin({ left: 6, right: 6 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(async () => {
                    if (this.isPlaying) {
                      if (this.avPlayer!.state === 'playing') {
                        if (this.playSetting?.fadeInOut) {
                          this.fadeOut()
                        } else {
                          this.avPlayer!.pause()
                        }
                      }
                    } else {
                      if (this.avPlayer!.state === 'error') {
                        this.isPlaying = true
                        const savedPosition = this.playedTime
                        await this.avPlayer!.reset()
                        this.playStartTime = savedPosition
                        if (this.isLocalPlaying) {
                          const file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                          this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                        } else {
                          this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                        }
                        this.avPlayer!.prepare()
                      } else if (['prepared', 'paused', 'completed'].includes(this.avPlayer!.state)) {
                        if (this.playSetting?.fadeInOut) {
                          this.fadeIn()
                        } else {
                          this.avPlayer!.play()
                        }
                      }
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.goforwardIcon)
                      .fontSize(34)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
                    let dur = this.getCurrentDuration()
                    this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < dur ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : dur * 1000)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.forward_end_fill'))
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex < (this.isLocalPlaying ? (this.localPlayItem?.tracks.length ?? 0) : (this.playingItem?.audioTracks.length ?? 0)) - 1 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex++
                    if (this.isLocalPlaying) {
                      this.playingTitle = this.localPlayItem!.tracks[this.playingIndex].title
                      try {
                        let file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                        this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                      } catch (_) {
                        this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                      }
                    } else {
                      this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
                      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                    }
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 10, right: 10 })

                Row() {
                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.bookmark'))
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(!this.isLocalPlaying && this.playingItem?.mediaType === 'book' ? true : false)
                  .onClick(() => {
                    this.tmpBookmarkTitle = ""
                    this.showBookmark = !this.showBookmark;
                  })
                  .bindSheet(this.showBookmark, this.bookmarkBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.REGULAR }),
                    title: {
                      title: "书签 " + this.bookmarks.length
                    },
                    showClose: false,
                    onWillAppear: async () => {
                      this.showProgress = true
                      this.bookmarks = (await getBookmarks(this.user!.id)).filter(bookmark => bookmark.libraryItemId ===
                      this.playingItem!.libraryItemId)
                      this.showProgress = false
                    },
                    onDisappear: () => {
                      this.showBookmark = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.speedIcon)
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showSpeed = !this.showSpeed;
                  })
                  .bindSheet(this.showSpeed, this.speedBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.REGULAR }),
                    title: {
                      title: "速度"
                    },
                    showClose: false,
                    onDisappear: () => {
                      this.showSpeed = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.moon_z'))
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showSleep = !this.showSleep;
                  })
                  .bindSheet(this.showSleep, this.sleepBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.REGULAR }),
                    title: {
                      title: "睡眠定时"
                    },
                    showClose: false,
                    onDisappear: () => {
                      this.showSleep = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.list_bullet'))
                      .fontSize(30)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(!this.isLocalPlaying ? this.playingItem?.mediaType === 'book' : (this.localPlayItem?.tracks.length ?? 0) > 1)
                  .onClick(() => {
                    this.showChapter = !this.showChapter;
                  })
                  .bindSheet(this.showChapter, this.chapterBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.REGULAR }),
                    title: {
                      title: this.isLocalPlaying ? ("章节 " + this.localPlayItem!.tracks.length) : ("章节 " + this.playingItem?.chapters.length)
                    },
                    showClose: false,
                    onWillAppear: () => {
                      this.chapterScroller.scrollToIndex(this.playingIndex, false, ScrollAlign.CENTER)
                    },
                    onDisappear: () => {
                      this.showChapter = false
                    }
                  })
                }
                .width('100%')
                .padding({ left: 20, right: 20 })
                .justifyContent(FlexAlign.SpaceBetween)
                .bindSheet(this.showEditBookmark, this.editBookmarkBuilder(), {
                  height: SheetSize.FIT_CONTENT,
                  preferType: SheetType.CENTER,
                  systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.REGULAR }),
                  title: {
                    title: "编辑书签 " + this.formatSeconds(this.bookmarks[this.editBookmarkIndex]?.time??0)
                  },
                  showClose: false,
                  onDisappear: () => {
                    this.showEditBookmark = false
                  }
                })
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({
                left: 20,
                right: 20,
                bottom: this.windowAvoidArea.navigationIndicator.visible ?
                  this.windowAvoidArea.navigationIndicator.bottomRect.height : 0
              })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(1)
          .clip(false)
        Row() {
          ImmersiveActionButton({
            barWidth: 40,
            barHeight: 40,
            barRadius: 20,
            onButtonClick: () => {
              this.showPlay = false
            }
          }) {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(32)
              .fontColor([this.playColorPalette.secondary])
          }

          Row() {
            Text("睡眠定时 " + ((this.sleepTime !== 0 && !this.isLocalPlaying && this.playingItem!.audioTracks !== undefined) ? this.formatSleepTime(this.sleepTime - this.playedTime - this.playingItem!.audioTracks[this.playingIndex].startOffset) : 0))
              .fontSize(18)
          }
          .height(40)
          .borderRadius(10)
          .padding({ left: 15, right: 15 })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .visibility(this.sleepTime !== 0 ? Visibility.Visible : Visibility.None)

          ImmersiveActionButton({
            barWidth: 40,
            barHeight: 40,
            barRadius: 20,
            menuItems: [{
              symbolIcon: new SymbolGlyphModifier(this.lockPlayer ? $r('sys.symbol.lock') :
                $r('sys.symbol.lock_open')),
              value: this.lockPlayer ? "解锁播放器" : "锁定播放器",
              action: async () => {
                this.lockPlayer = !this.lockPlayer
              }
            }, {
              symbolIcon: new SymbolGlyphModifier($r('sys.symbol.xmark')),
              value: "关闭播放器",
              action: () => {
                this.avPlayer!.stop()
                this.shouldClosePlayer = true
                this.showPlay = false
              }
            }]
          }) {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontSize($r('sys.float.ohos_id_text_size_headline7'))
              .fontColor([this.playColorPalette.secondary])
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: 20,
          right: 20,
          top: (this.windowAvoidArea.statusBar.visible ? this.windowAvoidArea.statusBar.topRect.height : 0) + 8
        })
      }
      .width('100%')
      .height(LayoutPolicy.matchParent)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .clip(false)
  }

  @Builder
  primaryButtonBuilder() {
    Button({ type: ButtonType.Circle }) {
      Stack() {
        Image(this.isLocalPlaying ?
          (this.localPlayItem?.coverPath ? fileUri.getUriFromPath(this.localPlayItem.coverPath) : $rawfile('nocover.jpg')) :
          (this.baseUrl + `/api/items/${this.playingItem?.libraryItemId}/cover?token=${this.apiToken}`))
          .alt($rawfile('nocover.jpg'))
          .objectFit(ImageFit.Cover)
          .width(65)
          .height(65)
          .draggable(false)
          .clipShape(new CircleShape({ width: '100%', height: '100%' }))
          .geometryTransition("cover")
          .rotate({ angle: this.rotateAngle })
          .animation({
            duration: 10,
            curve: Curve.Linear
          })
          .onAppear(() => {
            this.startRotate()
          })

        Progress({ value: this.playedPercent, total: 100, type: ProgressType.Ring })
          .width(71)
          .height(71)
          .style({
            strokeWidth: 3,
            enableSmoothEffect: true
          })
      }
      .width(70)
      .height(70)
    }
    .width(70)
    .height(70)
    .backgroundColor(Color.Transparent)
    .backgroundBlurStyle(BlurStyle.Thin)
    .shadow({
      radius: 10,
      color: $r('sys.color.font')
    })
    .bindContentCover(this.showPlay, this.playBuilder(), {
      onDisappear: () => {
        this.showPlay = false
        if (this.shouldClosePlayer) {
          this.isStartPlaying = false
          this.isPlaying = false
          this.shouldClosePlayer = false
        }
      }
    })
    .onClick(() => {
      this.showPlay = true
      this.changeSpeedIcon()
    })
  }

  goBackwardButton: ActionBarButton = new ActionBarButton({
    baseIcon: this.gobackwardIcon,
    onClick: () => {
      if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
      this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
    }
  })

  stopButton: ActionBarButton = new ActionBarButton({
    baseIcon: $r('sys.symbol.stop_circle'),
    onClick: () => {
      this.avPlayer!.stop()
      if (this.showPlay) {
        this.shouldClosePlayer = true
        this.showPlay = false
      } else {
        this.isStartPlaying = false
        this.isPlaying = false
      }
    }
  })

  playPauseButton: ActionBarButton = new ActionBarButton({
    baseIcon: this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'),
    onClick: async () => {
      if (this.isPlaying) {
        if (this.avPlayer!.state === 'playing') {
          if (this.playSetting?.fadeInOut) {
            this.fadeOut()
          } else {
            this.avPlayer!.pause()
          }
        }
      } else {
        if (this.avPlayer!.state === 'error') {
          this.isPlaying = true
          const savedPosition = this.playedTime
          await this.avPlayer!.reset()
          this.playStartTime = savedPosition
          if (this.isLocalPlaying) {
            const file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
            this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
          } else {
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
          }
          this.avPlayer!.prepare()
        } else if (['paused', 'completed'].includes(this.avPlayer!.state)) {
          if (this.playSetting?.fadeInOut) {
            this.fadeIn()
          } else {
            this.avPlayer!.play()
          }
        }
      }
    }
  })

  goForwardButton: ActionBarButton = new ActionBarButton({
    baseIcon: this.goforwardIcon,
    onClick: () => {
      if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
      let dur = this.getCurrentDuration()
      this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < dur ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : dur * 1000)
    }
  })

  build() {
    Column() {
      HdsActionBar({
        startButtons: [this.goBackwardButton, this.stopButton],
        endButtons: [this.playPauseButton, this.goForwardButton],
        primaryButtonBuilder: (): void => this.primaryButtonBuilder(),
        primaryButtonBuilderWidth: LengthMetrics.vp(70),
        isExpand: true,
        blurStrategy: BlurStrategy.ENABLE,
        actionBarStyle: new ActionBarStyle({
          backgroundColor: new ColorMetrics(),
          backgroundBlurStyle: BlurStyle.COMPONENT_THIN
        })
      })
        .height(0)
        .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
        .margin({ bottom: 108 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .justifyContent(FlexAlign.End)
  }
}
