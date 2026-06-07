import { SeriesItemComponent, GlassFloatingButton } from "../../utils/Component";
import { Series } from "../../utils/Interface"

@ComponentV2
export struct AllSeries {
  private seriesScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() series: Series[] = []
  @Consumer() series1: Series | undefined = undefined
  @Consumer() isStartPlaying: boolean = false

  build() {
    Stack() {
      Column() {
        Grid(this.seriesScroller) {
          ForEach(this.series, (series: Series, index) => {
            GridItem() {
              SeriesItemComponent({
                series: series
              })
                .margin({ bottom: index === this.series.length - 1 ? (this.isStartPlaying ? 104 : 20 ): 0 })
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
          right: 20,
          top: 56
        })
        .onReachEnd(async () => {

        })
        .visibility(this.series.length > 0 ? Visibility.Visible : Visibility.None)

        Column() {
          Text("没有系列")
            .fontSize(32)
            .fontColor($r('sys.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 100 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.series.length === 0 ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')

      GlassFloatingButton({
        scroller: this.seriesScroller,
        isStartPlaying: this.isStartPlaying
      })
    }
    .width('100%')
    .height('100%')
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
  }
}