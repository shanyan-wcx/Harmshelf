import { Episode, Library, LibraryItem, PlayItem, Playlist, PlaylistItem, Progress } from '../utils/Interface';
import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, PersistenceV2, RectShape } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { env } from '../utils/Class';
import { ColorMode } from "../pages/Index";
import { deletePlaylist, getPlayItem, getPlaylists, removeFromPlaylist, updatePlaylist } from '../utils/Api';
import { media } from '@kit.MediaKit';
import { deviceInfo } from '@kit.BasicServicesKit';

let deviceTypeInfo: string = deviceInfo.deviceType;

@Builder
export function playlistDetailBuilder(name: string, param: Object) {
  PlaylistDetail()
}

@ComponentV2
export struct PlaylistDetail {
  private PlaylistDetailScroller: Scroller = new Scroller();
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() playlist1: Playlist | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() library: Library | undefined = undefined
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() playlists: Playlist[] = []
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() statusBarHeight: number = 0
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Local showLoadingProgress: boolean = false
  @Local showPlayLoading: boolean = false
  @Local topHeight: Length = 0
  @Local showEditPlaylist: boolean = false
  @Local tmpPlaylistName: string = ""
  @Local tmpPlaylistDescription: string = ""

  async getPlayContent(playItem: PlayItem) {
    let index: number = 0
    for (let track of playItem.audioTracks) {
      if (track.startOffset > playItem.currentTime) {
        index = track.index - 2
        break
      }
    }
    this.playingIndex = index
    this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
    this.playStartTime = playItem.currentTime - playItem.audioTracks[index].startOffset
    this.avPlayer!.url =
      this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
    console.log("共", playItem.audioTracks.length, "条音轨")
    console.log("播放序号为", this.playingIndex)
    console.log("起始位置为", this.playStartTime)
  }

  get totalDuration(): string {
    if (!this.playlist1) {
      return '0s'
    }
    let totalSec = 0
    const items = this.playlist1.items ?? []
    if (this.library?.mediaType === 'book') {
      totalSec = items.map(item => item?.libraryItem?.media?.duration ?? 0).reduce((a, b) => a + b, 0)
    } else {
      totalSec = items.map(item => item?.episode?.duration ?? 0).reduce((a, b) => a + b, 0)
    }
    const days = Math.floor(totalSec / 86400)
    const hours = Math.floor((totalSec % 86400) / 3600)
    const minutes = Math.floor((totalSec % 3600) / 60)
    const seconds = Math.round(totalSec % 60)
    if (days > 0) {
      return `${days}d ${hours}h ${minutes}m ${seconds}s`
    } else if (hours >
      0) {
      return `${hours}h ${minutes}m ${seconds}s`
    } else if (minutes >
      0) {
      return `${minutes}m ${seconds}s`
    } else {
      return `${seconds}s`
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

  get displayImages(): PlaylistItem[] {
    const len = this.playlist1!.items.length;
    if (len === 0) {
      return [];
    } else if (len === 1) {
      return [this.playlist1!.items[0], this.playlist1!.items[0], this.playlist1!.items[0], this.playlist1!.items[0]];
    } else if (len === 2) {
      return [this.playlist1!.items[0], this.playlist1!.items[1], this.playlist1!.items[1], this.playlist1!.items[0]];
    } else if (len === 3) {
      return [this.playlist1!.items[0], this.playlist1!.items[1], this.playlist1!.items[2], this.playlist1!.items[0]];
    } else {
      return this.playlist1!.items.slice(0, 4);
    }
  }

  @Builder
  playlistEnd(index: number) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .backgroundColor($r('sys.color.warning'))
    .border({
      width: deviceTypeInfo === '2in1' ? 1 : 0,
      color: $r('sys.color.ohos_id_shadow_default_lg_dark')
    })
    .shadow({
      radius: 6,
      color: $r('sys.color.ohos_id_shadow_default_lg_dark')
    })
    .onClick(async () => {
      let playlist: Playlist | undefined = undefined
      if (this.library!.mediaType === 'book') {
        playlist = await removeFromPlaylist(this.playlist1!.id!, this.playlist1!.items![index].libraryItemId)
      } else if (this.library!.mediaType === 'podcast') {
        playlist = await removeFromPlaylist(this.playlist1!.id!, this.playlist1!.items![index].libraryItemId, this.playlist1!.items![index].episodeId!)
      }
      if (playlist) {
        this.playlist1 = playlist
        if (playlist.items.length === 0) {
          this.pageInfos.pop()
        }
        this.playlists = await getPlaylists(this.library!.id)
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: '移除失败，请检查网络！',
          duration: 500
        });
      }
    })
  }

  @Builder
  editPlaylistBuilder() {
    Column() {
      TextInput({
        placeholder: "播放列表名称",
        text: this.tmpPlaylistName
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
          this.tmpPlaylistName = value
        })

      TextArea({
        placeholder: "播放列表描述",
        text: this.tmpPlaylistDescription
      })
        .width("100%")
        .height(120)
        .borderRadius(8)
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
          Text("删除")
            .fontSize(18)
        }
        .backgroundColor($r('sys.color.warning'))
        .height(40)
        .width('50%')
        .layoutWeight(1)
        .borderRadius(8)
        .onClick(async () => {
          let status = await deletePlaylist(this.playlist1!.id!)
          if (status) {
            this.showEditPlaylist = false
            this.getUIContext().getPromptAction().showToast({
              message: '删除成功！',
              duration: 500
            });
            this.pageInfos.pop()
            this.playlists = await getPlaylists(this.library!.id)
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '删除失败，请检查网络！',
              duration: 500
            });
          }
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
          if (this.tmpPlaylistName.length === 0) {
            this.getUIContext().getPromptAction().showToast({
              message: '播放列表名称不能为空！',
              duration: 500
            });
          } else {
            let newPlaylist = await updatePlaylist(this.playlist1!.id!, this.tmpPlaylistName, this.tmpPlaylistDescription)
            if (newPlaylist) {
              this.showEditPlaylist = false
              this.getUIContext().getPromptAction().showToast({
                message: '编辑播放列表成功！',
                duration: 500
              });
              this.playlist1 = newPlaylist
              this.playlists = await getPlaylists(this.library!.id)
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '编辑播放列表失败，请检查网络！',
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
    HdsNavDestination() {
      Stack() {
        Scroll(this.PlaylistDetailScroller) {
          Column() {
            Column() {
              Column() {
                if ((this.playlist1!.items ?? []).length === 1) {
                  Image(this.baseUrl +
                    `/api/items/${this.playlist1!.items[0].libraryItemId}/cover?token=${this.apiToken}`)
                    .alt($rawfile('nocover.jpg'))
                    .objectFit(ImageFit.Cover)
                    .width('100%')
                    .aspectRatio(1)
                    .clip(true)
                    .objectFit(ImageFit.Fill)
                    .draggable(false)
                } else if ((this.playlist1!.items ?? []).length > 1) {
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
              .width((this.sideBarContentWidth - 40) / 2 >= 250 ? 250 : (this.sideBarContentWidth - 40) / 2)
              .aspectRatio(1)
              .borderRadius(10)
              .margin({ bottom: 5 })
              .clip(true)

              if (this.playlist1!.description && this.playlist1!.description.length > 0) {
                Text(this.playlist1!.description)
                  .fontSize(18)
                  .margin({ top: 10 })
                  .padding({ left: 20 , right: 20 })
              }
            }
            .onAreaChange((oldArea, newArea) => {
              this.topHeight = newArea.height
            })

            Column() {
              Row() {
                Column() {
                  Text("播放列表项目 " + this.playlist1!.items.length)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 3 })

                  Text(this.totalDuration)
                    .fontSize(15)
                    .fontColor($r('sys.color.font_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .layoutWeight(1)
                .margin({ right: 10 })
                .alignItems(HorizontalAlign.Start)

                Button({ type: ButtonType.Normal }) {
                  if (this.showPlayLoading) {
                    Column() {
                      LoadingProgress()
                        .width(30)
                        .height(30)
                        .color($r('sys.color.ohos_id_color_titlebar_icon'))
                    }
                  } else {
                    Row() {
                      SymbolGlyph($r('sys.symbol.play_fill'))
                        .fontWeight(FontWeight.Normal)
                        .fontSize(18)
                        .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                        .hitTestBehavior(HitTestMode.None)
                        .margin({ bottom: 1 })

                      Text(" 播放")
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                }
                .backgroundColor($r('sys.color.comp_emphasize_secondary'))
                .height(40)
                .width(100)
                .borderRadius(8)
                .onClick(async () => {
                  this.showPlayLoading = true
                  let id: string | undefined = undefined
                  let id1: string | undefined = undefined
                  if (this.library?.mediaType === 'book') {
                    for (let playlistItem of this.playlist1!.items) {
                      let isFinished =
                        this.progress.find(p => p.libraryItemId === playlistItem.libraryItemId)?.isFinished ?? false
                      if (!isFinished) {
                        id = playlistItem.libraryItemId
                        break
                      }
                    }
                  } else if (this.library?.mediaType === 'podcast') {
                    for (let playlistItem of this.playlist1!.items) {
                      let isFinished =
                        this.progress.find(p => p.episodeId === playlistItem.episodeId)?.isFinished ?? false
                      if (!isFinished) {
                        id = playlistItem.libraryItemId
                        id1 = playlistItem.episodeId!
                        break
                      }
                    }
                  }
                  if (id) {
                    if (this.library?.mediaType === 'book') {
                      this.playingItem = await getPlayItem(id)
                      if (this.playingItem) {
                        await this.avPlayer!.reset();
                        this.isStartPlaying = true
                        this.isPlaying = true
                        await this.getPlayContent(this.playingItem!)
                      }
                    } else if (this.library?.mediaType === 'podcast') {
                      this.playingItem = await getPlayItem(id, id1)
                      if (this.playingItem) {
                        await this.avPlayer!.reset();
                        this.isStartPlaying = true
                        this.isPlaying = true
                        this.playingIndex = 0
                        this.playingTitle = this.playingItem!.displayTitle.trim()
                        this.playStartTime =
                          this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
                        this.avPlayer!.url =
                          this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
                        console.log("共", this.playingItem!.audioTracks.length, "条音轨")
                        console.log("播放序号为", this.playingIndex)
                        console.log("起始位置为", this.playStartTime)
                      }
                    }
                  }
                  this.showPlayLoading = false
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)

              List() {
                ForEach(this.playlist1!.items, (item: PlaylistItem, index) => {
                  ListItem() {
                    Stack() {
                      Row() {
                        Image(this.baseUrl + `/api/items/${item.libraryItemId}/cover?token=${this.apiToken}`)
                          .alt($rawfile('nocover.jpg'))
                          .objectFit(ImageFit.Cover)
                          .width(55)
                          .aspectRatio(1)
                          .borderRadius(8)
                          .margin({ right: 10 })
                          .draggable(false)

                        Column() {
                          Text(this.library?.mediaType === 'book' ? item.libraryItem!.media.metadata.title :
                            item.episode!.title)
                            .fontSize(16)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(this.library?.mediaType === 'book' ?
                            (item.libraryItem!.media.metadata.authorName ?? "-") :
                            (this.libraryItems.find(item1 => item1.id === item.libraryItemId)?.media.metadata.author ??
                              "-"))
                            .fontSize(14)
                            .fontColor($r('sys.color.font_secondary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(this.formatDuration(this.library?.mediaType === 'book' ?
                            item.libraryItem!.media.duration :
                            item.episode!.duration))
                            .fontSize(12)
                            .fontColor($r('sys.color.font_secondary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('100%')
                        .layoutWeight(1)
                        .margin({ right: 10 })
                        .alignItems(HorizontalAlign.Start)

                        Button({ type: ButtonType.Circle }) {
                          SymbolGlyph($r('sys.symbol.play_fill'))
                            .fontWeight(FontWeight.Normal)
                            .fontSize(18)
                            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                            .hitTestBehavior(HitTestMode.None)
                            .margin({ bottom: 1 })
                        }
                        .height(40)
                        .width(40)
                        .backgroundColor($r('sys.color.comp_background_tertiary'))
                        .onClick(async () => {
                          if (this.library?.mediaType === 'book') {
                            this.playingItem = await getPlayItem(item.libraryItemId)
                            if (this.playingItem) {
                              await this.avPlayer!.reset();
                              this.isStartPlaying = true
                              this.isPlaying = true
                              await this.getPlayContent(this.playingItem!)
                            }
                          } else if (this.library?.mediaType === 'podcast') {
                            this.playingItem = await getPlayItem(item.libraryItemId, item.episodeId!)
                            if (this.playingItem) {
                              await this.avPlayer!.reset();
                              this.isStartPlaying = true
                              this.isPlaying = true
                              this.playingIndex = 0
                              this.playingTitle = this.playingItem!.displayTitle.trim()
                              this.playStartTime =
                                this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
                              this.avPlayer!.url =
                                this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
                              console.log("共", this.playingItem!.audioTracks.length, "条音轨")
                              console.log("播放序号为", this.playingIndex)
                              console.log("起始位置为", this.playStartTime)
                            }
                          }
                        })
                      }
                      .padding(10)

                      Progress({
                        value: this.library?.mediaType === 'book' ?
                          (this.progress.find(p => p.libraryItemId === item.libraryItemId)?.progress ?? 0) * 100 :
                          (this.progress.find(p => p.episodeId === item.episodeId)?.progress ?? 0) * 100,
                        total: 100,
                        type: ProgressType.Linear
                      })
                        .width('100%')
                        .color(this.progress.find(p => p.libraryItemId === item.libraryItemId)?.progress === 1 ?
                          $r('sys.color.ohos_id_color_palette4') :
                          $r('sys.color.multi_color_11'))
                        .backgroundColor(Color.Transparent)
                        .style({
                          strokeWidth: 8,
                          strokeRadius: 8
                        })
                        .offset({
                          y: 0.5
                        })
                        .clipShape(new RectShape({
                          width: '100%',
                          height: '4'
                        }).position({
                          y: 4
                        }))
                    }
                    .clip(true)
                    .width('100%')
                    .backgroundColor($r('sys.color.background_secondary'))
                    .borderRadius(8)
                    .margin({ top: index === 0 ? 0 : 10 })
                    .alignContent(Alignment.Bottom)
                    .onClick(() => {
                      if (this.library?.mediaType === 'book') {
                        this.libraryItem = item.libraryItem
                        this.pageInfos.pushPathByName('libraryItemDetail', null)
                      } else {
                        this.episode = item.episode
                        this.pageInfos.pushPathByName('episodeDetail', null)
                      }
                    })
                  }
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.playlistEnd(index)
                      }
                    }
                  })
                })
              }
            }
            .width('100%')
            .margin({ top: 15 })
            .padding({ left: 20, right: 20, bottom: this.isStartPlaying ? 104 : deviceTypeInfo === '2in1' ? 20 : 25 })
            .borderRadius({ topLeft: 32, topRight: 32 })
            .clip(true)
            .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
              env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
              this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
              $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
            .constraintSize({
              minHeight: `calc(100% - ${Number(this.topHeight) + 20}vp)`
            })
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .padding({
          top: 66 + this.statusBarHeight
        })
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

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
    .width('100%')
    .height('100%')
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      content: {
        title: {
          mainTitle: this.playlist1!.name
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.square_and_pencil'),
              label: "编辑",
              action: () => {
                this.tmpPlaylistName = this.playlist1!.name
                this.tmpPlaylistDescription = this.playlist1!.description??""
                this.showEditPlaylist = true
              }
            }
          }]
        }
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          blurEffectiveStartOffset: LengthMetrics.vp(10)
        }
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.PlaylistDetailScroller])
    .bindSheet(this.showEditPlaylist, this.editPlaylistBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: SheetType.CENTER,
      title: {
        title: "编辑播放列表"
      },
      showClose: false,
      onDisappear: () => {
        this.showEditPlaylist = false
      }
    })
  }
}