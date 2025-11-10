import {
  AuthorComponent, LibraryItemComponent, pageUpDown, RecentEpisodeComponent
} from "../../utils/Component"
import { Author, HomeSection, Library, LibraryItem, Progress } from "../../utils/Interface"

@ComponentV2
export struct SubHome {
  private homeScroller: Scroller = new Scroller();
  private continueListeningScroller: Scroller = new Scroller();
  private newestEpisodesScroller: Scroller = new Scroller();
  private recentlyAddedScroller: Scroller = new Scroller();
  private discoverScroller: Scroller = new Scroller();
  private listenAgainScroller: Scroller = new Scroller();
  private newestAuthorsScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() library: Library | undefined = undefined
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() homeData: HomeSection[] = []
  @Consumer() progress: Progress[] = []
  @Consumer() isStartPlaying: boolean = false

  build() {
    Stack() {
      Scroll(this.homeScroller) {
        Column() {
          if (this.homeData.some(item => item.id === "continue-listening")) {
            Column() {
              Row() {
                Text("继续收听")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.continueListeningScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.continueListeningScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "continue-listening")!.entities,
                  (libraryItem: LibraryItem, index) => {
                  if (this.library?.mediaType === 'book') {
                    ListItem() {
                      LibraryItemComponent({
                        item: libraryItem,
                        progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
                      })
                        .margin({
                          left: index === 0 ? 20 : 0,
                          right: index ===
                            this.homeData.find(item => item.id === "continue-listening")!.entities.length - 1 ? 20 : 0
                        })
                    }
                  } else if (this.library?.mediaType === 'podcast') {
                    ListItem() {
                      RecentEpisodeComponent({
                        item: libraryItem,
                        progress: this.progress.find(p => p.episodeId === libraryItem.recentEpisode?.id)
                      })
                        .margin({
                          left: index === 0 ? 20 : 0,
                          right: index ===
                            this.homeData.find(item => item.id === "continue-listening")!.entities.length - 1 ? 20 : 0
                        })
                    }
                  }
                  })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          if (this.homeData.some(item => item.id === "newest-episodes")) {
            Column() {
              Row() {
                Text("最新剧集")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.newestEpisodesScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.newestEpisodesScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "newest-episodes")!.entities,
                  (libraryItem: LibraryItem, index) => {
                    ListItem() {
                      RecentEpisodeComponent({
                        item: libraryItem,
                        progress: this.progress.find(p => p.episodeId === libraryItem.recentEpisode?.id)
                      })
                        .margin({
                          left: index === 0 ? 20 : 0,
                          right: index ===
                            this.homeData.find(item => item.id === "newest-episodes")!.entities.length - 1 ? 20 : 0
                        })
                    }
                  })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          if (this.homeData.some(item => item.id === "recently-added")) {
            Column() {
              Row() {
                Text("最近添加")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.recentlyAddedScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.recentlyAddedScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "recently-added")!.entities,
                  (libraryItem: LibraryItem, index) => {
                    ListItem() {
                      LibraryItemComponent({
                        item: libraryItem,
                        progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
                      })
                        .margin({
                          left: index === 0 ? 20 : 0,
                          right: index ===
                            this.homeData.find(item => item.id === "recently-added")!.entities.length - 1 ? 20 : 0
                        })
                    }
                  })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          if (this.homeData.some(item => item.id === "discover")) {
            Column() {
              Row() {
                Text("发现")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.discoverScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.discoverScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "discover")!.entities,
                  (libraryItem: LibraryItem, index) => {
                    ListItem() {
                      LibraryItemComponent({
                        item: libraryItem,
                        progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
                      })
                        .margin({
                          left: index === 0 ? 20 : 0,
                          right: index === this.homeData.find(item => item.id === "discover")!.entities.length - 1 ?
                            20 : 0
                        })
                    }
                  })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }


          if (this.homeData.some(item => item.id === "listen-again")) {
            Column() {
              Row() {
                Text("再次收听")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.listenAgainScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.listenAgainScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "listen-again")!.entities,
                  (libraryItem: LibraryItem, index) => {
                    if (this.library?.mediaType === 'book') {
                      ListItem() {
                        LibraryItemComponent({
                          item: libraryItem,
                          progress: this.progress.find(p => p.libraryItemId === libraryItem.id)
                        })
                          .margin({
                            left: index === 0 ? 20 : 0,
                            right: index === this.homeData.find(item => item.id === "listen-again")!.entities.length - 1 ?
                              20 : 0
                          })
                      }
                    } else if (this.library?.mediaType === 'podcast') {
                      ListItem() {
                        RecentEpisodeComponent({
                          item: libraryItem,
                          progress: this.progress.find(p => p.episodeId === libraryItem.recentEpisode?.id)
                        })
                          .margin({
                            left: index === 0 ? 20 : 0,
                            right: index === this.homeData.find(item => item.id === "listen-again")!.entities.length - 1 ?
                              20 : 0
                          })
                      }
                    }
                  })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          if (this.homeData.some(item => item.id === "newest-authors")) {
            Column() {
              Row() {
                Text("最新作者")
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)

                pageUpDown({
                  scroller: this.newestAuthorsScroller
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 3 })
              .padding({
                top: 16,
                left: 20,
                right: 20,
                bottom: 5
              })

              List({ scroller: this.newestAuthorsScroller, space: 20 }) {
                ForEach(this.homeData.find(item => item.id === "newest-authors")!.entities, (author: Author, index) => {
                  ListItem() {
                    AuthorComponent({
                      author: author
                    })
                      .margin({
                        left: index === 0 ? 20 : 0,
                        right: index === this.homeData.find(item => item.id === "newest-authors")!.entities.length - 1 ?
                          20 : 0
                      })
                  }
                })
              }
              .width('100%')
              .height(this.displayWidth >= 1400 ? 245 : (this.displayWidth >= 1200 ? 225 : 205))
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }

          Column() {
            Text("开始收听")
              .fontSize(34)
              .fontColor($r('sys.color.font'))
          }
          .width('100%')
          .height('100%')
          .padding({ bottom: 155 })
          .justifyContent(FlexAlign.Center)
          .visibility(this.homeData.length === 0 || this.homeData.every(item => item.entities.length === 0) ?
            Visibility.Visible : Visibility.None)
        }

      }
      .width('100%')
      .height('100%')
      .padding({ top: 36, bottom: this.isStartPlaying ? 104 : 20 })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

    }
    .width('100%')
    .height('100%')
    .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)

    // .onClick(() => {
    //   this.homeData.forEach((data, index) => {
    //     console.log(data.id)
    //   })
    // })
  }
}