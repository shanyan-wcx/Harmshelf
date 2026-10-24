import { AuthorComponent1, GlassFloatingButton } from "../../utils/Component";
import { Author } from "../../utils/Interface";

@ComponentV2
export struct AllAuthors {
  private authorScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() authors: Author[] = []
  @Consumer() isStartPlaying: boolean = false
  @Consumer() statusBarHeight: number = 0

  build() {
    Stack() {
      Column() {
        Grid(this.authorScroller) {
          GridItem() {
            Row() {
              Blank()
                .width('100%')
                .height(this.statusBarHeight + 56 + 31)
            }
          }
          .columnStart(0)
          .columnEnd(this.displayWidth >= 1400 ? 7 :
            (this.displayWidth >= 1200 ? 6 :
              (this.displayWidth >= 1000 ? 5 :
                (this.displayWidth >= 800 ? 4 :
                  (this.displayWidth >= 400 ? 3 : 2)))))

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
          right: 20
        })
        .clip(false)
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
      .clip(false)


      GlassFloatingButton({
        scroller: this.authorScroller,
        isStartPlaying: this.isStartPlaying
      })
      .position({
        right: 15,
        bottom: this.isStartPlaying ? 99 : 15
      })
    }
    .width('100%')
    .height('100%')
    .clip(false)
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

  }
}
