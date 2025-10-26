import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Book, Collection, LibraryItem, Progress, Series } from '../api/Interface'
import Loading from './Loading'

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

@Component
export default struct Items {
  @State displayWidth: number = 0
  @State columnsTemplate: string = "1fr"
  @Consume PageIndexTransfer: number
  @Consume libraryItems: LibraryItem[]
  @Consume itemTransfer: LibraryItem
  @Consume showProgressTransfer: boolean
  @Consume allProgress: Progress[]
  @Consume seriesTransfer: Series
  @Consume collectionTransfer: Collection
  @Consume backPageIndex: number
  @Consume sidebarShow: boolean
  @Consume isSeries: boolean
  @State mainWindow: window.Window | null = null
  @Consume server: string
  @Consume apitoken: string

  getProgressById(itemId: string): Progress {
    let progress: Progress = {
      id: '',
      libraryItemId: itemId,
      episodeId: '',
      duration: 0,
      progress: 0,
      currentTime: 0,
      isFinished: false,
      hideFromContinueListening: false,
      lastUpdate: 0,
      startedAt: 0,
      finishedAt: null
    }
    for (let element of this.allProgress) {
      if (element.libraryItemId === itemId) {
        progress = element
        progress.progress = Math.round(element.progress * 100) / 100
        break
      }
    }
    return progress
  }

  async aboutToAppear() {
    this.mainWindow = await window.getLastWindow(getContext(this))
    this.displayWidth = px2vp(this.mainWindow.getWindowProperties().windowRect.width)
    if (this.displayWidth >= 320 && this.displayWidth < 550) {
      this.columnsTemplate = "1fr 1fr"
    } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
      this.columnsTemplate = "1fr 1fr 1fr 1fr"
    } else if (this.displayWidth >= 840) {
      this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr"
    }
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = px2vp(size.width)
      if (this.displayWidth >= 320 && this.displayWidth < 550) {
        this.columnsTemplate = "1fr 1fr"
      } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
        this.columnsTemplate = "1fr 1fr 1fr 1fr"
      } else if (this.displayWidth >= 840) {
        this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr"
      }
    })
  }

  build() {
    Column() {
      Stack() {
        Column() {
          Grid() {
            ForEach(this.isSeries === true ? this.seriesTransfer.books :
            this.collectionTransfer.books, (book: Book, index) => {
              GridItem() {
                Stack({ alignContent: Alignment.Bottom }) {
                  Image(this.server + `/api/items/${book.id}/cover?format=jpeg&width=1024` +
                    `&token=${this.apitoken}`)
                    .alt($rawfile('nocover.jpg'))
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10)
                    .objectFit(ImageFit.Fill)
                    .onClick(async () => {
                      animateTo({
                        duration: 300,
                        curve: Curve.EaseOut,
                      }, () => {
                        this.sidebarShow = false
                      })
                      for (let item of this.libraryItems) {
                        if (item.id === book.id) {
                          this.itemTransfer = item
                          break
                        }
                      }
                      this.backPageIndex = 4
                      this.PageIndexTransfer = 3
                    })
                  Progress({
                    value: this.getProgressById(book.id).progress * 100,
                    total: 100,
                    type: ProgressType.Linear
                  })
                    .size({ width: '100%', height: 'auto' })
                    .style({ strokeWidth: 5 })
                    .color(this.getProgressById(book.id).progress * 100 === 100 ?
                    Color.Green :
                    Color.Orange)
                }
                .width('100%')
                .borderRadius(10)
                .clip(true)
              }
              .borderRadius(10)
            })
          }
          .columnsTemplate(this.columnsTemplate)
          .columnsGap(20)
          .rowsGap(20)
          .margin({ left: 15, right: 15 })
          .padding({ top: 20, bottom: 20 })
          .height('100%')
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundImage($rawfile('background.jpg'))
        .backgroundImageSize(ImageSize.Cover)

        Column() {
          Loading()
        }
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)
      }
      .width('100%')
      .height('100%')
      .visibility((this.isSeries === true && this.seriesTransfer.books.length !== 0) ||
        (this.isSeries === false && this.collectionTransfer.books.length !== 0) ? Visibility.Visible : Visibility.None)

      Text("没有项目")
        .fontColor(Color.White)
        .fontSize(32)
        .margin({ top: 200 })
        .visibility((this.isSeries === true && this.seriesTransfer.books.length === 0) ||
          (this.isSeries === false && this.collectionTransfer.books.length === 0) ? Visibility.Visible :
        Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}