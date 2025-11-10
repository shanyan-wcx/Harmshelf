import { HdsActionBar, ActionBarButton, HdsListItem } from '@kit.UIDesignKit'
import { Author, Bookmark, Chapter, Library, PlayItem, User } from '../utils/Interface'
import { CircleShape, LengthMetrics, PersistenceV2, SymbolGlyphModifier, TextModifier } from '@kit.ArkUI'
import { common, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { CountdownTimer, env } from '../utils/Class';
import { deviceInfo } from "@kit.BasicServicesKit";
import { createBookmark, deleteBookmark, getBookmarks } from '../utils/Api';
import { PlaySetting } from './Index';
import { media } from '@kit.MediaKit';
import { HmParseHTML, Node } from '@wuyan/html_parse';

let deviceTypeInfo: string = deviceInfo.deviceType;

@ComponentV2
export struct Play {
  private chapterScroller: Scroller = new Scroller();
  @Consumer() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Consumer() displayWidth: number = 0
  @Consumer() displayHeight: number = 0
  @Consumer() statusBarHeight: number = 0;
  @Consumer() isPlaying: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() showPlay: boolean = false
  @Consumer() library: Library | undefined = undefined
  @Consumer() playingItem: PlayItem | undefined = undefined
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
  @Consumer() sleepTime: number = 0
  @Consumer() sliderMoving: boolean = false
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() sleepController: CountdownTimer | undefined = undefined
  @Local rotateAngle: number = 0
  @Local sliderValue: number = 0
  @Local lockPlayer: boolean = false
  @Local showProgress: boolean = false
  @Local showBookmark: boolean = false
  @Local showSpeed: boolean = false
  @Local showSleep: boolean = false
  @Local showChapter: boolean = false
  @Local speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @Local speedIcon: Resource = $r('sys.symbol.speed_100percent')
  @Local tmpBookmarkTitle: string = ""
  @Local tmpBookmarkTime: number = 0
  @Local showEditBookmark: boolean = false
  @Local editBookmarkIndex: number = 0
  @Local maxIntroLine: number = 5
  @Local showMoreIntro: boolean = false

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
      this.sleepTime = 0
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

  setSleepTime() {
    if (!this.sleepController) {
      this.sleepController = new CountdownTimer(this.sleepTime, () => {
        if (this.playSetting?.fadeInOut) {
          this.fadeOut()
        } else {
          this.avPlayer!.pause()
        }
        this.sleepTime = 0
      }, (remain) => {
        if (this.sleepTime !== 0) {
          this.sleepTime = remain
        }
      })
      this.sleepController.start()
    } else {
      this.sleepController.reset(this.sleepTime)
      this.sleepController.start()
    }
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

  async getPlayContent(playItem: PlayItem, time: number) {
    let index: number = 0
    for (let track of playItem.audioTracks) {
      if (track.startOffset > time) {
        index = track.index - 2
        break
      }
    }
    this.playingIndex = index
    this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
    this.playStartTime = time - playItem.audioTracks[index].startOffset
    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
    console.log("共", playItem.audioTracks.length, "条音轨")
    console.log("播放序号为", this.playingIndex)
    console.log("起始位置为", this.playStartTime)
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
        .borderRadius(8)
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
        .borderRadius(8)
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
        .borderRadius(8)
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
  bookmarkBuilder() {
    Column() {
      Stack() {
        List() {
          ForEach(this.bookmarks, (bookmark: Bookmark, index) => {
            HdsListItem({
              hdsListItemCard: {
                cardBorderRadius: 8,
                cardBackgroundColor: Color.Transparent,
                textItem: {
                  primaryText: {
                    text: bookmark.title.length === 0 ? this.formatTime(bookmark.createdAt) : bookmark.title,
                    modifier: new TextModifier().fontSize(16)
                  },
                  primaryPrefixSymbol: {
                    symbol: $r('sys.symbol.bookmark')
                  },
                  secondaryText: {
                    text: this.formatSeconds(bookmark.time),
                    modifier: new TextModifier().fontSize(16).fontColor($r('sys.color.font_secondary'))
                  },
                  secondaryPrefixSymbol: {
                    symbol: $r('sys.symbol.clock')
                  }
                },
                onClick: async () => {
                  this.showBookmark = false
                  await this.avPlayer!.reset();
                  this.isPlaying = true
                  await this.getPlayContent(this.playingItem!, bookmark.time)
                  this.getUIContext().getPromptAction().showToast({
                    message: '跳转书签成功！',
                    duration: 500
                  });
                }
              },
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
                ],
                deleteIconOptions: {
                  backgroundColor: $r('sys.color.warning'),
                  onAction: async () => {
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
                }
              }
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
        .borderRadius(8)
        .clip(true)
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
      .hitTestBehavior(HitTestMode.None)

      Row() {
        TextInput({
          placeholder: this.formatTime(Date.now())
        })
          .width("100%")
          .height(45)
          .layoutWeight(1)
          .borderRadius(8)
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

        Button({ type: ButtonType.Normal }) {
          Text("创建书签")
            .fontSize(18)
        }
        .height(45)
        .borderRadius(8)
        .padding({ left: 15, right: 15 })
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(async () => {
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
        })
      }
      .padding({ top: 10, bottom: 5 })
      .margin({ left: 20, right: 20, bottom: 20 })
      .borderRadius(8)
    }
  }

  @Builder
  speedBuilder() {
    Scroll() {
      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("0.5x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_50_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
          this.speedIcon = $r('sys.symbol.speed_50percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("0.75x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_75_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
          this.speedIcon = $r('sys.symbol.speed_75percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("1x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_00_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
          this.speedIcon = $r('sys.symbol.speed_100percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("1.25x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_25_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
          this.speedIcon = $r('sys.symbol.speed_125percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("1.5x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_50_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
          this.speedIcon = $r('sys.symbol.speed_150percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("1.75x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_75_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
          this.speedIcon = $r('sys.symbol.speed_175percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("2x")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(this.speed === media.PlaybackSpeed.SPEED_FORWARD_2_00_X ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
        .onClick(() => {
          this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
          this.speedIcon = $r('sys.symbol.speed_200percent')
          this.avPlayer!.setSpeed(this.speed)
          this.showSpeed = false
        })
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
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 5 * 60
          this.sleepController
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("10 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 10 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("15 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 15 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("30 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 30 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("45 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 45 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("60 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 60 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("90 min")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = 90 * 60
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("章节结束")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.sleepTime = this.playingItem!.audioTracks[this.playingIndex].duration - this.playedTime
          this.setSleepTime()
          this.showSleep = false
        })

        Button({ type: ButtonType.Normal }) {
          Text("清除定时")
            .fontSize(18)
        }
        .width('100%')
        .height(50)
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(() => {
          this.sleepTime = 0
          this.sleepController?.clear()
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
      List({ scroller: this.chapterScroller }) {
        ForEach(this.playingItem!.chapters, (chapter: Chapter, index) => {
          ListItem() {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text(chapter.title)
                  .fontSize(18)
                  .width('100%')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(this.formatSeconds(chapter.start))
                  .fontSize(18)
                  .fontColor($r('sys.color.font_secondary'))
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .height(50)
            .borderRadius(8)
            .padding({ left: 15, right: 15 })
            .backgroundColor(this.playingIndex === index ? $r('sys.color.comp_emphasize_secondary') : Color.Transparent)
            .onClick(async () => {
              this.showChapter = false
              await this.avPlayer!.reset();
              this.isPlaying = true
              this.playingIndex = index
              this.playingTitle = chapter.title
              this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
            })
          }
        })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, bottom: 25 })
      .scrollBar(BarState.Off)
      .borderRadius(8)
      .clip(true)
    }
  }

  @Builder
  playBuilder() {
    Column() {
      GridRow({
        columns: {
          xs: 1,
          sm: 2,
        },
        breakpoints: {
          value: ['1000vp'],
          reference: BreakpointsReference.WindowSize
        },
        gutter: {
          x: 20
        }
      }) {
        GridCol({ span: 1 }) {
          Column() {
            Row() {
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.chevron_down'))
                  .fontSize(32)
                  .fontColor([$r('sys.color.font_secondary')])
              }
              .height(40)
              .width(40)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showPlay = false
              })

              Row() {
                Text("睡眠定时 " + this.formatSleepTime(this.sleepTime))
                  .fontSize(18)
              }
              .height(40)
              .borderRadius(8)
              .padding({ left: 15, right: 15 })
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .visibility(this.sleepTime !== 0 ? Visibility.Visible : Visibility.None)

              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
                  .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                  .fontColor([$r('sys.color.font_secondary')])
              }
              .height(40)
              .width(40)
              .backgroundColor(Color.Transparent)
              .bindMenu([{
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
                }
              }])
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 25 })
            .padding({ left: 20, right: 20 })

            Column() {
              if (this.displayHeight >= 700) {
                Image(this.baseUrl + `/api/items/${this.playingItem!.libraryItemId}/cover?token=${this.apiToken}`)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width(deviceTypeInfo === '2in1' ?
                    (((this.displayWidth / 2) - 60) > (this.displayHeight / 2) ? this.displayHeight / 2 : '100%') :
                    '100%')
                  .aspectRatio(1)
                  .borderRadius(10)
                  .draggable(false)
                  .geometryTransition("cover")
                  .margin({ bottom: 40 })
              }

              Column() {
                Text(this.playingTitle)
                  .width('100%')
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 5 })
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(this.library?.mediaType === 'book' ?
                  this.playingItem?.mediaMetadata.authors?.map(item => item.name).join(", ") :
                  this.playingItem!.displayAuthor)
                  .width('100%')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font_secondary'))
                  .textAlign(TextAlign.Center)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .margin({ bottom: 30 })
              .padding({ left: 20, right: 20 })
              .alignItems(HorizontalAlign.Center)

              Column() {
                Column() {
                  Row() {
                    Text(this.formatSeconds(this.playedPercent * this.playingItem!.audioTracks[this.playingIndex].duration / 100))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)

                    Text(this.formatSeconds(this.playingItem!.audioTracks[this.playingIndex].duration))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ bottom: -10 })
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
                    .blockColor($r('app.color.sliderBlock'))
                    .selectedColor($r('sys.color.font_secondary'))
                    .sliderInteractionMode(SliderInteraction.SLIDE_AND_CLICK_UP)
                    .onChange((value: number, mode: SliderChangeMode) => {
                      if (mode === SliderChangeMode.Begin) {
                        this.sliderMoving = true
                      }
                      if (mode === SliderChangeMode.End && this.sliderMoving === true) {
                        let seekTime = value * this.playingItem!.audioTracks[this.playingIndex].duration * 10
                        if (seekTime < 0) {
                          seekTime = 0
                        } else if (seekTime > this.playingItem!.audioTracks[this.playingIndex].duration * 1000) {
                          seekTime = this.playingItem!.audioTracks[this.playingIndex].duration * 1000
                        }
                        this.avPlayer!.seek(seekTime)
                        this.sliderMoving = false
                      }
                    })
                    .hitTestBehavior(this.lockPlayer ? HitTestMode.None : HitTestMode.Default)
                }
                .width('100%')

                Row() {
                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.backward_end_fill'))
                      .fontSize(30)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex > 0 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex--
                    this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
                    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.gobackwardIcon)
                      .fontSize(34)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
                      .fontSize(34)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(78)
                  .width(78)
                  .margin({ left: 6, right: 6 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(() => {
                    if (this.isPlaying) {
                      if (this.playSetting?.fadeInOut) {
                        this.fadeOut()
                      } else {
                        this.avPlayer!.pause()
                      }
                    } else {
                      if (this.playSetting?.fadeInOut) {
                        this.fadeIn()
                      } else {
                        this.avPlayer!.play()
                      }
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.goforwardIcon)
                      .fontSize(34)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < this.playingItem!.audioTracks[this.playingIndex].duration ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : this.playingItem!.audioTracks[this.playingIndex].duration * 1000)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.forward_end_fill'))
                      .fontSize(30)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex < this.playingItem!.audioTracks.length - 1 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex++
                    this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
                    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
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
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.library?.mediaType === 'book' ? true : false)
                  .onClick(() => {
                    this.tmpBookmarkTitle = ""
                    this.showBookmark = !this.showBookmark;
                  })
                  .bindSheet(this.showBookmark, this.bookmarkBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
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
                      .fontColor([$r('sys.color.font_secondary')])
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
                      .fontColor([$r('sys.color.font_secondary')])
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
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.library?.mediaType === 'book' ? true : false)
                  .onClick(() => {
                    this.showChapter = !this.showChapter;
                  })
                  .bindSheet(this.showChapter, this.chapterBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
                    title: {
                      title: "章节 " + this.playingItem?.chapters.length
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
              .layoutWeight(1)
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
            .padding({
              bottom: deviceTypeInfo === '2in1' ? 0 : 10,
              left: 20,
              right: 20,
            })
          }
        }

        if (this.displayWidth >= 1000) {
          GridCol({ span: 1 }) {
            Column() {
              Text("没想好放什么")
                .fontSize(32)
            }
            .width('100%')
            .height('100%')
            .margin({ bottom: 20 })
            .justifyContent(FlexAlign.Center)
          }
          .padding({
            bottom: deviceTypeInfo === '2in1' ? 0 : 10,
            left: 20,
            right: 20,
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundImage(this.baseUrl + `/api/items/${this.playingItem!.libraryItemId}/cover?token=${this.apiToken}`)
    .backgroundImageSize(ImageSize.FILL)
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundBrightness({
      rate: env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 0.2 : 0.5,
      lightUpDegree: env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 0.1 : 0.5
    })
    .padding({ top: this.statusBarHeight + 20, bottom: 20 })
  }

  @Builder
  primaryButtonBuilder() {
    Button({ type: ButtonType.Circle }) {
      Stack() {
        Image(this.baseUrl + `/api/items/${this.playingItem!.libraryItemId}/cover?token=${this.apiToken}`)
          .alt($rawfile('nocover.jpg'))
          .objectFit(ImageFit.Cover)
          .width(65)
          .height(65)
          .draggable(false)
          .clipShape(new CircleShape({ width: '100%', height: '100%' }))
          .geometryTransition("cover")
          .animation({
            duration: 10,
            curve: Curve.Linear,
            iterations: 1,
            onFinish: () => {
              this.rotateAngle = this.rotateAngle + 0.1
            }
          })
          .rotate({ angle: this.rotateAngle })
          .onAppear(() => {
            this.rotateAngle = 0.1
          })

        Progress({ value: this.playedPercent, total: 100, type: ProgressType.Ring })
          .width(71)
          .height(71)
          .style({
            strokeWidth: 3
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
      radius: 8,
      color: $r('sys.color.font')
    })
    .bindContentCover(this.showPlay, this.playBuilder(), {
      onDisappear: () => {
        this.showPlay = false
      }
    })
    .onClick(() => {
      this.showPlay = true
    })
  }

  build() {
    Column() {
      HdsActionBar({
        startButtons: [new ActionBarButton({
          baseIcon: this.gobackwardIcon,
          onClick: () => {
            this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ?
              (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
          }
        }), new ActionBarButton({
          baseIcon: $r('sys.symbol.stop_circle'),
          onClick: () => {
            this.avPlayer!.stop()
          }
        })],
        endButtons: [new ActionBarButton({
          baseIcon: this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'),
          onClick: () => {
            if (this.isPlaying) {
              if (this.playSetting?.fadeInOut) {
                this.fadeOut()
              } else {
                this.avPlayer!.pause()
              }
            } else {
              if (this.playSetting?.fadeInOut) {
                this.fadeIn()
              } else {
                this.avPlayer!.play()
              }
            }
          }
        }), new ActionBarButton({
          baseIcon: this.goforwardIcon,
          onClick: () => {
            this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals <
            this.playingItem!.audioTracks[this.playingIndex].duration ?
              (this.playedTime + this.playSetting!.skipIntervals) * 1000 :
              this.playingItem!.audioTracks[this.playingIndex].duration * 1000)
          }
        })],
        primaryButtonBuilder: (): void => this.primaryButtonBuilder(),
        primaryButtonBuilderWidth: LengthMetrics.vp(70),
        isExpand: true
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