import { AuthorComponent1, GlassFloatingButton } from "../../utils/Component";
import { Author } from "../../utils/Interface";

@ComponentV2
export struct AllAuthors {
  private authorScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() authors: Author[] = []
  @Consumer() isStartPlaying: boolean = false

  build() {
    Stack() {
      Column() {
        Grid(this.authorScroller) {
          ForEach(this.authors, (author: Author, index) => {
            GridItem() {
              AuthorComponent1({
                author: author
              })
                .margin({ bottom: index === this.authors.length - 1 ? (this.isStartPlaying ? 104 : 20) : 0 })
            }
          })
        }
        .width('100%')
        .height('100%')
        .columnsTemplate(this.displayWidth >= 1400 ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
          (this.displayWidth >= 1200 ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
            (this.displayWidth >= 1000 ? "1fr 1fr 1fr 1fr 1fr 1fr" :
              (this.displayWidth >= 800 ? "1fr 1fr 1fr 1fr 1fr" :
                (this.displayWidth >= 400 ? "1fr 1fr 1fr 1fr" : "1fr 1fr 1fr")))))
        .columnsGap(20)
        .rowsGap(20)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .padding({
          left: 20,
          right: 20,
          top: 56
        })
        .onReachEnd(async () => {

        })
        .visibility(this.authors.length > 0 ? Visibility.Visible : Visibility.None)


        Column() {
          Text("没有作者")
            .fontSize(32)
            .fontColor($r('sys.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 100 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.authors.length === 0 ? Visibility.Visible : Visibility.None)

      }
      .width('100%')
      .height('100%')


      GlassFloatingButton({
        scroller: this.authorScroller,
        isStartPlaying: this.isStartPlaying
      })
    }
    .width('100%')
    .height('100%')
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

  }
}