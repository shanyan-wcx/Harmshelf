import { window, promptAction } from '@kit.ArkUI';
import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { LibraryItem, Chapter, Track, UpdateSession, Progress, PlayItem, Bookmark } from '../api/Interface'
import { closeSession, createBookmark, deleteBookmark, getBookmarks } from '../api/Api'

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

function formatDuration(seconds: number): string {
  const roundedSeconds = Math.floor(seconds);
  const hours = Math.floor(roundedSeconds / 3600);
  const minutes = Math.floor((roundedSeconds % 3600) / 60);
  const secs = roundedSeconds % 60;
  const paddedMinutes = minutes.toString().padStart(2, '0');
  const paddedSeconds = secs.toString().padStart(2, '0');
  let formattedTime = `${paddedMinutes}:${paddedSeconds}`;
  if (hours > 0) {
    const paddedHours = hours.toString().padStart(2, '0');
    formattedTime = `${paddedHours}:${formattedTime}`;
  }
  return formattedTime;
}

function formatTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  const formatNumber = (num: number) => (num < 10 ? `0${num}` : `${num}`);
  return `${formatNumber(hours)}:${formatNumber(minutes)}:${formatNumber(secs)}`;
}

function formatSleepTime(seconds: number): string {
  if (seconds < 60) {
    const roundedSeconds = Math.floor(seconds);
    return `${roundedSeconds} sec`;
  } else if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes} min`;
  } else {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours} hr ${minutes} min`;
  }
}

@Component
export default struct Play {
  @State displayWidth: number = 0
  @State displayHeight: number = 0
  @State statusBarHeight: number = 0
  @State coverWidth: string = "20%"
  @State showChapters: boolean = false
  @State showMenu: boolean = false
  @State showSleep: boolean = false
  @State showSpeed: boolean = false
  @State showBookmark: boolean = false
  @Consume showPlayTransfer: boolean
  @Consume isPlayingTransfer: boolean
  @Consume startPlayingTransfer: boolean
  @Consume itemTransfer: LibraryItem
  @Consume nowPlayingChapters: Chapter[]
  @Consume nowPlayingItem: LibraryItem
  @Consume avPlayer: media.AVPlayer | null
  @Consume playTitle: string
  @Consume nowPlayingDuration: number
  @Consume nowPlayedTime: number
  @Consume startTime: number
  @Consume nowPlayedProgress: number
  @Consume nowPlayingTracks: Track[]
  @Consume nowPlayingIndex: number
  @Consume server: string
  @Consume apitoken: string
  @Consume nowTrackStartTime: number
  @Consume session: AVSessionManager.AVSession | null
  @Consume sessionId: string
  @Consume syncTime: number
  @Consume allProgress: Progress[]
  @Consume playItem: PlayItem | null
  @State mainWindow: window.Window | null = null
  @State showCover: boolean = true
  @State speedValue: number = 0
  @Consume jumpTime: number
  @Consume speed: number
  @Consume speedNumber: number
  @Consume sleepTime: number
  @Consume bookmarks: Bookmark[]
  @Consume nowPlayingBookmarks: Bookmark[]
  @Consume libraryItems: LibraryItem[]
  @State nowTime: string = ''
  @State createBookmarkTitle: string = ''
  @State nowTimeNumber: number = 0
  private bookmarkScroller: Scroller = new Scroller
  @Consume prepared: boolean
  @State progressWidth: number = 0

  @Builder
  bookmarkOperate(index: number) {
    Button({ type: ButtonType.Circle }) {
      Image($rawfile('delete.png'))
        .width(30)
        .height(30)
    }
    .height(40)
    .width(40)
    .margin({ left: 10, right: 10 })
    .backgroundColor('#00000000')
    .onClick(async () => {
      await deleteBookmark(this.nowPlayingItem.id, this.nowPlayingBookmarks[index].time)
      this.bookmarks = await getBookmarks(this.playItem!.userId)
      this.nowPlayingBookmarks = await this.getPlayingBookmarks(this.nowPlayingItem.id)
      this.bookmarkScroller.scrollEdge(Edge.Bottom)
    })
  }

  private getStatusBarHeight() {
    window.getLastWindow(getContext(this), (error, topWindow) => {
      if (topWindow) {
        let area = topWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = px2vp(area.topRect.height)
      }
    });
  }

  async setSessionInfo() {
    let metadata: AVSessionManager.AVMetadata = {
      assetId: '0',
      title: this.nowPlayingChapters[this.nowPlayingIndex].title,
      mediaImage: fileUri.getUriFromPath(filesDir + `/covers/${this.nowPlayingItem.id}.jpg`),
      duration: this.nowPlayingTracks[this.nowPlayingIndex].duration * 1000,
      artist: this.nowPlayingItem.media.metadata.authorName,
      skipIntervals: 10
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

  async getCurrentTime() {
    for (let element of this.allProgress) {
      if (element.libraryItemId === this.nowPlayingItem.id) {
        this.nowTime = formatTime(element.currentTime)
        this.nowTimeNumber = Math.round(element.currentTime)
        break
      }
    }
  }

  async getPlayingBookmarks(itemId: string): Promise<Bookmark[]> {
    let nowPlayingBookmarks: Bookmark[] = []
    this.bookmarks.forEach(element => {
      if (element.libraryItemId === itemId) {
        nowPlayingBookmarks.push(element)
      }
    });
    return nowPlayingBookmarks
  }

  async aboutToAppear() {
    this.mainWindow = await window.getLastWindow(getContext(this))
    this.getStatusBarHeight()
    this.displayWidth = px2vp(this.mainWindow.getWindowProperties().windowRect.width)
    this.displayHeight = px2vp(this.mainWindow.getWindowProperties().windowRect.height)
    console.log("屏幕高度", this.displayHeight)
    if (this.displayHeight < 700) {
      this.showCover = false
    } else if (this.displayWidth >= 320 && this.displayWidth < 550) {
      this.coverWidth = "80%"
    } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
      this.coverWidth = "280"
    } else if (this.displayWidth >= 840) {
      this.coverWidth = "240"
    }
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = px2vp(size.width)
      this.displayHeight = px2vp(size.height)
      console.log("屏幕高度", this.displayHeight)
      if (this.displayHeight < 700) {
        this.showCover = false
      } else if (this.displayWidth >= 320 && this.displayWidth < 550) {
        this.coverWidth = "80%"
        this.showCover = true
      } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
        this.coverWidth = "280"
        this.showCover = true
      } else if (this.displayWidth >= 840) {
        this.coverWidth = "240"
        this.showCover = true
      }
    })
  }

  async getPlayContent(playItem: PlayItem): Promise<string> {
    let index: number = 0
    this.nowPlayingTracks = playItem.audioTracks
    for (let track of playItem.audioTracks) {
      if (track.startOffset > playItem.currentTime) {
        index = track.index - 2
        console.log("找到当前音轨序号为" + index + "，起始位置为" + playItem.audioTracks[index].startOffset)
        break
      }
    }
    let url: string = this.server + playItem.audioTracks[index].contentUrl + "?token=" + this.apitoken
    this.playTitle = playItem.chapters[index].title
    this.nowTrackStartTime = playItem.audioTracks[index].startOffset
    console.log("找到音频Url为", url)
    this.nowPlayingIndex = index
    this.startTime = playItem.currentTime - playItem.audioTracks[index].startOffset
    console.log("起始位置为", this.startTime * 1000)
    return url
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button({ type: ButtonType.Circle }) {
            Image($rawfile('down.png'))
              .width(35)
              .height(35)
          }
          .width(45)
          .height(45)
          .backgroundColor('#00000000')
          .margin({ left: 25 })
          .onClick(() => {
            this.showPlayTransfer = false
          })

          Row() {
            Text("睡眠定时")
              .fontSize(20)
              .fontColor(Color.White)
              .margin({ right: 10 })
            Text(formatSleepTime(this.sleepTime))
              .fontSize(20)
              .fontColor(Color.White)
          }
          .width('auto')
          .height(45)
          .padding({ left: 15, right: 15 })
          .borderRadius(10)
          .backgroundColor('#383838')
          .visibility(this.sleepTime > 0 ? Visibility.Visible : Visibility.None)

          Button({ type: ButtonType.Circle }) {
            Image($rawfile('more.png'))
              .width(35)
              .height(35)
          }
          .width(45)
          .height(45)
          .margin({ right: 10 })
          .backgroundColor('#00000000')
          .onClick(() => {
            this.showMenu = true
          })
        }
        .width("100%")
        .justifyContent(FlexAlign.SpaceBetween)

        Image(this.server + `/api/items/${this.itemTransfer.id}/cover?format=jpeg&width=1024` + `&token=${this.apitoken}`)
          .alt($rawfile('nocover.jpg'))
          .width(this.coverWidth)
          .aspectRatio(1)
          .borderRadius(10)
          .objectFit(ImageFit.Fill)
          .margin({ top: 20 })
          .visibility(this.showCover === true ? Visibility.Visible : Visibility.None)
        Column() {
          Text(this.playTitle)
            .fontSize(28)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.nowPlayingItem.media.metadata.authorName)
            .fontSize(18)
            .fontColor('#E5ECF2')
            .margin({ top: 5 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width("80%")

        Column() {
          Column() {
            Row() {
              Text(formatDuration(this.nowPlayingDuration))
                .fontSize(16)
                .fontColor(Color.White)
              Text("-" + formatDuration(this.nowPlayingDuration - this.nowPlayedTime))
                .fontSize(16)
                .fontColor(Color.White)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            Progress({
              value: this.nowPlayedProgress,
              total: 100,
              type: ProgressType.Linear
            })
              .style({ strokeWidth: 10 })
              .width('100%')
              .margin({ top: 5, bottom: 15 })
              .color(Color.White)
              .onAreaChange((oldValue: Area, newValue: Area) => {
                this.progressWidth = newValue.width as number;
              })
              .gesture(
                GestureGroup(
                  GestureMode.Exclusive,
                  TapGesture({ fingers: 1, count: 1 })
                    .onAction((event: GestureEvent) => {
                      let touchProgress = Math.round((event.fingerList[0].localX / this.progressWidth) * 100)
                      if (touchProgress < 0) {
                        this.nowPlayedProgress = 0
                      } else if (touchProgress >= 100) {
                        this.nowPlayedProgress = 99
                      } else {
                        this.nowPlayedProgress = touchProgress
                      }
                      console.log("触摸进度", this.nowPlayedProgress)
                      this.startTime = this.nowPlayedProgress * this.nowPlayingDuration / 100
                      this.avPlayer!.seek(this.startTime * 1000)
                      this.isPlayingTransfer === true ?
                      this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.startTime) :
                      this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.startTime)
                    })
                )
              )
          }
          .width('100%')

          Row() {
            Button({ type: ButtonType.Circle }) {
              Image($rawfile('previous.png'))
                .width(35)
                .height(35)
            }
            .width(45)
            .height(45)
            .backgroundColor('#00000000')
            .onClick(async () => {
              await this.avPlayer!.reset();
              if (this.nowPlayingIndex - 1 < 0) {
                promptAction.showToast({
                  message: '已经是第一个',
                  duration: 500
                });
              } else {
                this.nowPlayingIndex--
                this.playTitle = this.nowPlayingChapters[this.nowPlayingIndex].title
                this.startTime = 0
                this.nowTrackStartTime = this.nowPlayingTracks[this.nowPlayingIndex].startOffset
                this.avPlayer!.url =
                  this.server + this.nowPlayingTracks[this.nowPlayingIndex].contentUrl + "?token=" + this.apitoken
                this.isPlayingTransfer === true ?
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.startTime) :
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.startTime)
              }
            })

            Button({ type: ButtonType.Circle }) {
              Image(this.jumpTime === 10 ? $rawfile('rewind_10.png') : $rawfile('rewind_30.png'))
                .width(45)
                .height(45)
            }
            .width(60)
            .height(60)
            .margin({ right: 10 })
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
              Image(this.isPlayingTransfer === true ? $rawfile('suspend.png') : $rawfile('play.png'))
                .width(40)
                .height(40)
            }
            .width(70)
            .height(70)
            .backgroundColor('#383838')
            .onClick(() => {
              this.isPlayingTransfer = !this.isPlayingTransfer
              if (this.isPlayingTransfer === false) {
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
                .width(45)
                .height(45)
            }
            .width(60)
            .height(60)
            .margin({ left: 10 })
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

            Button({ type: ButtonType.Circle }) {
              Image($rawfile('next.png'))
                .width(35)
                .height(35)
            }
            .width(45)
            .height(45)
            .backgroundColor('#00000000')
            .onClick(async () => {
              await this.avPlayer!.reset();
              if (this.nowPlayingIndex + 1 > this.nowPlayingTracks.length - 1) {
                promptAction.showToast({
                  message: '已经是最后一个',
                  duration: 500
                });
              } else {
                this.nowPlayingIndex++
                this.playTitle = this.nowPlayingChapters[this.nowPlayingIndex].title
                this.startTime = 0
                this.nowTrackStartTime = this.nowPlayingTracks[this.nowPlayingIndex].startOffset
                this.avPlayer!.url =
                  this.server + this.nowPlayingTracks[this.nowPlayingIndex].contentUrl + "?token=" + this.apitoken
                this.isPlayingTransfer === true ?
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.startTime) :
                this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.startTime)
              }

            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Button({ type: ButtonType.Circle }) {
              Image($rawfile('bookmark.png'))
                .width(35)
                .height(35)
            }
            .width(35)
            .height(35)
            .backgroundColor('#00000000')
            .onClick(async () => {
              await this.getCurrentTime()
              this.showBookmark = true
            })

            Button({ type: ButtonType.Circle }) {
              Image($rawfile('speed.png'))
                .width(35)
                .height(35)
            }
            .width(35)
            .height(35)
            .backgroundColor('#00000000')
            .onClick(() => {
              this.showSpeed = true
            })

            Button({ type: ButtonType.Circle }) {
              Image($rawfile('sleep.png'))
                .width(35)
                .height(35)
            }
            .width(35)
            .height(35)
            .backgroundColor('#00000000')
            .onClick(() => {
              this.showSleep = true
            })

            Button({ type: ButtonType.Circle }) {
              Image($rawfile('list2.png'))
                .width(35)
                .height(35)
            }
            .width(35)
            .height(35)
            .backgroundColor('#00000000')
            .onClick(() => {
              this.showChapters = true
            })
          }
          .width('100%')
          .margin({ top: 10 })
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('80%')
        .height(240)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ bottom: 20 })
        .offset({
          y: -20
        })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.SpaceEvenly)
      .backgroundColor('#232323')
      .padding({ top: this.statusBarHeight })

      Column() {
        Column() {
          Column() {
            Text("清除睡眠定时")
              .width('100%')
              .height(60)
              .textAlign(TextAlign.Center)
              .border({
                radius: 10
              })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(20)
              .fontColor(Color.White)
              .backgroundColor('#333333')
              .onClick(async () => {
                this.showMenu = false
                this.sleepTime = 0
              })
          }
          .width('80%')
          .height('auto')
          .borderRadius(10)
          .backgroundColor('#333333')

          Column() {
            Text("关闭播放器")
              .width('100%')
              .height(60)
              .textAlign(TextAlign.Center)
              .border({
                radius: 10
              })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(20)
              .fontColor(Color.White)
              .backgroundColor('#333333')
              .onClick(async () => {
                this.showMenu = false
                this.sleepTime = 0
                this.isPlayingTransfer = false
                this.showPlayTransfer = false
                this.startPlayingTransfer = false
                this.avPlayer!.stop()
                await this.stopContinuousTask();
                await this.session!.destroy()
                console.log("Session已销毁。")
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
                    userId: this.playItem!.userId,
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
              })
          }
          .width('80%')
          .height('auto')
          .borderRadius(10)
          .backgroundColor('#333333')
        }
        .width('80%')
        .height('auto')
        .borderRadius(10)
        .backgroundColor('#333333')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showMenu = false
      })
      .visibility(this.showMenu === true ? Visibility.Visible : Visibility.None)

      Column() {
        Column() {
          List({ scroller: this.bookmarkScroller, initialIndex: this.nowPlayingBookmarks.length - 1 }) {
            ForEach(this.nowPlayingBookmarks, (item: Bookmark, index) => {
              ListItem() {
                Row() {
                  Text(formatTime(item.time))
                    .fontSize(16)
                    .fontColor(Color.Gray)
                    .textAlign(TextAlign.Center)
                    .width(65)
                  Text(item.title)
                    .fontSize(20)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Start)
                    .width('100%')
                    .margin({ left: 15 })
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .height(50)
                .padding({ left: 20, right: 20 })
                .justifyContent(FlexAlign.SpaceBetween)
                .onClick(async () => {
                  await this.avPlayer!.reset()
                  this.playItem!.currentTime = item.time
                  console.log("准备跳转书签时间", this.playItem!.currentTime)
                  let url: string = await this.getPlayContent(this.playItem!)
                  this.avPlayer!.url = url
                  this.isPlayingTransfer === true ?
                  this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.startTime) :
                  this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.startTime)
                  this.showBookmark = false
                })
              }
              .width('100%')
              .borderRadius(10)
              .backgroundColor('#333333')
              .swipeAction({
                end: {
                  builder: () => {
                    this.bookmarkOperate(index)
                  },
                }
              })
            })
          }
          .width('100%')
          .height(350)
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          Row() {
            Text(this.nowTime)
              .fontSize(16)
              .fontColor(Color.Gray)
              .textAlign(TextAlign.Center)
              .width(65)
            TextInput({ text: $$this.createBookmarkTitle, placeholder: "书签标题" })
              .width('100%')
              .layoutWeight(1)
              .height(40)
              .margin({ left: 15 })
              .border({
                width: 2,
                radius: 5,
                color: Color.White
              })
              .placeholderColor(Color.Gray)
              .caretColor(Color.White)
              .fontColor(Color.White)
            Button({ type: ButtonType.Normal }) {
              Text("创建")
                .fontSize(20)
                .fontColor(Color.White)
            }
            .backgroundColor(Color.Green)
            .width(60)
            .height(40)
            .margin({ left: 15 })
            .borderRadius(5)
            .onClick(async () => {
              if(this.createBookmarkTitle!==''){
                let bookmark: Bookmark = {
                  libraryItemId: this.nowPlayingItem.id,
                  title: this.createBookmarkTitle,
                  time: this.nowTimeNumber,
                  createdAt: Math.round(new Date().getTime() / 1000)
                }
                await createBookmark(this.nowPlayingItem.id, bookmark)
                this.bookmarks = await getBookmarks(this.playItem!.userId)
                this.nowPlayingBookmarks = await this.getPlayingBookmarks(this.nowPlayingItem.id)
                this.bookmarkScroller.scrollEdge(Edge.Bottom)
                this.createBookmarkTitle = ''
              }else {
                promptAction.showToast({
                  message: '书签标题不能为空',
                  duration: 500
                });
              }
            })
          }
          .width('100%')
          .height(60)
          .padding({ left: 20, right: 15 })
          .backgroundColor('#232323')
          .onClick(() => {
          })
        }
        .width('80%')
        .height(400)
        .borderRadius(10)
        .clip(true)
        .backgroundColor('#333333')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showBookmark = false
      })
      .visibility(this.showBookmark === true ? Visibility.Visible : Visibility.None)

      Column() {
        Column() {
          Text("0.125x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_125_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_125_X
              this.speedNumber = 0.125
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("0.25x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_25_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_25_X
              this.speedNumber = 0.25
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("0.5x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_50_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
              this.speedNumber = 0.5
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("0.75x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_75_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
              this.speedNumber = 0.75
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("1.0x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_00_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
              this.speedNumber = 1
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("1.25x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_25_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
              this.speedNumber = 1.25
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("1.5x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_50_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
              this.speedNumber = 1.5
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("1.75x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_75_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
              this.speedNumber = 1.75
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
          Text("2.0x")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_2_00_X ? '#232323' : '#333333')
            .onClick(async () => {
              this.showSpeed = false
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
              this.speedNumber = 2
              this.avPlayer!.setSpeed(this.speed)
              await this.setPlaybackState(this.isPlayingTransfer === true ?
              AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY : AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE,
                this.nowPlayedTime)
            })
        }
        .width('80%')
        .height('auto')
        .borderRadius(10)
        .backgroundColor('#333333')
        .onClick(() => {
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showSpeed = false
      })
      .visibility(this.showSpeed === true ? Visibility.Visible : Visibility.None)

      Column() {
        Column() {
          Text("5分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 300
            })
          Text("10分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 600
            })
          Text("15分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 900
            })
          Text("30分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 1800
            })
          Text("45分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 2700
            })
          Text("60分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 3600
            })
          Text("90分钟")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 5400
            })
          Text("2小时")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = 7200
            })
          Text("章节结尾")
            .width('100%')
            .height(50)
            .textAlign(TextAlign.Center)
            .border({
              radius: 10
            })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#333333')
            .onClick(async () => {
              this.showSleep = false
              this.sleepTime = (this.nowPlayingDuration - this.nowPlayedTime) / this.speed
            })
        }
        .width('80%')
        .height('auto')
        .borderRadius(10)
        .backgroundColor('#333333')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showSleep = false
      })
      .visibility(this.showSleep === true ? Visibility.Visible : Visibility.None)

      Column() {
        Column() {
          List() {
            ForEach(this.nowPlayingChapters, (item: Chapter, index) => {
              ListItem() {
                Row() {
                  Text(this.nowPlayingChapters[index].title)
                    .width('100%')
                    .layoutWeight(1)
                    .margin({ left: 15 })
                    .padding({ right: 10 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(16)
                    .fontColor(Color.White)
                  Text(formatDuration(this.nowPlayingChapters[index].start))
                    .width(65)
                    .margin({ right: 15 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(16)
                    .fontColor(Color.Gray)
                    .textAlign(TextAlign.End)
                }
                .width('100%')
                .height(50)
                .justifyContent(FlexAlign.SpaceBetween)
                .borderRadius(10)
                .backgroundColor(index === this.nowPlayingIndex ? '#232323' : '#333333')
                .onClick(async () => {
                  await this.avPlayer!.reset();
                  this.nowPlayingIndex = index
                  this.playTitle = this.nowPlayingChapters[index].title
                  this.startTime = 0
                  this.nowTrackStartTime = this.nowPlayingTracks[index].startOffset
                  this.avPlayer!.url =
                    this.server + this.nowPlayingTracks[index].contentUrl + "?token=" + this.apitoken
                  this.showChapters = false
                  this.isPlayingTransfer === true ?
                  this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY, this.startTime) :
                  this.setPlaybackState(AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE, this.startTime)
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .borderRadius(10)
          .scrollBar(BarState.Off)
        }
        .width('80%')
        .height('60%')
        .borderRadius(10)
        .backgroundColor('#333333')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showChapters = false
      })
      .visibility(this.showChapters === true ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}
