import {
  AudioFile,
  Author,
  Chapter,
  Episode,
  Library,
  LibraryItem,
  Progress,
  PlayItem,
  Filter1,
  Series,
  UpdateProgress,
  Playlist,
  Collection,
  Collection1
} from "../utils/Interface";
import { HdsNavDestination, HdsNavDestinationAttribute } from "@kit.UIDesignKit";
import { LengthMetrics, SymbolGlyphModifier } from "@kit.ArkUI";
import {
  addToCollection,
  addToPlaylist,
  createCollection,
  createPlaylist,
  getCollections,
  getItem, getPlayItem, getPlaylists, getUser,
  removeFromCollection,
  removeFromPlaylist,
  updateProgress } from "../utils/Api";
import { EpisodeComponent1 } from "../utils/Component";
import { media } from "@kit.MediaKit";

@Builder
export function libraryItemDetailBuilder(name: string, param: Object) {
  LibraryItemDetail()
}

@ComponentV2
export struct LibraryItemDetail {
  private libraryDetailScroller: Scroller = new Scroller();
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() displayWidth: number = 0
  @Consumer() displayHeight: number = 0
  @Consumer() statusBarHeight: number = 0
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() playlists: Playlist[] = []
  @Consumer() collections: Collection[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() series1: Series | undefined = undefined
  @Consumer() series: Series[] = []
  @Consumer() playStartTime: number = 0
  @Consumer() syncTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.libraryItemId === this.libraryItem!.id)
  @Local maxIntroLine: number = 5
  @Local showMoreIntro: boolean = false
  @Local showChapters: boolean = false
  @Local showAudioFiles: boolean = false
  @Local order: boolean = true
  @Local episodes: Episode[] = []
  @Local sortBy: number = 0
  @Local sortByStr: string = "出版日期"
  @Local contentHeight: number = 158
  @Local showLoadingProgress: boolean = false
  @Local moreMenus: MenuElement[] = []
  @Local showPlayLoading: boolean = false
  @Local showConfirm: boolean = false
  @Local showPlaylists: boolean = false
  @Local showProgress: boolean = false
  @Local showCreatePlaylist: boolean = false
  @Local tmpPlaylistName: string = ""
  @Local tmpPlayingItem: PlayItem | undefined = undefined
  @Local tmpPlayingIndex: number = 0
  @Local showCollections: boolean = false
  @Local showCreateCollection: boolean = false
  @Local tmpCollectionName: string = ""
  @Local tmpCollectionItem: PlayItem | undefined = undefined
  @Monitor('syncTime')
  async refreshProgress(monitor: IMonitor) {
    this.itemProgress = undefined
    this.itemProgress = this.progress.find(p => p.libraryItemId === this.libraryItem!.id)
    this.updateMoreMenus()
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
    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
    console.log("共", playItem.audioTracks.length, "条音轨")
    console.log("播放序号为", this.playingIndex)
    console.log("起始位置为", this.playStartTime)
  }

  updateMoreMenus() {
    this.moreMenus = []
    if (this.library?.mediaType === 'book') {
      if (!this.itemProgress?.isFinished) {
        this.moreMenus.push({
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_square')) ,
          value: "标记为已听完",
          action: async () => {
            let tmpProgress: UpdateProgress = {
              duration: this.libraryItem!.media.duration,
              currentTime: this.libraryItem!.media.duration,
              progress: 1,
              isFinished: true
            }
            let status = await updateProgress(tmpProgress, this.libraryItem!.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.libraryItemId === this.libraryItem!.id)
            }
            this.updateMoreMenus()
          }
        })
      }
      if (this.itemProgress && this.itemProgress.currentTime > 0) {
        this.moreMenus.push({
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.delete_left')),
          value: "放弃进度",
          action: async () => {
            let tmpProgress: UpdateProgress = {
              duration: this.libraryItem!.media.duration,
              currentTime: 0,
              progress: 0,
              isFinished: false
            }
            let status = await updateProgress(tmpProgress, this.libraryItem!.id)
            if (status) {
              this.progress = (await getUser())?.mediaProgress??this.progress
              this.itemProgress = this.progress.find(p => p.libraryItemId === this.libraryItem!.id)
            }
            console.log(JSON.stringify(this.itemProgress))
            this.updateMoreMenus()
          }
        })
      }
      this.moreMenus.push({
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.star')),
        value: "添加到收藏",
        action: async () => {
          this.showCollections = true
        }
      })
      this.moreMenus.push({
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.music_note_list')),
        value: "添加到播放列表",
        action: async () => {
          this.showPlaylists = true
        }
      })
    }
  }

  async aboutToAppear() {
    this.showLoadingProgress = true
    let tmpLibraryItem = await getItem(this.libraryItem!.id)
    if (tmpLibraryItem) {
      this.libraryItem = tmpLibraryItem
    }
    this.episodes = this.libraryItem?.media.episodes!
    if (this.displayWidth >= 1000) {
      this.showChapters = true
    }
    this.updateMoreMenus()
    this.showLoadingProgress = false
  }

  @Builder
  confirmBuilder() {
    Column() {
      Text("确认从" + this.libraryItem?.media.metadata.title + "的" + this.formatSeconds(this.playingItem?.chapters[this.playingIndex].start) + "开始播放？")
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
        .borderRadius(8)
        .onClick(() => {
          this.showConfirm = false
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
          if (this.tmpPlayingItem) {
            this.playingItem = this.tmpPlayingItem
            this.playingIndex = this.tmpPlayingIndex
            await this.avPlayer!.reset();
            this.isStartPlaying = true
            this.isPlaying = true
            this.playingTitle = this.playingItem!.chapters[this.playingIndex].title
            this.playStartTime = 0
            this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
            console.log("共", this.playingItem!.audioTracks.length, "条音轨")
            console.log("播放序号为", this.playingIndex)
            console.log("起始位置为", this.playStartTime)
          }
          this.showConfirm = false
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
                  Text(playlist.items.find(p => p.libraryItemId === this.libraryItem!.id) ? "移除" : "添加")
                }
                .width(80)
                .height(40)
                .borderRadius(8)
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  let tmpPlaylist: Playlist | undefined = undefined
                  let item = playlist.items.find(p => p.libraryItemId === this.libraryItem!.id)
                  if (!item) {
                    tmpPlaylist = await addToPlaylist(playlist.id!, this.libraryItem!.id)
                  } else {
                    tmpPlaylist = await removeFromPlaylist(playlist.id!, this.libraryItem!.id)
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

      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("新建播放列表")
            .fontSize(18)
        }
        .height(45)
        .width('100%')
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(async () => {
          if (this.showProgress) {
            this.getUIContext().getPromptAction().showToast({
              message: '正在加载播放列表',
              duration: 500
            });
          } else {
            this.tmpPlaylistName = ""
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
        .borderRadius(8)
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
              items: [{
                libraryItemId: this.libraryItem!.id,
                episodeId: null,
                libraryItem: this.libraryItem
              }]
            }
            let newPlaylist = await createPlaylist(playlist)
            if (newPlaylist) {
              this.showCreatePlaylist = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表成功！',
                duration: 500
              });
              this.playlists.push(newPlaylist)
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

  @Builder
  collectionsBuilder() {
    Column() {
      Stack() {
        List() {
          ForEach(this.collections, (collection: Collection, index) => {
            ListItem() {
              Row() {
                Text(collection.name)
                  .fontSize(18)
                  .width('100%')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Button({ type: ButtonType.Normal }) {
                  Text(collection.books.find(b => b.id === this.libraryItem!.id) ? "移除" : "添加")
                }
                .width(80)
                .height(40)
                .borderRadius(8)
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  let tmpCollection: Collection | undefined = undefined
                  let book = collection.books.find(b => b.id === this.libraryItem!.id)
                  if (!book) {
                    tmpCollection = await addToCollection(collection.id!, this.libraryItem!.id)
                  } else {
                    tmpCollection = await removeFromCollection(collection.id!, this.libraryItem!.id)
                  }
                  if (tmpCollection) {
                    this.showCollections = false
                    collection = tmpCollection
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

      Column() {
        Button({ type: ButtonType.Normal }) {
          Text("新建收藏")
            .fontSize(18)
        }
        .height(45)
        .width('100%')
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_emphasize_secondary'))
        .onClick(async () => {
          if (this.showProgress) {
            this.getUIContext().getPromptAction().showToast({
              message: '正在加载收藏',
              duration: 500
            });
          } else {
            this.tmpCollectionName = ""
            this.showCollections = false
            this.showCreateCollection = true
          }
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 25 })
    }
  }

  @Builder
  createCollectionBuilder() {
    Column() {
      TextInput({
        placeholder: "收藏名称"
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
          this.tmpCollectionName = value
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
          this.showCreateCollection = false
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
          if (this.tmpCollectionName.length === 0) {
            this.getUIContext().getPromptAction().showToast({
              message: '收藏名称不能为空！',
              duration: 500
            });
          } else {
            let collection: Collection1 = {
              libraryId: this.library!.id,
              name: this.tmpCollectionName,
              books: [this.libraryItem!.id]
            }
            let newCollection = await createCollection(collection)
            if (newCollection) {
              this.showCreateCollection = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建收藏成功！',
                duration: 500
              });
              this.collections.push(newCollection)
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '创建收藏失败，请检查网络！',
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
        Scroll(this.libraryDetailScroller) {
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
                Image(this.baseUrl + `/api/items/${this.libraryItem!.id}/cover?token=${this.apiToken}`)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Cover)
                  .width(this.sideBarContentWidth / this.displayHeight >= 3 / 5 ? this.displayHeight * 0.38 : '100%')
                  .aspectRatio(1)
                  .borderRadius(10)
                  .margin({ bottom: 20 })
                  .draggable(false)

                Row() {
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

                        Text(this.library?.mediaType === 'book' ? " 播放" : " 下一首")
                          .fontSize(18)
                          .fontWeight(FontWeight.Medium)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                  }
                  .backgroundColor($r('sys.color.comp_emphasize_secondary'))
                  .height(40)
                  .width('100%')
                  .layoutWeight(1)
                  .borderRadius(8)
                  .onClick(async () => {
                    this.showPlayLoading = true
                    if (this.library?.mediaType === 'book') {
                      this.playingItem = await getPlayItem(this.libraryItem!.id)
                      if (this.playingItem) {
                        await this.avPlayer!.reset();
                        this.isStartPlaying = true
                        this.isPlaying = true
                        await this.getPlayContent(this.playingItem!)
                      }
                    } else if (this.library?.mediaType === 'podcast') {
                      this.playingItem = await getPlayItem(this.libraryItem!.id, this.libraryItem!.media.episodes![0].id!)
                      if (this.playingItem) {
                        await this.avPlayer!.reset();
                        this.isStartPlaying = true
                        this.isPlaying = true
                        this.playingIndex = 0
                        this.playingTitle = this.playingItem!.displayTitle.trim()
                        this.playStartTime = this.playingItem!.currentTime - this.playingItem!.audioTracks[0].startOffset
                        this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[0].contentUrl + "?token=" + this.apiToken
                        console.log("共", this.playingItem!.audioTracks.length, "条音轨")
                        console.log("播放序号为", this.playingIndex)
                        console.log("起始位置为", this.playStartTime)
                      }
                    }
                    this.showPlayLoading = false
                  })

                  if (this.library?.mediaType === 'book') {
                    Button({ type: ButtonType.Normal }) {
                      SymbolGlyph($r('sys.symbol.download'))
                        .fontWeight(FontWeight.Normal)
                        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                        .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                        .hitTestBehavior(HitTestMode.None)
                    }
                    .margin({ left: 16 })
                    .backgroundColor($r('sys.color.comp_background_tertiary'))
                    .height(40)
                    .width(40)
                    .borderRadius(8)
                    .onClick(() => {

                    })
                  }

                  Button({ type: ButtonType.Normal }) {
                    SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
                      .fontWeight(FontWeight.Normal)
                      .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                      .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                      .hitTestBehavior(HitTestMode.None)
                  }
                  .margin({ left: 16 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .height(40)
                  .width(40)
                  .borderRadius(8)
                  .bindMenu(this.moreMenus)
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
                }
                .width('100%')
                .margin({ top: 5 })
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

                if (this.library?.mediaType === 'book') {
                  Column() {
                    Text("你的进度：" + Math.round((this.itemProgress?.progress ?? 0) * 100) + "%")
                      .fontSize(17)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.itemProgress?.isFinished ?
                      "已听完 " + (this.itemProgress ? this.formatTime(this.itemProgress?.finishedAt) : "未知") :
                      "剩余 " +
                        (this.itemProgress ?
                          this.formatDuration(this.itemProgress.duration - this.itemProgress.currentTime) : "未知"))
                      .fontSize(15)
                      .fontColor($r('sys.color.font_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .padding({ top: 5, bottom: 5 })
                  .margin({ top: 20 })
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .justifyContent(FlexAlign.Center)
                  .visibility(this.itemProgress && this.itemProgress.currentTime > 0 ? Visibility.Visible :
                    Visibility.None)
                }

                Column() {
                  Row() {
                    Text("作者")
                      .fontSize(17)
                      .margin({ right: 20 })
                      .fontColor($r('sys.color.font_secondary'))
                      .width(this.library?.mediaType === 'book' ? 68 : 34)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    if (this.library?.mediaType === 'book') {
                      Row() {
                        ForEach(this.libraryItem!.media.metadata.authors, (author: Author, index) => {
                          Text(author.name)
                            .fontSize(17)
                            .decoration({
                              type: TextDecorationType.Underline
                            })
                            .onClick(() => {
                              let filter: Filter1 = {
                                criteria: author.name,
                                type: "author"
                              }
                              this.pageInfos.pushPathByName('filterItems', filter)
                            })

                          if (this.libraryItem!.media.metadata.authors &&
                            index < this.libraryItem!.media.metadata.authors.length - 1) {
                            Text(", ")
                              .fontSize(17)
                          }
                        })
                      }
                      .width('100%')
                      .layoutWeight(1)
                    } else if (this.library?.mediaType === 'podcast') {
                      Text(this.libraryItem!.media.metadata.author)
                        .fontSize(17)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .decoration({
                          type: TextDecorationType.Underline
                        })
                        .onClick(() => {
                          let filter: Filter1 = {
                            criteria: this.libraryItem!.media.metadata.author??"",
                            type: "author"
                          }
                          this.pageInfos.pushPathByName('filterItems', filter)
                        })
                    }
                  }
                  .width('100%')
                  .clip(true)

                  if (this.libraryItem?.media.metadata.seriesName) {
                    Row() {
                      Text("系列")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(68)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(this.libraryItem?.media.metadata.seriesName)
                        .fontSize(17)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .decoration({
                          type: TextDecorationType.Underline
                        })
                        .onClick(() => {
                          let filter: Filter1 = {
                            criteria: this.libraryItem?.media.metadata.seriesName!.replace(/#\d+$/, "").trim()!,
                            type: "series"
                          }
                          this.series1 = this.series.find(s => s.name === this.libraryItem?.media.metadata.seriesName!.replace(/#\d+$/, "").trim())
                          this.pageInfos.pushPathByName('filterItems', filter)
                        })
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  if (this.library?.mediaType === 'book') {
                    Row() {
                      Text("持续时间")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(68)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(this.formatDuration(this.libraryItem!.media.duration))
                        .fontSize(17)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  if (this.library?.mediaType === 'book') {
                    Row() {
                      Text("演播者")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(68)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Row() {
                        ForEach(this.libraryItem!.media.metadata.narrators, (narrator: string, index) => {
                          Text(narrator)
                            .fontSize(17)
                            .decoration({
                              type: TextDecorationType.Underline
                            })
                            .onClick(() => {
                              let filter: Filter1 = {
                                criteria: narrator,
                                type: "narrator"
                              }
                              this.pageInfos.pushPathByName('filterItems', filter)
                            })

                          if (this.libraryItem!.media.metadata.narrators &&
                            index < this.libraryItem!.media.metadata.narrators.length - 1) {
                            Text(", ")
                              .fontSize(17)
                          }
                        })
                      }
                      .width('100%')
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  if (this.libraryItem!.media.metadata.genres.length > 0) {
                    Row() {
                      Text("流派")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(this.library?.mediaType === 'book' ? 68 : 34)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Row() {
                        ForEach(this.libraryItem!.media.metadata.genres, (genre: string, index) => {
                          Text(genre)
                            .fontSize(17)
                            .decoration({
                              type: TextDecorationType.Underline
                            })
                            .onClick(() => {
                              let filter: Filter1 = {
                                criteria: genre,
                                type: "genre"
                              }
                              this.pageInfos.pushPathByName('filterItems', filter)
                            })

                          if (index < this.libraryItem!.media.metadata.genres.length - 1) {
                            Text(", ")
                              .fontSize(17)
                          }
                        })
                      }
                      .width('100%')
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  if (this.libraryItem!.media.tags.length > 0) {
                    Row() {
                      Text("标签")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(this.library?.mediaType === 'book' ? 68 : 34)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Row() {
                        ForEach(this.libraryItem!.media.tags, (tag: string, index) => {
                          Text(tag)
                            .fontSize(17)
                            .decoration({
                              type: TextDecorationType.Underline
                            })
                            .onClick(() => {
                              let filter: Filter1 = {
                                criteria: tag,
                                type: "tag"
                              }
                              this.pageInfos.pushPathByName('filterItems', filter)
                            })

                          if (index < this.libraryItem!.media.tags.length - 1) {
                            Text(", ")
                              .fontSize(17)
                          }
                        })
                      }
                      .width('100%')
                      .layoutWeight(1)
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  if (this.library?.mediaType === 'book') {
                    Row() {
                      Text("发布年份")
                        .fontSize(17)
                        .margin({ right: 20 })
                        .fontColor($r('sys.color.font_secondary'))
                        .width(68)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(this.libraryItem!.media.metadata.publishedYear)
                        .fontSize(17)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .margin({ top: 10 })
                    .clip(true)
                  }

                  Column() {
                    Text(
                      this.libraryItem!.media.metadata.description??""
                      // 段落与换行
                        .replace(/<p[^>]*>/gi, '')
                        .replace(/<\/p>/gi, '\n\n')
                        .replace(/<br\s*\/?>/gi, '\n')
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
                        .replace(/\n{3,}/g, '\n\n')
                        .trim()
                    )
                      .fontSize(17)
                      .width('100%')
                      .maxLines(this.maxIntroLine)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ bottom: 5 })

                    Button({ type: ButtonType.Normal }) {
                      Row() {
                        Text(this.showMoreIntro ? "收起" : "阅读更多")
                          .fontSize(17)
                          .fontWeight(FontWeight.Medium)
                          .maxLines(1)

                        SymbolGlyph(this.showMoreIntro ? $r('sys.symbol.arrowtriangle_up_fill') :
                          $r('sys.symbol.arrowtriangle_down_fill'))
                          .fontWeight(FontWeight.Normal)
                          .fontSize(17)
                          .fontColor([$r('sys.color.font')])
                          .margin({ left: 5 })
                      }
                    }
                    .padding(5)
                    .borderRadius(8)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      this.showMoreIntro = !this.showMoreIntro
                      if (!this.showMoreIntro) {
                        this.maxIntroLine = 5
                      } else {
                        this.maxIntroLine = 99999
                      }
                    })
                    .visibility((this.libraryItem!.media.metadata.description??"").length > 0 ? Visibility.Visible : Visibility.None)
                  }
                  .width('100%')
                  .height('auto')
                  .margin({ top: 15 })
                  .justifyContent(FlexAlign.Start)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ top: 15 })
                .bindSheet(this.showCollections, this.collectionsBuilder(), {
                  height: SheetSize.MEDIUM,
                  preferType: SheetType.CENTER,
                  title: {
                    title: "收藏"
                  },
                  showClose: false,
                  onWillAppear: async () => {
                    this.showProgress = true
                    this.collections = await getCollections(this.library!.id)
                    this.showProgress = false
                  },
                  onDisappear: () => {
                    this.showCollections = false
                  }
                })
              }
              .padding({ bottom: this.displayWidth < 1000 ? ((this.libraryItem!.media.metadata.description??"").length > 0 ? 15 : 0) : 20 })
              .onSizeChange((oldValue, newValue) => {
                if (newValue.height) {
                  if (this.displayWidth < 1000) {
                    this.contentHeight =
                      this.library?.mediaType === 'book' ? this.displayHeight - 100 : this.displayHeight - 60
                  } else {
                    if (this.displayHeight > Number(newValue.height)) {
                      this.contentHeight =
                        this.library?.mediaType === 'book' ? this.displayHeight - 100 : this.displayHeight
                    } else {
                      this.contentHeight =
                        this.library?.mediaType === 'book' ? Number(newValue.height) - 25 : Number(newValue.height)
                    }
                  }
                }
              })
              .bindSheet(this.showCreateCollection, this.createCollectionBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: SheetType.CENTER,
                title: {
                  title: "新建收藏"
                },
                showClose: false,
                onDisappear: () => {
                  this.showCreateCollection = false
                }
              })
            }

            GridCol({ span: 1 }) {
              if (this.library?.mediaType === 'book') {
                Column() {
                  Button({ type: ButtonType.Normal }) {
                    Row() {
                      Text("章节 " + this.libraryItem?.media.chapters?.length)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                      SymbolGlyph(this.showChapters ? $r('sys.symbol.arrowtriangle_up_fill') :
                        $r('sys.symbol.arrowtriangle_down_fill'))
                        .fontColor([$r('sys.color.font')])
                        .margin({ left: 10 })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }
                  .width('100%')
                  .padding(20)
                  .margin({ bottom: 20 })
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(() => {
                    this.showChapters = !this.showChapters
                  })

                  List() {
                    ListItem() {
                      Row() {
                        Text("标题")
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)

                        Text("开始")
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .margin({ left: 20 })
                      }
                      .width('100%')
                      .height(36)
                      .padding({
                        left: 20,
                        right: 20
                      })
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundColor($r('sys.color.comp_background_tertiary'))
                    }

                    ForEach(this.libraryItem?.media.chapters, (chapter: Chapter, index) => {
                      ListItem() {
                        Row() {
                          Text(chapter.title)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .width('100%')
                            .layoutWeight(1)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(this.formatSeconds(chapter.start))
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .margin({ left: 20 })
                            .decoration({
                              type: TextDecorationType.Underline
                            })
                            .onClick(async () => {
                              this.tmpPlayingItem = await getPlayItem(this.libraryItem!.id)
                              if (this.tmpPlayingItem) {
                                this.tmpPlayingIndex = index
                                this.showConfirm = !this.showConfirm;
                              }
                            })
                        }
                        .width('100%')
                        .height(36)
                        .padding({
                          left: 20,
                          right: 20
                        })
                        .justifyContent(FlexAlign.SpaceBetween)
                        .backgroundColor(index % 2 === 0 ? Color.Transparent : $r('sys.color.comp_background_tertiary'))
                      }
                    })
                  }
                  .scrollBar(BarState.Off)
                  .margin({ bottom: 20 })
                  .border({
                    width: 1,
                    radius: 8,
                    color: $r('sys.color.comp_divider')
                  })
                  .visibility(this.showChapters ? Visibility.Visible : Visibility.None)
                  .height(this.contentHeight - 158)
                  .bindSheet(this.showConfirm, this.confirmBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: SheetType.CENTER,
                    title: {
                      title: "确认播放"
                    },
                    showClose: false,
                    onDisappear: () => {
                      this.showConfirm = false
                    }
                  })

                  Button({ type: ButtonType.Normal }) {
                    Row() {
                      Text("音轨 " + this.libraryItem?.media.audioFiles?.length)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                      SymbolGlyph(this.showAudioFiles ? $r('sys.symbol.arrowtriangle_up_fill') :
                        $r('sys.symbol.arrowtriangle_down_fill'))
                        .fontColor([$r('sys.color.font')])
                        .margin({ left: 10 })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }
                  .width('100%')
                  .padding(20)
                  .margin({ bottom: 20 })
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(() => {
                    this.showAudioFiles = !this.showAudioFiles
                  })

                  List() {
                    ListItem() {
                      Row() {
                        Text("文件名")
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)

                        Text("持续时间")
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .margin({ left: 20 })
                      }
                      .width('100%')
                      .height(36)
                      .padding({
                        left: 20,
                        right: 20
                      })
                      .justifyContent(FlexAlign.SpaceBetween)
                      .backgroundColor($r('sys.color.comp_background_tertiary'))
                    }

                    ForEach(this.libraryItem?.media.audioFiles, (audioFile: AudioFile, index) => {
                      ListItem() {
                        Row() {
                          Text(audioFile.metadata.filename)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .width('100%')
                            .layoutWeight(1)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(this.formatSeconds(audioFile.duration))
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .margin({ left: 20 })
                        }
                        .width('100%')
                        .height(36)
                        .padding({
                          left: 20,
                          right: 20
                        })
                        .justifyContent(FlexAlign.SpaceBetween)
                        .backgroundColor(index % 2 === 0 ? Color.Transparent : $r('sys.color.comp_background_tertiary'))
                      }
                    })
                  }
                  .scrollBar(BarState.Off)
                  .margin({ bottom: 20 })
                  .border({
                    width: 1,
                    radius: 8,
                    color: $r('sys.color.comp_divider')
                  })
                  .visibility(this.showAudioFiles ? Visibility.Visible : Visibility.None)
                  .height(this.contentHeight - 158)
                }
              } else if (this.library?.mediaType === 'podcast') {
                Column() {
                  Row() {
                    Text("剧集 (" + this.libraryItem?.media.episodes?.length + ")")
                      .fontSize(20)
                      .fontWeight(FontWeight.Medium)

                    Button({ type: ButtonType.Normal }) {
                      Row() {
                        Text(this.sortByStr)
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)

                        SymbolGlyph(this.order ? $r('sys.symbol.text_and_arrow_down') : $r('sys.symbol.text_and_arrow_up') )
                          .margin({ left: 6 })
                      }
                    }
                    .height(31)
                    .padding(8)
                    .borderRadius(8)
                    .backgroundColor($r('sys.color.comp_background_tertiary'))
                    .bindMenu([
                      {
                        value: "出版日期",
                        action: () => {
                          if (this.sortBy === 0) {
                            this.order = !this.order
                          } else {
                            this.sortBy = 0
                            this.sortByStr = "出版日期"
                            this.order = true
                          }
                          if (this.order) {
                            this.episodes.sort((a, b) => (b.publishedAt ?? 0) - (a.publishedAt ?? 0))
                          } else {
                            this.episodes.sort((a, b) => (a.publishedAt ?? 0) - (b.publishedAt ?? 0))
                          }
                        }
                      },
                      {
                        value: "标题",
                        action: () => {
                          if (this.sortBy === 1) {
                            this.order = !this.order
                          } else {
                            this.sortBy = 1
                            this.sortByStr = "标题"
                            this.order = true
                          }
                          if (this.order) {
                            this.episodes.sort((a, b) => String(b.title)
                              .localeCompare(String(a.title), 'en', { numeric: true }))
                          } else {
                            this.episodes.sort((a, b) => String(a.title)
                              .localeCompare(String(b.title), 'en', { numeric: true }))
                          }
                        }
                      },
                      {
                        value: "季",
                        action: () => {
                          if (this.sortBy === 2) {
                            this.order = !this.order
                          } else {
                            this.sortBy = 2
                            this.sortByStr = "季"
                            this.order = true
                          }
                          if (this.order) {
                            this.episodes.sort((a, b) => String(b.season)
                              .localeCompare(String(a.season), 'en', { numeric: true }))
                          } else {
                            this.episodes.sort((a, b) => String(a.season)
                              .localeCompare(String(b.season), 'en', { numeric: true }))
                          }
                        }
                      },
                      {
                        value: "剧集",
                        action: () => {
                          if (this.sortBy === 3) {
                            this.order = !this.order
                          } else {
                            this.sortBy = 3
                            this.sortByStr = "剧集"
                            this.order = true
                          }
                          if (this.order) {
                            this.episodes.sort((a, b) => String(b.episode)
                              .localeCompare(String(a.episode), 'en', { numeric: true }))
                          } else {
                            this.episodes.sort((a, b) => String(a.episode)
                              .localeCompare(String(b.episode), 'en', { numeric: true }))
                          }
                        }
                      },
                      {
                        value: "文件名",
                        action: () => {
                          if (this.sortBy === 4) {
                            this.order = !this.order
                          } else {
                            this.sortBy = 4
                            this.sortByStr = "文件名"
                            this.order = true
                          }
                          if (this.order) {
                            this.episodes.sort((a, b) =>
                            String(b.audioFile?.metadata?.filename ?? '').localeCompare(
                              String(a.audioFile?.metadata?.filename ?? ''),
                              'en',
                              { numeric: true }
                            )
                            )
                          } else {
                            this.episodes.sort((a, b) =>
                            String(a.audioFile?.metadata?.filename ?? '').localeCompare(
                              String(b.audioFile?.metadata?.filename ?? ''),
                              'en',
                              { numeric: true }
                            )
                            )
                          }
                        }
                      }
                    ])
                  }
                  .width('100%')
                  .height(18)
                  .clip(false)
                  .justifyContent(FlexAlign.SpaceBetween)

                  Column() {
                    ForEach(this.episodes, (episode: Episode, index) => {
                      EpisodeComponent1({
                        item: episode
                      })
                        .margin({ bottom: index === this.episodes.length - 1 ? 20 : 0 })
                    })
                  }
                }
              }
            }
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .padding({
          top: 76 + this.statusBarHeight,
          left: 20,
          right: 20,
          bottom: this.isStartPlaying ? 84 : 0
        })
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        if (this.library?.mediaType === 'podcast') {
          Button({ type: ButtonType.Normal }) {
            SymbolGlyph($r('sys.symbol.arrow_up_to_line'))
              .fontWeight(FontWeight.Normal)
              .fontSize($r('sys.float.ohos_id_text_size_headline7'))
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
              .hitTestBehavior(HitTestMode.None)
          }
          .position({
            right: 15,
            bottom: this.isStartPlaying ? 99 : 15
          })
          .animation({ duration: 510, curve: Curve.EaseInOut })
          .width(36)
          .height(36)
          .borderRadius(6)
          .backgroundColor(Color.Transparent)
          .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
          .shadow({
            radius: 12,
            color: $r('sys.color.font'),
          })
          .onClick(async () => {
            this.libraryDetailScroller.scrollEdge(Edge.Top, { velocity: 1000000 })
          })
          .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
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
    .width('100%')
    .height('100%')
    .titleBar({
      avoidLayoutSafeArea:true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      content: {
        title: {
          mainTitle: this.libraryItem!.media.metadata.title,
          subTitle: this.libraryItem!.media.metadata.subtitle ?? ""
        }
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          blurEffectiveStartOffset: LengthMetrics.vp(20)
        }
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.libraryDetailScroller])
  }
}