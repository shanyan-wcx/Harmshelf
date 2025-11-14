import { fileIo as fs } from '@kit.CoreFileKit';
import { env } from '../utils/Class';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { PersistenceV2 } from '@kit.ArkUI';
import { ColorMode } from "../pages/Index";

@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() filesDir: string = ""
  @Local folderList: string[] = []
  @Local subFolderList: string[] = []
  @Local folderDeep: number = 0

  async aboutToAppear() {
    const entries = await fs.listFile(this.filesDir);
    for (let name of entries) {
      if (name !== "hiappevent") {
        const fullPath = `${this.filesDir}/${name}`;
        const stat = await fs.stat(fullPath);
        if (stat.isDirectory()) {
          this.folderList.push(name);
        }
      }
    }
  }

  build() {
    Stack() {
      Scroll(this.LocalMediaScroller) {
        Column() {
          Text("本地目录")
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 15, bottom: 15 })

          Column() {
            if (this.folderDeep === 0) {
              ForEach(this.folderList, (folder: string, index) => {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Text(folder)
                      .fontSize(20)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(20)
                      .fontColor([$r('sys.color.font_secondary')])
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                }
                .width('100%')
                .height(60)
                .borderRadius(8)
                .margin({ bottom: index !== this.folderList.length -1 ? 10 : 0 })
                .padding({ left: 20, right: 20 })
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  this.subFolderList = []
                  const entries = await fs.listFile(this.filesDir + "/" + folder);
                  for (let name of entries) {
                    const fullPath = `${this.filesDir}/${name}`;
                    const stat = await fs.stat(fullPath);
                    if (stat.isDirectory()) {
                      this.subFolderList.push(name);
                    }
                  }
                  this.folderDeep = 1
                })
              })
            } else if (this.folderDeep === 1) {
              Button({ type: ButtonType.Normal }) {
                Row() {
                  Text("返回上一级")
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(20)
                    .fontColor([$r('sys.color.font_secondary')])
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('100%')
              .height(60)
              .borderRadius(8)
              .margin({ bottom: 10 })
              .padding({ left: 20, right: 20 })
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onClick(async () => {
                this.folderDeep = 0
              })

              if (this.subFolderList.length > 0) {
                ForEach(this.subFolderList, (folder: string, index) => {
                  Button({ type: ButtonType.Normal }) {
                    Row() {
                      Text(folder)
                        .fontSize(20)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      SymbolGlyph($r('sys.symbol.chevron_right'))
                        .fontSize(20)
                        .fontColor([$r('sys.color.font_secondary')])
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }
                  .width('100%')
                  .height(60)
                  .borderRadius(8)
                  .margin({ bottom: index !== this.folderList.length -1 ? 10 : 0 })
                  .padding({ left: 20, right: 20 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(async () => {

                  })
                })
              } else {
                Row() {
                  Text("没有项目")
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                }
                .height(60)
                .borderRadius(8)
                .padding({ left: 20, right: 20 })
              }
            }
          }
          .width('100%')
          .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
            env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
            this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
            $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
          .borderRadius(8)
          .padding(20)
        }
        .padding({ left: 20, right: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 56, bottom: 25 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}