import { LibraryItemComponent1 } from "../utils/Component";
import { Filter1, LibraryItem, Progress, Media, Series } from "../utils/Interface";
import { LengthMetrics } from "@kit.ArkUI";
import { HdsNavDestination, HdsNavDestinationAttribute } from "@kit.UIDesignKit";

@Builder
export function filterItemsBuilder(name: string, filter: Filter1) {
  FilterItems({ criteria: filter.criteria, type: filter.type })
}

@ComponentV2
export struct FilterItems {
  private filterItemsScroller: Scroller = new Scroller()
  @Require @Param criteria: string = ""
  @Require @Param type: string = ""
  @Consumer() displayWidth: number = 0
  @Consumer() statusBarHeight: number = 0
  @Consumer() libraryItems: LibraryItem[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() series1: Series | undefined = undefined
  @Consumer() isStartPlaying: boolean = false
  @Local filterItems: LibraryItem[] = []
  @Local showLoadingProgress: boolean = false

  searchAuthor(media: Media, criteria: string) {
    if (!media.metadata || !criteria || criteria.length === 0) {
      return false;
    }
    if (media.metadata.authorName && media.metadata.authorName === criteria) {
      return true
    }
    if (media.metadata.author && media.metadata.author === criteria) {
      return true
    }
    if (media.metadata.authors?.some(author => author.name === criteria)) {
      return true;
    }
    return false
  }

  searchNarrator(media: Media, criteria: string) {
    if (!media.metadata || !criteria || criteria.length === 0) {
      return false;
    }
    if (media.metadata.narratorName && media.metadata.narratorName === criteria) {
      return true
    }
    if (media.metadata.narrators?.some(narrator => narrator === criteria)) {
      return true;
    }
    return false
  }

  searchGenre(media: Media, criteria: string) {
    if (!media.metadata || !criteria || criteria.length === 0) {
      return false;
    }
    if (media.metadata.genres?.some(genre => genre === criteria)) {
      return true;
    }
    return false
  }

  searchTag(media: Media, criteria: string) {
    if (!media || !criteria || criteria.length === 0) {
      return false;
    }
    if (media.tags?.some(tag => tag === criteria)) {
      return true;
    }
    return false
  }

  aboutToAppear() {
    this.showLoadingProgress = true
    if (this.type === "series") {
      if (this.series1) {
        const bookIds = new Set(this.series1!.books.map(book => book.id));
        this.filterItems =  this.libraryItems.filter(item => bookIds.has(item.id));
      }
    } else {
      this.libraryItems.forEach((libraryItem: LibraryItem, index) => {
        let media = libraryItem.media
        if (this.type === "author") {
          if (this.searchAuthor(media, this.criteria)) {
            this.filterItems.push(libraryItem)
          }
        } else if (this.type === "narrator") {
          if (this.searchNarrator(media, this.criteria)) {
            this.filterItems.push(libraryItem)
          }
        } else if (this.type === "genre") {
          if (this.searchGenre(media, this.criteria)) {
            this.filterItems.push(libraryItem)
          }
        } else if (this.type === "tag") {
          if (this.searchTag(media, this.criteria)) {
            this.filterItems.push(libraryItem)
          }
        }
      })
    }
    this.showLoadingProgress = false
  }

  build() {
    HdsNavDestination() {
      Stack() {
        Column() {
          Grid(this.filterItemsScroller) {
            ForEach(this.filterItems, (libraryItem: LibraryItem, index) => {
              GridItem() {
                LibraryItemComponent1({
                  item: libraryItem,
                  progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
                })
                  .margin({ bottom: index === this.filterItems.length - 1 ? 20 : 0 })
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
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
          .padding({
            left: 20,
            right: 20,
            top: 64 + this.statusBarHeight,
            bottom: this.isStartPlaying ? 82 : 0
          })
          .onReachEnd(async () => {

          })
          .visibility(this.filterItems.length > 0 ? Visibility.Visible : Visibility.None)

          Column() {
            Text("没有媒体")
              .fontSize(32)
              .fontColor($r('sys.color.font'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .visibility(this.filterItems.length === 0 ? Visibility.Visible : Visibility.None)
        }
        .width('100%')
        .height('100%')
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        Button({ type: ButtonType.Normal }) {
          SymbolGlyph($r('sys.symbol.arrow_up_to_line'))
            .fontWeight(FontWeight.Normal)
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .hitTestBehavior(HitTestMode.None)
        }
        .position({
          right: 15,
          bottom: 15
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
          this.filterItemsScroller.scrollEdge(Edge.Top)
        })
        .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(72)
            .color($r('sys.color.loading_progress_focused_color'))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .visibility(this.showLoadingProgress === true ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .titleBar({
      avoidLayoutSafeArea:true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true
        }
      },
      content: {
        title: {
          mainTitle: this.criteria
        }
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.filterItemsScroller])
  }
}