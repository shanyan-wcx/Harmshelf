import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { PersistenceV2 } from '@kit.ArkUI';
import { ColorMode } from "../pages/Index";
import { LocalPlayItem, LocalTrack, PlayItem } from '../utils/Interface';
import { media } from '@kit.MediaKit';
import { Logger } from '../utils/Logger';
import { getBottomContentInset } from '../utils/Layout';
import { ImmersiveActionButton } from '../utils/Component';

@ComponentV2
export struct LocalMedia {
  @Consumer() LocalMediaScroller: Scroller = new Scroller()
  @Consumer() pageIndex: number = 0
  @Consumer() statusBarHeight: number = 0
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

  private async listDirectories(path: string): Promise<string[]> {
    let directories: string[] = []
    try {
      const entries = await fs.listFile(path)
      for (let name of entries) {
        const stat = await fs.stat(`${path}/${name}`)
        if (stat.isDirectory()) {
          directories.push(name)
        }
      }
    } catch (_) {}
    return directories
  }

  private async listAudioFiles(path: string): Promise<string[]> {
    let files: string[] = []
    try {
      const entries = await fs.listFile(path)
      for (let name of entries) {
        const stat = await fs.stat(`${path}/${name}`)
        if (stat.isFile() && this.isAudioFile(name)) {
          files.push(name)
        }
      }
    } catch (_) {}
    return files
  }

  private async refreshCurrentLevel() {
    if (this.downloadPath === '') {
      return
    }
    if (this.folderDeep === 0) {
      this.folderList = await this.listDirectories(this.downloadPath)
      return
    }
    if (this.folderIdx >= this.folderList.length) {
      this.folderDeep = 0
      await this.refreshCurrentLevel()
      return
    }

    const folderPath = `${this.downloadPath}/${this.folderList[this.folderIdx]}`
    if (this.folderDeep === 1) {
      this.subFolderList = await this.listDirectories(folderPath)
      if (this.subFolderIdx >= this.subFolderList.length) {
        this.subFolderIdx = 0
      }
      return
    }
    if (this.subFolderIdx >= this.subFolderList.length) {
      this.folderDeep = 1
      await this.refreshCurrentLevel()
      return
    }

    this.audioFolderList = await this.listAudioFiles(
      `${folderPath}/${this.subFolderList[this.subFolderIdx]}`)
  }

  @Monitor('pageIndex')
  async refreshOnEnter(_: IMonitor) {
    if (this.pageIndex === 2) {
      await this.refreshCurrentLevel()
    }
  }

  @Monitor('downloadUri')
  async refreshDownloadPath(_: IMonitor) {
    if (this.downloadUri === '') {
      return
    }
    this.downloadPath = new fileUri.FileUri(this.downloadUri).path
    if (this.pageIndex === 2) {
      await this.refreshCurrentLevel()
    }
  }

  isAudioFile(fileName: string): boolean {
    let ext = fileName.split('.').pop();
    if (!ext) {
      return false;
    }
    return this.audioExts.includes(ext.toLowerCase());
  }

  async aboutToAppear() {
    this.downloadPath = new fileUri.FileUri(this.downloadUri).path
    await this.refreshCurrentLevel()
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
    Row() {
      ImmersiveActionButton({
        barWidth: 40,
        barHeight: 40,
        onButtonClick: () => {
          this.deleteSubFolder(folderName)
        }
      }) {
        SymbolGlyph($r('sys.symbol.trash_fill'))
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor([Color.Red])
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .clip(false)
  }

  @Builder
  deleteButton(fileName: string) {
    Row() {
      ImmersiveActionButton({
        barWidth: 40,
        barHeight: 40,
        onButtonClick: () => {
          this.deleteLocalFile(fileName)
        }
      }) {
        SymbolGlyph($r('sys.symbol.trash_fill'))
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor([Color.Red])
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(40)
    .height(40)
    .margin({ left: 10, right: 10 })
    .clip(false)
  }

  build() {
    Stack() {
      Scroll(this.LocalMediaScroller) {
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
                    .fontSize(16)
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
              .height(60)
              .borderRadius(18)
              .margin({ bottom: index !== this.folderList.length - 1 ? 12 : 0 })
              .padding({ left: 20, right: 20 })
              .backgroundColor($r('sys.color.background_secondary'))
              .border({
                width: 0.35,
                radius: 18,
                color: $r('sys.color.ohos_id_color_focused_outline_transparent')
              })
              .shadow(ShadowStyle.OUTER_DEFAULT_XS)
              .clip(false)
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
                  .fontSize(16)
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
            .height(60)
            .borderRadius(18)
            .margin({ bottom: 10 })
            .padding({ left: 20, right: 20 })
            .backgroundColor($r('sys.color.background_secondary'))
            .border({
              width: 0.35,
              radius: 18,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
            .onClick(async () => {
              this.folderDeep = 0
            })

            if (this.subFolderList.length > 0) {
              List({ space: 12 }) {
                Repeat<string>(this.subFolderList.sort((a, b) => a.localeCompare(b)))
                  .each((repeatItem: RepeatItem<string>) => {
                  ListItem() {
                    Stack() {
                      Stack() {
                        Row() {
                          Text(repeatItem.item)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)

                          SymbolGlyph($r('sys.symbol.chevron_right'))
                            .fontSize(18)
                            .fontColor([$r('sys.color.font_secondary')])
                        }
                        .width('100%')
                        .height(60)
                        .padding({ left: 20, right: 20 })
                      }
                      .width('100%')
                      .height(60)
                      .borderRadius(18)
                      .clip(true)
                    }
                    .width('100%')
                    .height(60)
                    .borderRadius(18)
                    .backgroundColor($r('sys.color.background_secondary'))
                    .border({
                      width: 0.35,
                      radius: 18,
                      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
                    })
                    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                    .clip(false)
                  }
                  .width('100%')
                  .height(60)
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.deleteSubFolderButton(repeatItem.item)
                      }
                    }
                  })
                  .clip(false)
                  .onClick(async () => {
                    try {
                      this.audioFolderList = []
                      const entries = await fs.listFile(this.downloadPath + "/" + this.folderList[this.folderIdx] + "/" + repeatItem.item);
                      for (let name of entries) {
                        const fullPath = `${this.downloadPath}/${this.folderList[this.folderIdx]}/${repeatItem.item}/${name}`;
                        const stat = await fs.stat(fullPath);
                        if (stat.isFile() && this.isAudioFile(name)) {
                          this.audioFolderList.push(name);
                        }
                      }
                      this.subFolderIdx = repeatItem.index
                      this.folderDeep = 2
                    } catch (_) {}
                  })
                  })
                  .virtualScroll({ totalCount: this.subFolderList.length })
                  .key((item: string) => item)
              }
              .cachedCount(2)
              .width('100%')
              .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
              .scrollBar(BarState.Off)
              .enableScrollInteraction(false)
              .clip(false)
            } else {
              Row() {
                Text("没有项目")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
              }
              .height(50)
              .borderRadius(18)
              .padding({ left: 20, right: 20 })
            }
          } else {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text("返回上一级")
                  .fontSize(16)
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
            .height(60)
            .borderRadius(18)
            .margin({ bottom: 10 })
            .padding({ left: 20, right: 20 })
            .backgroundColor($r('sys.color.background_secondary'))
            .border({
              width: 0.35,
              radius: 18,
              color: $r('sys.color.ohos_id_color_focused_outline_transparent')
            })
            .shadow(ShadowStyle.OUTER_DEFAULT_XS)
            .clip(false)
            .onClick(async () => {
              this.folderDeep = 1
            })

            if (this.audioFolderList.length > 0) {
              List({ space: 12 }) {
                Repeat<string>(this.audioFolderList.sort((a, b) => a.localeCompare(b)))
                  .each((repeatItem: RepeatItem<string>) => {
                  ListItem() {
                    Stack() {
                      Stack() {
                        Row() {
                          Text(repeatItem.item)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                        }
                        .width('100%')
                        .height(60)
                        .padding({ left: 20, right: 20 })
                      }
                      .width('100%')
                      .height(60)
                      .borderRadius(18)
                      .clip(true)
                    }
                    .width('100%')
                    .height(60)
                    .borderRadius(18)
                    .backgroundColor($r('sys.color.background_secondary'))
                    .border({
                      width: 0.35,
                      radius: 18,
                      color: $r('sys.color.ohos_id_color_focused_outline_transparent')
                    })
                    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                    .clip(false)
                  }
                  .width('100%')
                  .height(60)
                  .swipeAction({
                    end: {
                      builder: () => {
                        this.deleteButton(repeatItem.item)
                      }
                    }
                  })
                  .clip(false)
                  .onClick(() => {
                    this.startLocalPlayback(repeatItem.index)
                  })
                  })
                  .virtualScroll({ totalCount: this.audioFolderList.length })
                  .key((item: string) => item)
              }
              .cachedCount(2)
              .width('100%')
              .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
              .scrollBar(BarState.Off)
              .enableScrollInteraction(false)
              .clip(false)
            } else {
              Row() {
                Text("没有文件")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
              }
              .height(50)
              .borderRadius(18)
              .padding({ left: 20, right: 20 })
            }
          }
        }
        .width('100%')
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius(18)
        .padding({ left: 20, right: 20, bottom: 20 })
        .border({
          width: 0.35,
          radius: 18,
          color: $r('sys.color.ohos_id_color_focused_outline_transparent')
        })
        .shadow(ShadowStyle.OUTER_DEFAULT_XS)
        .clip(true)
      }
        .width('100%')
        .padding({ left: 20, right: 20, top: this.statusBarHeight + 69, bottom: getBottomContentInset(25, this.isStartPlaying, 104) })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
