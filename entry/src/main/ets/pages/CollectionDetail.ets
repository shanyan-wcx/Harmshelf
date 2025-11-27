import { Book, Collection, Collection1, Library, LibraryItem, PlayItem, Progress, User } from '../utils/Interface';
import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics, PersistenceV2, RectShape } from '@kit.ArkUI';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { env } from '../utils/Class';
import { ColorMode } from "../pages/Index";
import { deleteCollection, getCollections, getPlayItem, removeFromCollection, updateCollection } from '../utils/Api';
import { media } from '@kit.MediaKit';
import { deviceInfo } from '@kit.BasicServicesKit';

let deviceTypeInfo: string = deviceInfo.deviceType;

@Builder
export function collectionDetailBuilder(name: string, param: Object) {
  CollectionDetail()
}

@ComponentV2
export struct CollectionDetail {
  private CollectionDetailScroller: Scroller = new Scroller();
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() displayHeight: number = 0
  @Consumer() collection1: Collection | undefined = undefined
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() collections: Collection[] = []
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
  @Consumer() library: Library | undefined = undefined
  @Consumer() user: User | undefined = undefined
  @Consumer() toCloseSession: PlayItem | undefined = undefined
  @Consumer() toCloseIndex: number = 0
  @Local showLoadingProgress: boolean = false
  @Local showPlayLoading: boolean = false
  @Local topHeight: Length = 0
  @Local showEditCollection: boolean = false
  @Local tmpCollectionName: string = ""
  @Local tmpCollectionDescription: string = ""

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
    if (!this.collection1) {
      return '0s'
    }
    let totalSec = 0
    const books = this.collection1.books ?? []
    totalSec = books.map(item => item?.media?.duration ?? 0).reduce((a, b) => a + b, 0)
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

  private getPosition(collection: Collection, index: number): number {
    const gap =
      (this.sideBarContentWidth - 40 >= 500 ? 500 : this.sideBarContentWidth - 40) / (collection.books!.length - 1) / 2;
    if (collection.books!.length == 1) {
      return (this.sideBarContentWidth - 40 >= 500 ? 500 : this.sideBarContentWidth - 40) / 2
    } else {
      return (collection.books!.length - 1 - index) * gap
    }
  }

  @Builder
  collectionEnd(index: number) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash_fill'))
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor([$r('sys.color.white')])
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .backgroundColor($r('sys.color.warning'))
    .onClick(async () => {
      if (this.user?.type === "root" || this.user?.type === "admin") {
        let collection = await removeFromCollection(this.collection1!.id!, this.collection1!.books![index].id)
        if (collection) {
          this.collection1 = collection
          this.collections = await getCollections(this.library!.id)
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: '移除失败，请检查网络！',
            duration: 500
          });
        }
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: '当前用户没有权限！',
          duration: 500
        });
      }
    })
  }

  @Builder
  editCollectionBuilder() {
    Column() {
      TextInput({
        placeholder: "收藏名称",
        text: this.tmpCollectionName
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

      TextArea({
        placeholder: "收藏描述",
        text: this.tmpCollectionDescription
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
          this.tmpCollectionDescription = value
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
          let status = await deleteCollection(this.collection1!.id!)
          if (status) {
            this.showEditCollection = false
            this.getUIContext().getPromptAction().showToast({
              message: '删除成功！',
              duration: 500
            });
            this.pageInfos.pop()
            this.collections = await getCollections(this.library!.id)
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
          if (this.tmpCollectionName.length === 0) {
            this.getUIContext().getPromptAction().showToast({
              message: '收藏名称不能为空！',
              duration: 500
            });
          } else {
            let newCollection = await updateCollection(this.collection1!.id!, this.tmpCollectionName, this.tmpCollectionDescription)
            if (newCollection) {
              this.showEditCollection = false
              this.getUIContext().getPromptAction().showToast({
                message: '编辑收藏成功！',
                duration: 500
              });
              this.collection1 = newCollection
              this.collections = await getCollections(this.library!.id)
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '编辑收藏失败，请检查网络！',
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
        Scroll(this.CollectionDetailScroller) {
          Column() {
            Column() {
              Stack({ alignContent: Alignment.Bottom }) {
                if (this.collection1!.books!.length === 1) {
                  Column() {
                    Image(this.baseUrl + `/api/items/${this.collection1!.books![0].id}/cover?token=${this.apiToken}`)
                      .alt($rawfile('nocover.jpg'))
                      .objectFit(ImageFit.Cover)
                      .height('100%')
                      .aspectRatio(1)
                      .clip(true)
                      .objectFit(ImageFit.Fill)
                      .draggable(false)
                  }
                  .width('100%')
                  .height('100%')
                  .backgroundImage(this.baseUrl +
                    `/api/items/${this.collection1!.books![0].id}/cover?token=${this.apiToken}`)
                  .backgroundImageSize(ImageSize.FILL)
                  .backgroundBlurStyle(BlurStyle.BACKGROUND_THICK)
                } else {
                  ForEach(this.collection1!.books!.slice().reverse(), (book: Book, index) => {
                    Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                      .alt($rawfile('nocover.jpg'))
                      .objectFit(ImageFit.Cover)
                      .height('100%')
                      .aspectRatio(1)
                      .clip(true)
                      .objectFit(ImageFit.Fill)
                      .draggable(false)
                      .position({ x: this.getPosition(this.collection1, index) })
                      .shadow({
                        offsetX: 10,
                        offsetY: 0,
                        radius: 10,
                        color: $r('sys.color.ohos_id_shadow_default_lg_dark')
                      })
                  })
                }
              }
              .width(this.sideBarContentWidth - 40 >= 500 ? 500 : this.sideBarContentWidth - 40)
              .aspectRatio(2)
              .borderRadius(10)
              .margin({ bottom: 5 })
              .clip(true)

              if (this.collection1!.description && this.collection1!.description.length > 0) {
                Text(this.collection1!.description)
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
                  Text("收藏项目 " + this.collection1!.books!.length)
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
                  this.toCloseIndex = this.playingIndex
                  this.toCloseSession = this.playingItem
                  let id: string | undefined = undefined
                  for (let book of this.collection1!.books!) {
                    let isFinished = this.progress.find(p => p.libraryItemId === book.id)?.isFinished ?? false
                    if (!isFinished) {
                      id = book.id
                      break
                    }
                  }
                  if (id) {
                    this.playingItem = await getPlayItem(id)
                    if (this.playingItem) {
                      await this.avPlayer!.reset();
                      this.isStartPlaying = true
                      this.isPlaying = true
                      await this.getPlayContent(this.playingItem!)
                    }
                  }
                  this.showPlayLoading = false
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Center)

              List({ space: 10 }) {
                ForEach(this.collection1!.books, (book: Book, index) => {
                  ListItem() {
                    Stack() {
                      Row() {
                        Image(this.baseUrl + `/api/items/${book.id}/cover?token=${this.apiToken}`)
                          .alt($rawfile('nocover.jpg'))
                          .objectFit(ImageFit.Cover)
                          .width(55)
                          .aspectRatio(1)
                          .borderRadius(8)
                          .margin({ right: 10 })
                          .draggable(false)

                        Column() {
                          Text(book.media!.metadata.title)
                            .fontSize(16)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(book.mediaType === 'book' ? (book.media!.metadata.authorName ?? "-") :
                            (book.media!.metadata.author ?? "-"))
                            .fontSize(14)
                            .fontColor($r('sys.color.font_secondary'))
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })

                          Text(this.formatDuration(book.media!.duration))
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
                          this.toCloseIndex = this.playingIndex
                          this.toCloseSession = this.playingItem
                          this.playingItem = await getPlayItem(book.id)
                          if (this.playingItem) {
                            await this.avPlayer!.reset();
                            this.isStartPlaying = true
                            this.isPlaying = true
                            await this.getPlayContent(this.playingItem!)
                          }
                        })
                      }
                      .padding(10)

                      Progress({
                        value: (this.progress.find(p => p.libraryItemId === book.id)?.progress ?? 0) * 100,
                        total: 100,
                        type: ProgressType.Linear
                      })
                        .width('100%')
                        .color(this.progress.find(p => p.libraryItemId === book.id)?.progress === 1 ?
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
                    .alignContent(Alignment.Bottom)
                    .onClick(() => {
                      this.libraryItem = this.libraryItems.find(item => item.id === book.id)
                      this.pageInfos.pushPathByName('libraryItemDetail', null)
                    })
                  }
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.collectionEnd(index)
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
        end: deviceTypeInfo === '2in1' ? LengthMetrics.vp(4) : LengthMetrics.vp(16)
      },
      content: {
        title: {
          mainTitle: this.collection1!.name
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.square_and_pencil'),
              label: "编辑",
              action: () => {
                if (this.user?.type === "root" || this.user?.type === "admin") {
                  this.tmpCollectionName = this.collection1!.name
                  this.tmpCollectionDescription = this.collection1!.description??""
                  this.showEditCollection = true
                } else {
                  this.getUIContext().getPromptAction().showToast({
                    message: '当前用户没有权限！',
                    duration: 500
                  });
                }
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
    .bindToScrollable([this.CollectionDetailScroller])
    .bindSheet(this.showEditCollection, this.editCollectionBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: SheetType.CENTER,
      title: {
        title: "编辑收藏"
      },
      showClose: false,
      onDisappear: () => {
        this.showEditCollection = false
      }
    })
  }
}