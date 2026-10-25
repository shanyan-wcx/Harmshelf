import { SeriesItemComponent } from "../../utils/Component";
import { Series } from "../../utils/Interface"
import { getBottomContentInset } from '../../utils/Layout';

@ComponentV2
export struct AllSeries {
  private seriesScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() series: Series[] = []
  @Consumer() series1: Series | undefined = undefined
  @Consumer() isStartPlaying: boolean = false
  @Consumer() statusBarHeight: number = 0
  build() {
    Stack() {
      Column() {
        Grid(this.seriesScroller) {
          GridItem() {
            Row() {
              Blank()
                .width('100%')
                .height(this.statusBarHeight + 56 + 36)
            }
          }
          .columnStart(0)
          .columnEnd(this.displayWidth >= 1200 ? 2 : (this.displayWidth >= 800 ? 1 : 0))

          ForEach(this.series, (series: Series, index) => {
            GridItem() {
              SeriesItemComponent({
                series: series
              })
                .margin({ bottom: index === this.series.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 104) : 0 })
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
      .clip(false)

    }
    .width('100%')
    .height('100%')
    .clip(false)
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
  }
}
