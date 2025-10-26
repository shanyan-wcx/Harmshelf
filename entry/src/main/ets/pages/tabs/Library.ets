import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { LibraryItem, Progress } from '../../api/Interface'
import Loading from '../Loading'

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  let formattedTime = '';
  if (hours > 0) {
    formattedTime += `${hours} hr `;
  }
  formattedTime += `${minutes} min`;

  return formattedTime;
}

@Component
export default struct library {
  @Consume displayWidth: number = 0
  @State columnsTemplate: string = "1fr"
  @Consume PageIndexTransfer: number
  @State libraryId: string = ''
  @Consume libraryItems: LibraryItem[]
  @Consume itemTransfer: LibraryItem
  @Consume nowPlayingItem: LibraryItem
  @Consume showProgressTransfer: boolean
  @Consume allProgress: Progress[]
  @Consume backPageIndex: number
  @Consume sidebarShow: boolean
  @Consume mainWindow: window.Window
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

  getDuration(itemId: string): string {
    let duration = ''
    if (this.getProgressById(itemId).currentTime === 0) {
      duration = "未听过"
    } else if (this.getProgressById(itemId).isFinished === true) {
      duration = "已听完"
    } else {
      duration =
        "剩余 " + formatDuration(this.getProgressById(itemId).duration - this.getProgressById(itemId).currentTime)
    }
    return duration
  }

  async aboutToAppear() {
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
            ForEach(this.libraryItems, (item: LibraryItem, index) => {
              GridItem() {
                Stack({ alignContent: Alignment.Bottom }) {
                  Image(this.server + `/api/items/${item.id}/cover?format=jpeg&width=1024` + `&token=${this.apitoken}`)
                    .alt($rawfile('nocover.jpg'))
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10)
                    .objectFit(ImageFit.Fill)
                    .onClick(async () => {
                      this.itemTransfer = item
                      this.backPageIndex = 0
                      this.PageIndexTransfer = 3
                      animateTo({
                        duration: 300,
                        curve: Curve.EaseOut,
                      }, () => {
                        this.sidebarShow = false
                      })
                    })
                  Progress({
                    value: this.getProgressById(item.id).progress * 100,
                    total: 100,
                    type: ProgressType.Linear
                  })
                    .size({ width: '100%', height: 'auto' })
                    .style({ strokeWidth: 5 })
                    .color(this.getProgressById(item.id).progress * 100 === 100 ? Color.Green :
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

        // Column() {
        //   Loading()
        // }
        // .width('100%')
        // .height('100%')
        // .hitTestBehavior(HitTestMode.Transparent)
      }
      .width('100%')
      .height('100%')
      .visibility(this.libraryItems.length !== 0 ? Visibility.Visible : Visibility.None)

      Text("没有项目")
        .fontColor(Color.White)
        .fontSize(32)
        .margin({ top: 200 })
        .visibility(this.libraryItems.length === 0 && this.showProgressTransfer === false ? Visibility.Visible :
        Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}