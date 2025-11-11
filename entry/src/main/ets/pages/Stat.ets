import { getStats, getUser } from "../utils/Api"
import { Library, ListeningStats, RecentSession } from "../utils/Interface"
import { UChartsV2, UChartsController, ChartOptions } from '@ibestservices/ucharts'
import { env } from "../utils/Class";
import { ConfigurationConstant } from "@kit.AbilityKit";

@ComponentV2
export struct Stats {
  @Consumer() statsScroller: Scroller = new Scroller();
  @Consumer() displayWidth: number = 0
  @Consumer() showLoadingProgress: boolean = false
  @Consumer() library: Library | undefined = undefined
  @Consumer() isStartPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Local colorMode: ConfigurationConstant.ColorMode | undefined = env.colorMode
  @Local stats: ListeningStats | undefined = undefined
  @Local chart: UChartsController = new UChartsController()
  @Local weekdays: string[] = []
  @Local minutes: number[] = []
  @Local gridColHeight: number = 0
  @Local finishedNum: number = -1
  private timerId: number | undefined = undefined
  private lastMode: ConfigurationConstant.ColorMode | undefined = undefined

  updateChart() {
    let opts: Partial<ChartOptions> = {
      type: "line",
      dataLabel: false,
      animation: false,
      color: [env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '#BCBCBC' : '#2E2F2F'],
      categories: this.stats?.days ? this.weekdays : ["-", "-", "-", "-", "-", "-", "-"],
      series: [
        {
          name: "分钟",
          data: this.stats?.days ? this.minutes : [0, 0, 0, 0, 0, 0, 0]
        }
      ],
      padding: [10, 0, 0, 0],
      legend: {
        show: false
      },
      xAxis: {
        disableGrid: true,
        fontSize: this.displayWidth >= 1000 ? 16 : 12,
        marginTop: 10
      },
      yAxis: {
        splitNumber: 6,
        data: [{
          min: 0,
          max: this.minutes.length > 0 ? (Math.max(...this.minutes) * 2 > 6 ? Math.max(...this.minutes) * 2 : 6) : 0,
          fontSize: this.displayWidth >= 1000 ? 15 : 12,
          axisLine: false
        }]
      },
      extra: {
        line: {
          type: "straight",
          width: 3,
          onShadow: false
        }
      }
    }
    this.chart.updateData(opts)
  }

  getConsecutiveDays(days: Record<string, number> | undefined): number {
    if (!days) {
      return 0
    }
    let dateKeys: string[] = Object.keys(days);
    if (dateKeys.length === 0) {
      return 0;
    }
    dateKeys.sort((a, b) => new Date(a).getTime() - new Date(b).getTime());
    let today = new Date();
    let count = 0;
    while (true) {
      let dateStr = today.toISOString().split("T")[0];
      if (days[dateStr] !== undefined) {
        count++;
        today.setDate(today.getDate() - 1);
      } else {
        break;
      }
    }
    return count;
  }

  formatDuration(seconds: number): string {
    if (seconds < 60) {
      return `${Math.floor(seconds)} sec`;
    } else if (seconds < 3600) {
      return `${Math.floor(seconds / 60)} min`;
    } else {
      return `${Math.floor(seconds / 3600)} hr`;
    }
  }

  async aboutToAppear() {
    if (this.baseUrl !== "") {
      this.showLoadingProgress = true
      this.stats = await getStats()
      this.finishedNum = (await getUser())?.mediaProgress.filter(p => p.isFinished).length??-1
      const weekMap: string[] = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
      if (this.stats && this.stats.days) {
        const daysObj = this.stats.days
        const today = new Date()
        for (let offset = 6; offset >= 0; offset--) {
          const d = new Date(today.getTime())
          d.setDate(today.getDate() - offset)
          const year = d.getFullYear()
          const month = (d.getMonth() + 1).toString().padStart(2, '0')
          const day = d.getDate().toString().padStart(2, '0')
          const dateStr = `${year}-${month}-${day}`
          let rawValue: number | undefined = daysObj[dateStr]
          if (rawValue === undefined) {
            rawValue = 0
          }
          const minuteValue = Math.round(rawValue / 60)
          this.weekdays.push(weekMap[d.getDay()])
          this.minutes.push(minuteValue)
        }
      }
      this.updateChart()
      this.timerId = setInterval(() => {
        const currentMode = env.colorMode
        if (currentMode !== this.lastMode) {
          this.lastMode = currentMode
          this.updateChart()
        }
      }, 1000)
      this.showLoadingProgress = false
    }
  }

  aboutToDisappear() {
    if (this.timerId) {
      clearInterval(this.timerId)
      this.timerId = undefined
    }
  }

  build() {
    if (this.baseUrl !== "") {
      Scroll(this.statsScroller) {
        GridRow({
          columns: {
            xs: 1,
            sm: 2,
          },
          breakpoints: {
            value: ['1000vp'],
            reference: BreakpointsReference.WindowSize
          },
          gutter: {
            x: 0
          }
        }) {
          GridCol({ span: this.displayWidth >= 1000 ? 2 : 1 }) {
            Column() {
              Text("你的统计数据")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 10 })
                .width('100%')

              Row() {
                Column() {
                  Text(this.finishedNum !== -1 ? this.finishedNum.toString() : "0")
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 5 })

                  Text("已完成的项目")
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'))
                }

                Column() {
                  Text(this.stats?.days ? Object.keys(this.stats?.days).length.toString() : "0")
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 5 })

                  Text("收听天数")
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'))
                }

                Column() {
                  Text(this.stats?.totalTime ? (Math.floor(this.stats?.totalTime / 60)).toString() : "0")
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 5 })

                  Text("收听分钟数")
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'))
                }
              }
              .width('100%')
              .justifyContent(this.displayWidth >= 800 ? FlexAlign.SpaceEvenly :
                (this.displayWidth >= 450 ? FlexAlign.SpaceAround : FlexAlign.SpaceBetween))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 20 })
          }
          .padding({ left: this.displayWidth >= 1000 ? 40 : 20, right: this.displayWidth >= 1000 ? 40 : 20 })

          GridCol({ span: 1 }) {
            Column() {
              Text("收听分钟数（最近七天）")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 20, left: 5 })
                .width('100%')

              UChartsV2({ controller: this.chart, contentHeight: 260 })
                .margin({ bottom: 20 })

              Blank()

              Row() {
                Column() {
                  Text("每周收听")
                    .fontSize(16)

                  Text(this.minutes.reduce((acc, cur) => acc + cur, 0).toString())
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)

                  Text("分钟")
                    .fontSize(16)
                }

                Column() {
                  Text("每日平均值")
                    .fontSize(16)

                  Text(this.minutes.length > 0 ?
                    (Math.floor(this.minutes.reduce((acc, cur) => acc + cur, 0) / this.minutes.length)).toString() :
                    "0")
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)

                  Text("分钟")
                    .fontSize(16)
                }

                Column() {
                  Text("单日最高")
                    .fontSize(16)

                  Text(this.minutes.length > 0 ? Math.max(...this.minutes).toString() : "0")
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)

                  Text("分钟")
                    .fontSize(16)
                }

                Column() {
                  Text("连续")
                    .fontSize(16)

                  Text(this.getConsecutiveDays(this.stats?.days).toString())
                    .fontSize(this.displayWidth >= 1000 ? 48 : 36)
                    .fontWeight(FontWeight.Bold)

                  Text("天")
                    .fontSize(16)
                }
              }
              .width('100%')
              .margin({ left: 5, top: this.displayWidth >= 1000 ? 20 : 0, bottom: 20 })
              .justifyContent(FlexAlign.SpaceBetween)

              Blank()
            }
            .width('100%')
            .height(this.displayWidth >= 1000 ? this.gridColHeight : 'auto')
          }
          .padding({ left: this.displayWidth >= 1000 ? 35 : 15, right: this.displayWidth >= 1000 ? 40 : 20 })

          GridCol({ span: 1 }) {
            Column() {
              Text("历史会话")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 6 })
                .width('100%')

              ForEach(this.stats?.recentSessions, (recentSession: RecentSession, index) => {
                Row() {
                  Text((index + 1) + ".")
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'))
                    .width(40)

                  Column() {
                    Text(recentSession.mediaMetadata.title)
                      .fontSize(16)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(recentSession.date)
                      .fontSize(15)
                      .fontColor($r('sys.color.font_secondary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Text(this.formatDuration(recentSession.timeListening))
                    .fontSize(16)
                    .fontColor($r('sys.color.font_secondary'))
                    .margin({ left: 20 })
                    .textAlign(TextAlign.End)
                }
                .height(48)
              })
            }
            .width('100%')
            .onSizeChange((oldValue, newValue) => {
              if (newValue.height) {
                this.gridColHeight = Number(newValue.height)
              }
            })
          }
          .padding({ left: this.displayWidth >= 1000 ? 40 : 20, right: this.displayWidth >= 1000 ? 40 : 20 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.displayWidth >= 1000 ? 85 : 65, bottom: this.isStartPlaying ? 99 : 20 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .visibility(this.showLoadingProgress ? Visibility.None : Visibility.Visible)
    } else {
      Column() {
        Text("没有服务器")
          .fontSize(32)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 36 })
      .justifyContent(FlexAlign.Center)
    }
  }
}