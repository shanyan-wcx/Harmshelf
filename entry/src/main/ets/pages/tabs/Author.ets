import { window } from '@kit.ArkUI';
import { Author } from '../../api/Interface'

@Component
export default struct author {
  @Consume displayWidth: number = 0
  @State columnsTemplate: string = "1fr"
  @Consume PageIndexTransfer: number
  @Consume showProgressTransfer: boolean
  @State libraryId: string = ''
  @Consume authors: Author[]
  @Consume backPageIndex: number
  @Consume sidebarShow: boolean
  @Consume mainWindow: window.Window
  @Consume server: string
  @Consume apitoken: string

  async aboutToAppear() {
    if (this.displayWidth >= 320 && this.displayWidth < 550) {
      this.columnsTemplate = "1fr 1fr 1fr"
    } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
      this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr"
    } else if (this.displayWidth >= 840) {
      this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr 1fr"
    }
    this.mainWindow.on('windowSizeChange', (size) => {
      this.displayWidth = px2vp(size.width)
      if (this.displayWidth >= 320 && this.displayWidth < 550) {
        this.columnsTemplate = "1fr 1fr 1fr"
      } else if (this.displayWidth >= 550 && this.displayWidth < 840) {
        this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr"
      } else if (this.displayWidth >= 840) {
        this.columnsTemplate = "1fr 1fr 1fr 1fr 1fr 1fr"
      }
    })
  }

  build() {
    Column() {
      Grid() {
        ForEach(this.authors, (item: Author, index) => {
          GridItem() {
            Stack({ alignContent: Alignment.Bottom }) {
              Image(item.imagePath === null ? "" :
                this.server + `/api/authors/${item.id}/image?format=jpeg` + `&token=${this.apitoken}`)
                .alt($rawfile('noprofile.jpg'))
                .width('100%')
                .aspectRatio(3 / 4)
                .borderRadius(10)
                .objectFit(ImageFit.Fill)
              Column() {
                Text(item.name)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Bold)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.numBooks + " 图书")
                  .fontSize(13)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(40)
              .backgroundColor('#75000000')
              .justifyContent(FlexAlign.SpaceAround)
            }
            .width('100%')
            .borderRadius(10)
            .clip(true)
          }
          .borderRadius(10)
          .onClick(async () => {
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
      .visibility(this.authors.length !== 0 ? Visibility.Visible : Visibility.None)

      Text("没有作者")
        .fontColor(Color.White)
        .fontSize(32)
        .margin({ top: 200 })
        .visibility(this.authors.length === 0 && this.showProgressTransfer === false ? Visibility.Visible :
        Visibility.None)
    }
    .width('100%')
    .height('100%')
  }
}