import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { DownloadManager, DownloadStatus, DownloadTaskInfo } from '../utils/Download';

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
  @Consumer() downloadTasks: DownloadTaskInfo[] = [];
  @Monitor('downloadTasks')
  async goBackPage(monitor: IMonitor) {
    if (this.downloadTasks.length === 0) {
      this.pageInfos.pop()
    }
  }

  build() {
    HdsNavDestination() {
      Stack() {
        List({ scroller: this.downloadTaskScroller }) {
          ForEach(this.downloadTasks, (task: DownloadTaskInfo, index) => {
            ListItem() {
              Column() {
                Row() {
                  Text(task.title)
                    .fontSize(18)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .layoutWeight(1)

                  Text(Math.floor(task.progress) + "%")
                    .fontSize(18)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ left: 15 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .margin({ top: 15 })

                Progress({ value: task.status === DownloadStatus.Failed ? 100 : task.progress, total: 100, type: ProgressType.Linear })
                  .width('100%')
                  .margin({ top: 12, bottom: 17 })
                  .style({ strokeWidth: 6, enableSmoothEffect: false })
                  .color(task.status === DownloadStatus.Failed ? $r('sys.color.warning') : (task.status === DownloadStatus.Paused ? $r('sys.color.comp_background_tertiary') : $r('sys.color.comp_emphasize_secondary')))
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20
              })
            }
            .margin({ top: index === 0 ? this.statusBarHeight + 49 : 0, bottom: index === this.downloadTasks.length - 1 ? (this.isStartPlaying ? 89 : 10) : 0 })
          })
        }
        .cachedCount(2)
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
        .divider({
          strokeWidth: 1,
          startMargin: 20,
          endMargin: 20,
          color: $r('sys.color.comp_divider')
        })
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.End)
    }
    .width('100%')
    .height('100%')
    .titleBar({
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false,
      padding: {
        start: LengthMetrics.vp(16),
        end: LengthMetrics.vp(16)
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          blurEffectiveStartOffset: LengthMetrics.vp(8)
        }
      },
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