import { fileIo as fs } from '@kit.CoreFileKit';
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
  @Consumer() filesDir: string = ""
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isPlaying: boolean = false
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() playStartTime: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Local folderList: string[] = []
  @Local subFolderList: string[] = []
  @Local audioFolderList: string[] = []
  @Local folderDeep: number = 0
  @Local mediaType: string = ""
  @Local metadata: string | undefined = undefined
  @Local folderIdx: number = 0
  @Local subFolderIdx: number = 0
  private audioExts = ['mp3', 'flac', 'wav', 'aac', 'm4a', 'm4b', 'ogg'];

  isAudioFile(fileName: string): boolean {
    let ext = fileName.split('.').pop();
    if (!ext) {
      return false;
    }
    return this.audioExts.includes(ext.toLowerCase());
  }

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
          Column() {
            Text("本地目录")
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 15 })

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
                  if (folder === "有声书") {
                    this.mediaType = "book"
                  } else if (folder === "播客") {
                    this.mediaType = "podcast"
                  }
                  this.folderIdx = index
                  this.folderDeep = 1
                  this.metadata = undefined
                  if (fs.accessSync(this.filesDir + "/" + folder + "/metadata.json")) {
                    this.metadata = await fs.readText(this.filesDir + "/" + folder + "/metadata.json")
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
                    this.audioFolderList = []
                    const entries = await fs.listFile(this.filesDir + "/" + folder);
                    for (let name of entries) {
                      const fullPath = `${this.filesDir}/${name}`;
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
                ForEach(this.audioFolderList, (file: string, index) => {
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
                  .margin({ bottom: index !== this.folderList.length -1 ? 10 : 0 })
                  .padding({ left: 20, right: 20 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .onClick(async () => {
                    let duration = 0
                    let avMetadataExtractor: media.AVMetadataExtractor = await media.createAVMetadataExtractor();
                    let audio = await fs.open(this.filesDir + "/" + this.folderList[this.folderIdx] + "/" + this.subFolderList[this.subFolderIdx] + "/" + file)
                    avMetadataExtractor.fdSrc = {
                      fd: audio.fd
                    }
                    avMetadataExtractor.fetchMetadata((error, metadata) => {
                      if (error) {
                        console.error(`Failed to fetch Metadata, err = ${JSON.stringify(error)}`);
                        return;
                      }
                      duration = Number(metadata.duration)
                    });
                    avMetadataExtractor.release((error) => {

                    })
                    await this.avPlayer!.reset();
                    this.playingItem = {
                      id: "",
                      userId: "",
                      libraryId: "",
                      libraryItemId: "",
                      bookId: null,
                      episodeId: null,
                      mediaType: this.mediaType,
                      mediaMetadata: {
                        title: "",
                        titleIgnorePrefix: "",
                        subtitle: "",
                        author: JSON.parse(this.metadata??"").author??undefined,
                        authors: JSON.parse(this.metadata??"").authors??[],
                        genres: [],
                        description: "",
                        language: "",
                        explicit: false
                      },
                      chapters: [JSON.parse(this.metadata??"").chapter[index]]??[],
                      displayTitle: "",
                      displayAuthor: "",
                      coverPath: "",
                      duration: 0,
                      playMethod: 0,
                      mediaPlayer: "",
                      deviceInfo: {
                        id: "",
                        userId: "",
                        deviceName: "",
                        clientVersion: "",
                        clientName: "",
                      },
                      serverVersion: "",
                      date: "",
                      dayOfWeek: "",
                      timeListening: 0,
                      startTime: 0,
                      currentTime: 0,
                      startedAt: 0,
                      updatedAt: 0,
                      audioTracks: [{
                        index: 0,
                        startOffset: 0,
                        duration: duration,
                        title: file,
                        contentUrl: "",
                        mimeType: "",
                        codec: "",
                        metadata: {
                          filename: file,
                          ext: "",
                          path: "",
                          relPath: "",
                          size: 0,
                          mtimeMs: 0,
                          ctimeMs: 0,
                          birthtimeMs: 0
                        }
                      }],
                      videoTrack: null
                    }
                    this.isStartPlaying = true
                    this.isPlaying = true
                    this.playingIndex = index
                    this.playingTitle = file
                    this.playStartTime = 0
                    this.avPlayer!.fdSrc = {
                      fd: audio.fd,
                    }
                    fs.close(audio)
                    console.log("共", this.playingItem!.audioTracks.length, "条音轨")
                    console.log("播放序号为", this.playingIndex)
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
      .padding({ left: 20, right: 20, top: 72, bottom: this.isStartPlaying ? 109 : 25 })
      .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}