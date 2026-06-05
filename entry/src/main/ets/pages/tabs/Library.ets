import { LibraryItemComponent1 } from '../../utils/Component';
import { Library, LibraryItem, Progress } from '../../utils/Interface';

@ComponentV2
export struct MediaLibrary {
  private mediaLibraryScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() isStartPlaying: boolean = false

  build() {
    Stack() {
      Column() {
        Grid(this.mediaLibraryScroller) {
          ForEach(this.libraryItems, (libraryItem: LibraryItem, index) => {
            GridItem() {
              LibraryItemComponent1({
                item: libraryItem,
                progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
              })
                .margin({ bottom: index === this.libraryItems.length - 1 ? (this.isStartPlaying ? 104 : 20) : 0 })
            }
          })
        }
        .width('100%')
        .height('100%')
        .columnsTemplate(this.displayWidth >= 1400 ? "1fr 1fr 1fr 1fr 1fr 1fr" :
          (this.displayWidth >= 1000 ? "1fr 1fr 1fr 1fr 1fr" :
            (this.displayWidth >= 800 ? "1fr 1fr 1fr 1fr" :
              (this.displayWidth >= 400 ? "1fr 1fr 1fr" : "1fr 1fr"))))
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
        .visibility(this.libraryItems.length > 0 ? Visibility.Visible : Visibility.None)

        Column() {
          Text("没有媒体")
            .fontSize(32)
            .fontColor($r('sys.color.font'))
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 100 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.libraryItems.length === 0 ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')

      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.arrow_up_to_line'))
          .fontWeight(FontWeight.Normal)
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          .hitTestBehavior(HitTestMode.None)
      }
      .position({
        right: 15,
        bottom: this.isStartPlaying ? 99 : 15
      })
      .animation({ duration: 510, curve: Curve.EaseInOut })
      .width(36)
      .height(36)
      .borderRadius(6)
      .backgroundColor(Color.Transparent)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .shadow({
        radius: 12,
        color: $r('sys.color.font'),
      })
      .onClick(async () => {
        this.mediaLibraryScroller.scrollEdge(Edge.Top)
      })
    }
    .width('100%')
    .height('100%')
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
  }
}