import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { LibraryItem, Progress } from '../../api/Interface'
import Loading from '../Loading'
import { JSON } from '@kit.ArkTS';

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

@Component
export default struct home {
  @Consume displayWidth: number
  @State coverWidth: number = 180
  @Consume PageIndexTransfer: number
  @State libraryId: string = ''
  @Consume libraryItemsInProgress: LibraryItem[]
  @Consume libraryItemsFinished: LibraryItem[]
  @Consume itemTransfer: LibraryItem
  @Consume nowPlayingItem: LibraryItem
  @Consume showProgressTransfer: boolean
  @Consume allProgress: Progress[]
  @Consume libraryItems: LibraryItem[]
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

  async aboutToAppear() {
    if (this.displayWidth >= 320 && this.displayWidth < 550) {
      this.coverWidth = 180
    } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
      this.coverWidth = 170
    } else if (this.displayWidth >= 840) {
      this.coverWidth = 220
    }
    console.log("当前封面宽度", this.coverWidth)
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = px2vp(size.width)
      if (this.displayWidth >= 320 && this.displayWidth < 550) {
        this.coverWidth = 180
      } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
        this.coverWidth = 170
      } else if (this.displayWidth >= 840) {
        this.coverWidth = 220
      }
    })
  }

  build() {
    Stack() {
      Column() {
        Column() {
          List() {
            ForEach(this.libraryItemsInProgress, (item: LibraryItem, index) => {
              ListItem() {
                Stack({ alignContent: Alignment.Bottom }) {
                  Image(this.server + `/api/items/${item.id}/cover?format=jpeg&width=1024` + `&token=${this.apitoken}`)
                    .alt($rawfile('nocover.jpg'))
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10)
                    .objectFit(ImageFit.Fill)
                    .onClick(async () => {
                      this.itemTransfer = item
                      this.PageIndexTransfer = 3
                      console.log(JSON.stringify(item))
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
                    .color(this.getProgressById(item.id).progress * 100 === 100 ?
                    Color.Green :
                    Color.Orange)
                }
                .width('100%')
                .height('100%')
                .borderRadius(10)
                .clip(true)
              }
              .width(this.coverWidth)
              .height(this.coverWidth)
              .borderRadius(10)
              .padding({ left: 20 })
            })
          }
          .listDirection(Axis.Horizontal)
          .width('100%')
          .height(this.coverWidth)
          .scrollBar(BarState.Off)

          Column() {
            Text("继续收听")
              .fontColor('#F2E4C1')
              .fontSize(16)
              .backgroundColor(Color.Black)
              .width(100)
              .height(23)
              .margin({ left: 20 })
              .textAlign(TextAlign.Center)
              .border({
                width: 2,
                color: '#9E9681'
              })
          }
          .width('100%')
          .height(25)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#674625')
          .shadow({
            offsetX: 0,
            offsetY: 20,
            radius: 20,
            color: '#95000000'
          })
        }
        .width('100%')
        .height(this.coverWidth + 45)
        .justifyContent(FlexAlign.End)
        .visibility(this.libraryItemsInProgress.length > 0 ? Visibility.Visible : Visibility.None)

        Column() {
          List() {
            ForEach(this.libraryItemsFinished, (item: LibraryItem, index) => {
              ListItem() {
                Stack({ alignContent: Alignment.Bottom }) {
                  Image(this.server + `/api/items/${item.id}/cover?format=jpeg&width=1024` + `&token=${this.apitoken}`)
                    .alt($rawfile('nocover.jpg'))
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(10)
                    .objectFit(ImageFit.Fill)
                    .onClick(async () => {
                      this.itemTransfer = item
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
                    .color(this.getProgressById(item.id).progress * 100 === 100 ?
                    Color.Green :
                    Color.Orange)
                }
                .width('100%')
                .height('100%')
                .borderRadius(10)
                .clip(true)
              }
              .width(this.coverWidth)
              .height(this.coverWidth)
              .borderRadius(10)
              .padding({ left: 20 })
            })
          }
          .listDirection(Axis.Horizontal)
          .width('100%')
          .height(this.coverWidth)
          .scrollBar(BarState.Off)

          Column() {
            Text("再次收听")
              .fontColor('#F2E4C1')
              .fontSize(16)
              .backgroundColor(Color.Black)
              .width(100)
              .height(23)
              .margin({ left: 20 })
              .textAlign(TextAlign.Center)
              .border({
                width: 2,
                color: '#9E9681'
              })
          }
          .width('100%')
          .height(25)
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#674625')
          .shadow({
            offsetX: 0,
            offsetY: 20,
            radius: 20,
            color: '#95000000'
          })
        }
        .width('100%')
        .height(this.coverWidth + 45)
        .justifyContent(FlexAlign.End)
        .visibility(this.libraryItemsFinished.length > 0 ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')

      Column() {
        Text("开始收听")
          .fontColor(Color.White)
          .fontSize(32)
          .margin({ top: 200 })
          .visibility(this.libraryItemsFinished.length === 0 && this.libraryItemsInProgress.length === 0 &&
            this.showProgressTransfer === false ?
          Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)

      // Column() {
      //   Loading()
      // }
      // .width('100%')
      // .height('100%')
      // .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }
}