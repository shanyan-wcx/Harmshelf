import {
  addToPlaylist,
  createPlaylist,
  deleteFromServer,
  getEpisode,
  getItem,
  getPlayItem,
  getPlaylists,
  getUser,
  removeFromPlaylist,
  updateProgress
} from '../utils/Api'
import { Episode, Library, LibraryItem, PlayItem, Playlist,
  PlaylistItem,
  Progress, UpdateProgress } from '../utils/Interface'
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI'
import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit'
import { HmParseHTML, Node } from '@wuyan/html_parse'
import { common, ConfigurationConstant, Want } from '@kit.AbilityKit'
import { env } from '../utils/Class'
import { media } from '@kit.MediaKit'

@Builder
export function episodeDetailBuilder(name: string, param: Object) {
  EpisodeDetail()
}

@ComponentV2
export struct EpisodeDetail {
  private episodeDetailScroller: Scroller = new Scroller();
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() displayWidth: number = 0
  @Consumer() statusBarHeight: number = 0
  @Consumer() episode: Episode | undefined = undefined
  @Consumer() progress: Progress[] = []
  @Consumer() playlists: Playlist[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() playingTitle: string = "-"
  @Consumer() syncTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Local itemProgress: Progress | undefined = this.progress.find(p => p.episodeId === this.episode!.id)
  @Local podcast: LibraryItem | undefined = undefined
  @Local showLoadingProgress: boolean = false
  @Local moreMenus: MenuElement[] = []
  @Local showPlayLoading: boolean = false
  @Local showPlaylists: boolean = false
  @Local showProgress: boolean = false
  @Local showCreatePlaylist: boolean = false
  @Local showDeleteConfirm: boolean = false
  @Local tmpPlaylistName: string = ""
  @Local tmpPlaylistDescription: string = ""

  @Monitor('syncTime')
  async refreshProgress(monitor: IMonitor) {
    this.itemProgress = undefined
    this.itemProgress = this.progress.find(p => p.episodeId === this.episode!.id)
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

  updateMoreMenus() {
    this.moreMenus = []
    if (!this.itemProgress?.isFinished) {
      this.moreMenus.push({
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_square')),
        value: "标记为已听完",
        action: async () => {
          let tmpProgress: UpdateProgress = {
            duration: this.episode!.duration!,
            currentTime: this.episode!.duration!,
            progress: 1,
            isFinished: true
          }
          let status = await updateProgress(tmpProgress, this.episode!.libraryItemId!, this.episode!.id)
          if (status) {
            this.progress = (await getUser())?.mediaProgress ?? this.progress
            this.itemProgress = this.progress.find(p => p.episodeId === this.episode!.id)
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
            duration: this.episode!.duration!,
            currentTime: 0,
            progress: 0,
            isFinished: false
          }
          let status = await updateProgress(tmpProgress, this.episode!.libraryItemId!, this.episode!.id)
          if (status) {
            this.progress = (await getUser())?.mediaProgress ?? this.progress
            this.itemProgress = this.progress.find(p => p.episodeId === this.episode!.id)
          }
          this.updateMoreMenus()
        }
      })
    }
    this.moreMenus.push({
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.music_note_list')),
      value: "添加到播放列表",
      action: async () => {
        this.showPlaylists = true
      }
    })
    this.moreMenus.push({
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.music_note_list')),
      value: "从服务器中删除",
      action: async () => {
        this.showDeleteConfirm = true
      }
    })
  }

  async aboutToAppear() {
    this.showLoadingProgress = true
    let tmpEpisode = await getEpisode(this.episode!.libraryItemId!, this.episode!.id!)
    if (tmpEpisode) {
      this.episode = tmpEpisode
    }
    this.podcast = await getItem(this.episode!.libraryItemId!)
    this.updateMoreMenus()
    this.showLoadingProgress = false
  }

  @Builder
  deleteConfirmBuilder() {
    Column() {
      Text("确认从服务器删除" + this.episode!.title + "？")
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
          this.showDeleteConfirm = false
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
          let status = await deleteFromServer(this.episode!.libraryItemId!, this.episode!.id!)
          if (status) {
            this.showDeleteConfirm = false
            this.getUIContext().getPromptAction().showToast({
              message: '删除成功！',
              duration: 500
            });
            this.pageInfos.pop()
            this.libraryItem = await getItem(this.libraryItem!.id)
          } else {
            this.getUIContext().getPromptAction().showToast({
              message: '删除失败，请检查网络！',
              duration: 500
            });
          }
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
                  Text(playlist.items.find(p => p.episodeId === this.episode!.id) ? "移除" : "添加")
                }
                .width(80)
                .height(40)
                .borderRadius(8)
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  let tmpPlaylist: Playlist | undefined = undefined
                  let item = playlist.items.find(p => p.episodeId === this.episode!.id)
                  if (!item) {
                    tmpPlaylist = await addToPlaylist(playlist.id!, this.episode!.libraryItemId!, this.episode!.id)
                  } else {
                    tmpPlaylist = await removeFromPlaylist(playlist.id!, this.episode!.libraryItemId!, this.episode!.id)
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
        .padding({ left: 20, right: 20, bottom: 20 })
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
            this.tmpPlaylistDescription = ""
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

      TextArea({
        placeholder: "播放列表描述"
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
              description: this.tmpPlaylistDescription.length > 0 ? this.tmpPlaylistDescription : null,
              items: [{
                libraryItemId: this.episode!.libraryItemId!,
                episodeId: this.episode!.id!,
                episode: this.episode
              }]
            }
            let newPlaylist = await createPlaylist(playlist)
            if (newPlaylist) {
              this.playlists.push(newPlaylist)
              this.showCreatePlaylist = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建播放列表成功！',
                duration: 500
              });
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

  build() {
    HdsNavDestination() {
      Stack() {
        Scroll(this.episodeDetailScroller) {
          Column() {
            Row() {
              Image(this.baseUrl + `/api/items/${this.episode!.libraryItemId}/cover?token=${this.apiToken}`)
                .alt($rawfile('nocover.jpg'))
                .objectFit(ImageFit.Cover)
                .height(80)
                .aspectRatio(1)
                .borderRadius(8)
                .margin({ right: 10 })
                .draggable(false)

              Column() {
                Text(this.podcast?.media.metadata.title ?? "-")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ bottom: 5 })
                  .decoration({
                    type: TextDecorationType.Underline
                  })
                  .onClick(async () => {
                    this.libraryItem = this.podcast
                    this.pageInfos.pushPathByName('libraryItemDetail', null)
                  })

                Text(this.formatTime(this.episode!.publishedAt!))
                  .fontSize(16)
                  .fontColor($r('sys.color.font_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ bottom: 10 })
              }
              .width('100%')
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .margin({ top: 10, bottom: 20 })
            .justifyContent(FlexAlign.Start)

            Column() {
              Text("你的进度：" + Math.round((this.itemProgress?.progress ?? 0) * 100) + "%")
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.itemProgress?.isFinished ?
                "已听完 " + (this.itemProgress ? this.formatTime(this.itemProgress?.finishedAt) : "未知") : "剩余 " +
                  (this.itemProgress ?
                    this.formatDuration(this.itemProgress.duration - this.itemProgress.currentTime) : "未知"))
                .fontSize(15)
                .fontColor($r('sys.color.font_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
            .margin({ bottom: 20 })
            .borderRadius(8)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .justifyContent(FlexAlign.Center)
            .visibility(this.itemProgress && this.itemProgress.currentTime > 0 ? Visibility.Visible : Visibility.None)

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
              .width('100%')
              .layoutWeight(1)
              .borderRadius(8)
              .onClick(async () => {
                this.showPlayLoading = true
                this.playingItem = await getPlayItem(this.episode!.libraryItemId!, this.episode!.id!)
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
                this.showPlayLoading = false
              })

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
            }
            .width('100%')
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

            HmParseHTML({
              htmlStr: this.episode!.description.replace(/<br\s*\/?>/gi, '')
                .replace(/<ul([\s\S]*?)<\/ul>/gi, '<p><ul$1</ul></p>'),
              baseFontSize: 17,
              baseFontColor: env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#fff' : '#000',
              onClickCallback: (e: ClickEvent, node: Node) => {
                if (node.tag === 'a' && node.props.href !== undefined) {
                  let context = this.getUIContext().getHostContext() as common.UIAbilityContext
                  let want: Want = {
                    action: 'ohos.want.action.viewData',
                    entities: ['entity.system.browsable'],
                    uri: node.props.href
                  };
                  context.startAbility(want)
                }
              }
            })
              .width('100%')
              .margin({ top: 15 })
          }
          .width('100%')
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
        }
        .width('100%')
        .height('100%')
        .padding({
          top: 56 + this.statusBarHeight,
          left: 20,
          right: 20,
          bottom: this.isStartPlaying ? 89 : 10
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
      .bindSheet(this.showDeleteConfirm, this.deleteConfirmBuilder(), {
        height: SheetSize.FIT_CONTENT,
        preferType: SheetType.CENTER,
        title: {
          title: "确认删除"
        },
        showClose: false,
        onDisappear: () => {
          this.showDeleteConfirm = false
        }
      })
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
          mainTitle: this.episode!.title,
          subTitle: this.episode!.subtitle ?? ""
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
    .bindToScrollable([this.episodeDetailScroller])
  }
}