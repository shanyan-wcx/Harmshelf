import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Book, Collection, Series } from '../../api/Interface'

let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

@Component
export default struct collection {
  @Consume displayWidth: number = 0
  @State imageWidth: number = 0
  @State imageHeight: number = 0
  @State columnsTemplate: string = "1fr"
  @State libraryId: string = ''
  @Consume PageIndexTransfer: number
  @Consume showProgressTransfer: boolean
  @Consume collections: Collection[]
  @Consume backPageIndex: number
  @Consume sidebarShow: boolean
  @Consume mainWindow: window.Window
  @Consume collectionTransfer: Collection
  @Consume isSeries: boolean
  @Consume server: string
  @Consume apitoken: string

  private getPosition(item: Collection, index: number): number {
    const gap = this.imageWidth / (item.books.length - 1);
    if (item.books.length == 1) {
      return this.imageWidth / 2
    } else {
      return (item.books.length - 1 - index) * gap
    }
  }

  async aboutToAppear() {
    if (this.displayWidth >= 320 && this.displayWidth < 550) {
      this.columnsTemplate = "1fr"
    } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
      this.columnsTemplate = "1fr 1fr"
    } else if (this.displayWidth >= 840) {
      this.columnsTemplate = "1fr 1fr 1fr"
    }
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = px2vp(size.width)
      if (this.displayWidth >= 320 && this.displayWidth < 550) {
        this.columnsTemplate = "1fr"
      } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
        this.columnsTemplate = "1fr 1fr"
      } else if (this.displayWidth >= 840) {
        this.columnsTemplate = "1fr 1fr 1fr"
      }
    })
  }

  build() {
    Column() {
      Grid() {
        ForEach(this.collections, (item: Collection, index) => {
          GridItem() {
            Stack({ alignContent: Alignment.Bottom }) {
              ForEach(item.books.slice().reverse(), (item2: Book, index2) => {
                Image(this.server + `/api/items/${item2.id}/cover?format=jpeg&width=1024` + `&token=${this.apitoken}`)
                  .alt($rawfile('nocover.jpg'))
                  .height('100%')
                  .aspectRatio(1)
                  .clip(true)
                  .objectFit(ImageFit.Fill)
                  .onAreaChange((oldValue: Area, newValue: Area) => {
                    this.imageWidth = new Number(newValue.width).valueOf()
                    this.imageHeight = new Number(newValue.height).valueOf()
                  })
                  .position({ x: this.getPosition(item, index2) })
                  .shadow({
                    offsetX: 10,
                    offsetY: 0,
                    radius: 10,
                    color: '#95000000'
                  })
              })
              Column() {
                Text(item.name)
                  .fontColor('#F2E4C1')
                  .fontSize(16)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(25)
              .backgroundColor('#95000000')
              .justifyContent(FlexAlign.SpaceAround)
            }
            .width('100%')
            .height('100%')
            .borderRadius(10)
            .backgroundColor('#232323')
            .clip(true)
          }
          .aspectRatio(2)
          .borderRadius(10)
          .backgroundColor("#cccccc")
          .onClick(async () => {
            this.isSeries = false
            this.collectionTransfer = item
            this.backPageIndex = 0
            this.PageIndexTransfer = 4
            animateTo({
              duration: 300,
              curve: Curve.EaseOut,
            }, () => {
              this.sidebarShow = false
            })
          })
        })
      }
      .columnsTemplate(this.columnsTemplate)
      .columnsGap(20)
      .rowsGap(20)
      .margin({ left: 15, right: 15 })
      .padding({ top: 20, bottom: 20 })
      .height('100%')
      .scrollBar(BarState.Off)
      .visibility(this.collections.length !== 0 ? Visibility.Visible : Visibility.None)

      Text("没有收藏")
        .fontColor(Color.White)
        .fontSize(32)
        .margin({ top: 200 })
        .visibility(this.collections.length === 0 && this.showProgressTransfer === false ? Visibility.Visible :
        Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}