import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { DownloadTaskInfo } from '../utils/Download';

@Builder
export function downloadTaskBuilder(name: string, param: Object) {
  DownloadTask()
}

@ComponentV2
export struct DownloadTask {
  private downloadTaskScroller: Scroller = new Scroller();
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
              Row() {
                Text((index + 1).toString())
                  .fontSize(18)
                  .width(60)
                  .textAlign(TextAlign.Center)
                  .margin({ right: 15 })

                Text(task.title)
                  .fontSize(18)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height(60)
              .margin({ bottom: index === this.downloadTasks.length - 1 ? (this.isStartPlaying ? 99 : 20) : 0 })
              .onClick(() => {

              })
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({
          left: 20,
          right: 20,
          top: 56 + this.statusBarHeight
        })
        .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
        .scrollBar(BarState.Off)
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
          enableScrollEffect: true
        }
      },
      content: {
        title: {
          mainTitle: "下载队列 " + this.downloadTasks.length
        },
        menu: {
          value: [{
            content: {
              icon: $r('sys.symbol.pause'),
              label: 'pause',
              action: () => {
                this.getUIContext().getPromptAction().showToast({
                  message: '下载队列全部暂停！',
                  duration: 500
                });
              }
            }
          }, {
            content: {
              icon: $r('sys.symbol.play'),
              label: 'start',
              action: () => {
                this.getUIContext().getPromptAction().showToast({
                  message: '下载队列全部开始！',
                  duration: 500
                });
              }
            }
          }, {
            content: {
              icon: $r('sys.symbol.trash'),
              label: 'clear',
              action: () => {
                this.getUIContext().getPromptAction().showToast({
                  message: '下载队列清空！',
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