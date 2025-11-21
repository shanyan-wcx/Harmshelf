import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { env } from '../utils/Class';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { PersistenceV2 } from '@kit.ArkUI';
import { ColorMode } from "../pages/Index";
import { PlayItem } from '../utils/Interface';
import { media } from '@kit.MediaKit';

@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() downloadUri: string = ""
  @Local folderList: string[] = []
  @Local subFolderList: string[] = []
  @Local audioFolderList: string[] = []
  @Local folderDeep: number = 0
  @Local mediaType: string = ""
  @Local metadata: string | undefined = undefined
  @Local folderIdx: number = 0
  @Local subFolderIdx: number = 0
  @Local downloadPath: string = ""
  private audioExts = ['mp3', 'flac', 'wav', 'aac', 'm4a', 'm4b', 'ogg'];

  isAudioFile(fileName: string): boolean {
    let ext = fileName.split('.').pop();
    if (!ext) {
      return false;
    }
    return this.audioExts.includes(ext.toLowerCase());
  }

  async aboutToAppear() {
    this.downloadPath = new fileUri.FileUri(this.downloadUri).path
    const entries = await fs.listFile(this.downloadPath);
    for (let name of entries) {
      const fullPath = `${this.downloadPath}/${name}`;
      const stat = await fs.stat(fullPath);
      if (stat.isDirectory()) {
        this.folderList.push(name);
      }
    }
  }

  build() {
    Stack() {
      Scroll(this.LocalMediaScroller) {
        Column() {
          Column() {
            Text("本地媒体")
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 15, bottom: 15 })

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
                .margin({ bottom: index !== this.folderList.length - 1 ? 10 : 0 })
                .padding({ left: 20, right: 20 })
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(async () => {
                  this.subFolderList = []
                  const entries = await fs.listFile(this.downloadPath + "/" + folder);
                  for (let name of entries) {
                    const fullPath = `${this.downloadPath}/${folder}/${name}`;
                    const stat = await fs.stat(fullPath);
                    if (stat.isDirectory()) {
                      this.subFolderList.push(name);
                    }
                  }
                  if (folder === "有声书") {
                    this.mediaType = "book"
                  } else if (folder === "播客") {
                    this.mediaType = "podcast"
                  }
                  this.folderIdx = index
                  this.folderDeep = 1
                  this.metadata = undefined
                  if (fs.accessSync(this.downloadPath + "/" + folder + "/metadata.json")) {
                    this.metadata = await fs.readText(this.downloadPath + "/" + folder + "/metadata.json")
                  }
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
                ForEach(this.subFolderList.sort((a, b) => a.localeCompare(b)), (folder: string, index) => {
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
                  .margin({ bottom: index !== this.subFolderList.length - 1 ? 10 : 0 })
                  .padding({ left: 20, right: 20 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(async () => {
                    this.audioFolderList = []
                    const entries = await fs.listFile(this.downloadPath + "/" + this.folderList[this.folderIdx] + "/" + folder);
                    for (let name of entries) {
                      const fullPath = `${this.downloadPath}/${this.folderList[this.folderIdx]}/${folder}/${name}`;
                      const stat = await fs.stat(fullPath);
                      if (stat.isFile() && this.isAudioFile(name)) {
                        this.audioFolderList.push(name);
                      }
                    }
                    this.subFolderIdx = index
                    this.folderDeep = 2
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
            } else {
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
                this.folderDeep = 1
              })

              if (this.audioFolderList.length > 0) {
                ForEach(this.audioFolderList.sort((a, b) => a.localeCompare(b)), (file: string, index) => {
                  Button({ type: ButtonType.Normal }) {
                    Row() {
                      Text(file)
                        .fontSize(20)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                  }
                  .width('100%')
                  .height(60)
                  .borderRadius(8)
                  .margin({ bottom: index !== this.audioFolderList.length - 1 ? 10 : 0 })
                  .padding({ left: 20, right: 20 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(async () => {

                  })
                })
              } else {
                Row() {
                  Text("没有文件")
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
          .padding({ left: 20, right: 20, bottom: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 69, bottom: this.isStartPlaying ? 109 : 25 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}