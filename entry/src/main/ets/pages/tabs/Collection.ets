import { CollectionItemComponent, GlassFloatingButton } from "../../utils/Component";
import { Collection } from "../../utils/Interface"

@ComponentV2
export struct AllCollections {
  private collectionScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() collections: Collection[] = []
  @Consumer() statusBarHeight: number = 0

  build() {
    Stack() {
      Column() {
        Grid(this.collectionScroller) {
          GridItem() {
            Row() {
              Blank()
                .width('100%')
                .height(this.statusBarHeight + 56 + 36)
            }
          }
          .columnStart(0)
          .columnEnd(this.displayWidth >= 1200 ? 2 : (this.displayWidth >= 800 ? 1 : 0))

          ForEach(this.collections, (collection: Collection, index) => {
            GridItem() {
              CollectionItemComponent({
                collection: collection
              })
                .margin({ bottom: index === this.collections.length - 1 ? (this.isStartPlaying ? 104 : 20 ): 0 })
            }
          })
        }
        .width('100%')
        .height('100%')
        .columnsTemplate(this.displayWidth >= 1200 ? "1fr 1fr 1fr" : (this.displayWidth >= 800 ? "1fr 1fr" : "1fr"))
        .columnsGap(20)
        .rowsGap(15)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .padding({
          left: 20,
          right: 20
        })
        .clip(false)
        .visibility(this.collections.length > 0 ? Visibility.Visible : Visibility.None)


        Column() {
          Text("没有收藏")
            .fontSize(32)
            .fontColor($r('sys.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 100 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.collections.length === 0 ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .clip(false)


      GlassFloatingButton({
        scroller: this.collectionScroller,
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
