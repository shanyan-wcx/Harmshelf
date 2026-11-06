import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { DownloadManager, DownloadStatus, DownloadTaskInfo } from '../utils/Class';
import { gradientBlurTitleBarStyle } from '../utils/Component';
import { getBottomContentInset } from '../utils/Layout';

@Builder
export function downloadTaskBuilder(name: string, param: Object) {
  DownloadTask()
}

@ComponentV2
export struct DownloadTask {
  private downloadTaskScroller: Scroller = new Scroller();
  @Consumer() downloadManager: DownloadManager | undefined = undefined
  @Consumer() displayWidth: number = 0
  @Consumer() statusBarHeight: number = 0
  @Consumer() sideBarContentWidth: number = 0
  @Consumer() pageInfos: NavPathStack = new NavPathStack();
  @Consumer() isStartPlaying: boolean = false
  @Consumer() downloadTasks: DownloadTaskInfo[] = []
  @Consumer() downloadCount: number = 0
  @Monitor('downloadCount')
  async goBackPage(monitor: IMonitor) {
    if (this.downloadCount === 0) {
      this.pageInfos.pop()
    }
  }

  build() {
    HdsNavDestination() {
      Stack() {
        List({ scroller: this.downloadTaskScroller }) {
          Repeat<DownloadTaskInfo>(this.downloadTasks)
            .each((task: RepeatItem<DownloadTaskInfo>) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(task.item.title)
                      .fontSize(16)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .layoutWeight(1)

                    Text(Math.floor(task.item.progress) + "%")
                      .fontSize(16)
                      .fontColor($r('sys.color.font_secondary'))
                      .margin({ left: 15 })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)

                  Progress({
                    value: task.item.status === DownloadStatus.Failed ? 100 : task.item.progress,
                    total: 100,
                    type: ProgressType.Linear
                  })
                    .width('100%')
                    .style({ strokeWidth: 6, enableSmoothEffect: false })
                    .color(task.item.status === DownloadStatus.Failed ? $r('sys.color.warning') :
                      (task.item.status === DownloadStatus.Paused ? $r('sys.color.comp_background_tertiary') :
                        $r('sys.color.comp_emphasize_secondary')))
                }
                .width('100%')
                .height(80)
                .padding({ left: 16, right: 16 })
                .justifyContent(FlexAlign.Center)
                .borderRadius(18)
                .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .border({
                  width: 0.35,
                  radius: 18,
                  color: $r('sys.color.ohos_id_color_focused_outline_transparent')
                })
                .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                .clip(false)
              }
              .width('100%')
              .margin({
                left: 20,
                right: 20,
                top: task.index === 0 ? this.statusBarHeight + 56 : 0,
                bottom: task.index === this.downloadTasks.length - 1 ? getBottomContentInset(12, this.isStartPlaying, 89, false) : 12
              })
              .clip(false)
            })
            .virtualScroll({ totalCount: this.downloadTasks.length })
            .key(task => task.id)
        }
        .cachedCount(3)
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .clip(false)

      if (this.downloadTasks.length === 0) {
        Column({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.download'))
            .fontSize(48)
            .fontColor([$r('sys.color.font_secondary')])

          Text("暂无下载任务")
            .fontSize(18)

          Text("下载的内容会显示在这里")
            .fontSize(13)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .height('100%')
        .padding({
          top: this.statusBarHeight + 56,
          bottom: getBottomContentInset(20, this.isStartPlaying, 89, false)
        })
        .justifyContent(FlexAlign.Center)
      }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Top)
      .clip(false)
    }
    .width('100%')
    .height('100%')
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      style: gradientBlurTitleBarStyle(),
      content: {
        title: {
          mainTitle: "下载队列 " + this.downloadTasks.length
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.clean'),
              label: "clean",
              action: async () => {
                await this.downloadManager!.clearAll()
                this.downloadTasks.splice(0, this.downloadTasks.length)
                this.downloadCount = this.downloadTasks.length
                this.getUIContext().getPromptAction().showToast({
                  message: '清除全部下载任务！',
                  duration: 500
                });
              }
            }
          }]
        }
      }
    })
    .hideBackButton(false)
    .backgroundColor($r('sys.color.background_secondary'))
    .bindToScrollable([this.downloadTaskScroller])
  }
}
