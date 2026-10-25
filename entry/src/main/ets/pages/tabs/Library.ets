import { LibraryItemComponent1 } from '../../utils/Component';
import { Library, LibraryItem, Progress } from '../../utils/Interface';
import { getBottomContentInset } from '../../utils/Layout';

@ComponentV2
export struct MediaLibrary {
  private mediaLibraryScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() library: Library | undefined = undefined
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() isStartPlaying: boolean = false
  @Consumer() statusBarHeight: number = 0
  build() {
    Stack() {
      Column() {
        Grid(this.mediaLibraryScroller) {
          GridItem() {
            Row() {
              Blank()
                .width('100%')
                .height(this.statusBarHeight + 56 + 36)
            }
          }
          .columnStart(0)
          .columnEnd(this.displayWidth >= 1400 ? 5 :
            (this.displayWidth >= 1000 ? 4 :
              (this.displayWidth >= 800 ? 3 :
                (this.displayWidth >= 400 ? 2 : 1))))

          ForEach(this.libraryItems, (libraryItem: LibraryItem, index) => {
            GridItem() {
              LibraryItemComponent1({
                item: libraryItem,
                progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
              })
                .margin({ bottom: index === this.libraryItems.length - 1 ? getBottomContentInset(20, this.isStartPlaying, 104) : 0 })
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
          right: 20
        })
        .clip(false)
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
      .clip(false)

    }
    .width('100%')
    .height('100%')
    .clip(false)
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
  }
}
