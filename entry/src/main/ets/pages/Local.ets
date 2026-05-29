import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { env } from '../utils/Class';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { PersistenceV2 } from '@kit.ArkUI';
import { ColorMode } from "../pages/Index";
import { LocalPlayItem, LocalTrack, PlayItem } from '../utils/Interface';
import { media } from '@kit.MediaKit';
import { Logger } from '../utils/Logger';

@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() showPlay: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() localPlayItem: LocalPlayItem | undefined = undefined
  @Consumer() isLocalPlaying: boolean = false
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
    try {
      const entries = await fs.listFile(this.downloadPath);
      for (let name of entries) {
        const fullPath = `${this.downloadPath}/${name}`;
        const stat = await fs.stat(fullPath);
        if (stat.isDirectory()) {
          this.folderList.push(name);
        }
      }
    } catch (_) {}
  }

  getCurrentAudioFolderPath(): string {
    return `${this.downloadPath}/${this.folderList[this.folderIdx]}/${this.subFolderList[this.subFolderIdx]}`
  }

  async findCoverInFolder(folderPath: string): Promise<string | undefined> {
    const candidates = ['cover.jpg', 'cover.jpeg', 'cover.png', 'cover.webp', 'folder.jpg']
    try {
      const entries = await fs.listFile(folderPath)
      for (let c of candidates) {
        if (entries.includes(c)) {
          return `${folderPath}/${c}`
        }
      }
    } catch (_) {}
    return undefined
  }

  async startLocalPlayback(clickIndex: number) {
    const folderPath = this.getCurrentAudioFolderPath()
    let tracks: LocalTrack[] = []
    for (let i = 0; i < this.audioFolderList.length; i++) {
      const name = this.audioFolderList[i]
      tracks.push({
        index: i,
        title: name,
        filePath: `${folderPath}/${name}`,
        duration: 0,
      })
    }
    let coverPath = await this.findCoverInFolder(folderPath)
    let localItem: LocalPlayItem = {
      id: folderPath,
      folderPath: folderPath,
      displayTitle: this.subFolderList[this.subFolderIdx],
      coverPath: coverPath,
      tracks: tracks,
    }
    this.localPlayItem = localItem
    this.isLocalPlaying = true
    this.playingItem = undefined
    this.playingIndex = clickIndex
    this.playingTitle = tracks[clickIndex].title
    this.playStartTime = 0
    this.isPlaying = true
    this.isStartPlaying = true
    this.showPlay = true
    try {
      await this.avPlayer!.reset()
      const file = fs.openSync(tracks[clickIndex].filePath, fs.OpenMode.READ_ONLY)
      this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
    } catch (_) {}
  }

  async deleteLocalFile(fileName: string) {
    const fullPath = `${this.getCurrentAudioFolderPath()}/${fileName}`
    try {
      await fs.unlink(fullPath)
      let idx = this.audioFolderList.indexOf(fileName)
      if (idx >= 0) {
        this.audioFolderList.splice(idx, 1)
      }
      this.getUIContext().getPromptAction().showToast({
        message: '已删除',
        duration: 500
      })
    } catch (err) {
      Logger.error(`删除失败${err}`)
      this.getUIContext().getPromptAction().showToast({
        message: '删除失败',
        duration: 500
      })
    }
  }

  async deleteSubFolder(folderName: string) {
    const folderPath = `${this.downloadPath}/${this.folderList[this.folderIdx]}/${folderName}`
    try {
      const entries = await fs.listFile(folderPath)
      for (let name of entries) {
        const fullPath = `${folderPath}/${name}`
        const stat = await fs.stat(fullPath)
        if (stat.isFile()) {
          await fs.unlink(fullPath)
        }
      }
      await fs.rmdir(folderPath)
      let idx = this.subFolderList.indexOf(folderName)
      if (idx >= 0) {
        this.subFolderList.splice(idx, 1)
      }
      this.getUIContext().getPromptAction().showToast({
        message: '已删除',
        duration: 500
      })
    } catch (err) {
      Logger.error(`删除失败${err}`)
      this.getUIContext().getPromptAction().showToast({
        message: '删除失败',
        duration: 500
      })
    }
  }

  @Builder
  deleteSubFolderButton(folderName: string) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash_fill'))
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.white')])
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .backgroundColor($r('sys.color.warning'))
    .onClick(() => {
      this.deleteSubFolder(folderName)
    })
  }

  @Builder
  deleteButton(fileName: string) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.trash_fill'))
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.white')])
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .backgroundColor($r('sys.color.warning'))
    .onClick(() => {
      this.deleteLocalFile(fileName)
    })
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Text("本地媒体")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 15, bottom: 15 })

          if (this.folderDeep === 0) {
            ForEach(this.folderList, (folder: string, index) => {
              Button({ type: ButtonType.Normal }) {
                Row() {
                  Text(folder)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(18)
                    .fontColor([$r('sys.color.font_secondary')])
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('100%')
              .height(50)
              .borderRadius(8)
              .margin({ bottom: index !== this.folderList.length - 1 ? 10 : 0 })
              .padding({ left: 20, right: 20 })
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onClick(async () => {
                try {
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
                } catch (_) {}
              })
            })
          } else if (this.folderDeep === 1) {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text("返回上一级")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(18)
                  .fontColor([$r('sys.color.font_secondary')])
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .height(50)
            .borderRadius(8)
            .margin({ bottom: 10 })
            .padding({ left: 20, right: 20 })
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .onClick(async () => {
              this.folderDeep = 0
            })

            if (this.subFolderList.length > 0) {
              List({ space: 6 }) {
                ForEach(this.subFolderList.sort((a, b) => a.localeCompare(b)), (folder: string, index) => {
                  ListItem() {
                    Row() {
                      Text(folder)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)

                      SymbolGlyph($r('sys.symbol.chevron_right'))
                        .fontSize(18)
                        .fontColor([$r('sys.color.font_secondary')])
                    }
                    .width('100%')
                    .height(50)
                    .padding({ left: 20, right: 20 })
                  }
                  .width('100%')
                  .height(50)
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.deleteSubFolderButton(folder)
                      }
                    }
                  })
                  .onClick(async () => {
                    try {
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
                    } catch (_) {}
                  })
                })
              }
              .width('100%')
              .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
              .scrollBar(BarState.Off)
            } else {
              Row() {
                Text("没有项目")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
              }
              .height(50)
              .borderRadius(8)
              .padding({ left: 20, right: 20 })
            }
          } else {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text("返回上一级")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(18)
                  .fontColor([$r('sys.color.font_secondary')])
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .height(50)
            .borderRadius(8)
            .margin({ bottom: 10 })
            .padding({ left: 20, right: 20 })
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .onClick(async () => {
              this.folderDeep = 1
            })

            if (this.audioFolderList.length > 0) {
              List({ space: 6 }) {
                ForEach(this.audioFolderList.sort((a, b) => a.localeCompare(b)), (file: string, index) => {
                  ListItem() {
                    Row() {
                      Text(file)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .height(50)
                    .padding({ left: 20, right: 20 })
                  }
                  .width('100%')
                  .height(50)
                  .borderRadius(8)
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.deleteButton(file)
                      }
                    }
                  })
                  .onClick(() => {
                    this.startLocalPlayback(index)
                  })
                })
              }
              .width('100%')
              .layoutWeight(1)
              .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
              .scrollBar(BarState.Off)
            } else {
              Row() {
                Text("没有文件")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
              }
              .height(50)
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
        .clip(true)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 69, bottom: this.isStartPlaying ? 104 : 25 })
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}