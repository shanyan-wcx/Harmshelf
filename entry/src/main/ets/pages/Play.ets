import { HdsBarStyle, HdsListItem } from '@kit.UIDesignKit'
import { Bookmark, Chapter, LibraryItem, LocalPlayItem, LocalTrack, PlayItem, User } from '../utils/Interface'
import { ColorMetrics, CircleShape, LengthMetrics, PersistenceV2, SymbolGlyphModifier, TextModifier, uiMaterial, window } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { createBookmark, deleteBookmark, getBookmarks, getItem, getLibraryItems, getSeries } from '../utils/Api';
import { PlaySetting } from './Index';
import { media } from '@kit.MediaKit';
import { Logger } from '../utils/Logger';
import { setColorModeUpdateCallback } from '../utils/Class';
import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { rcp } from '@kit.RemoteCommunicationKit';
import { ImmersiveActionButton, MiniBarState } from '../utils/Component';
import {
  MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN,
  MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT
} from '../utils/Layout';

interface PlayColorPalette {
  primary: string
  secondary: string
  sliderBlock: string
  sliderTrack: string
}

interface RecommendationCandidate {
  item: LibraryItem
  score: number
  sameSeries: boolean
  seriesOrder: number
}

@ComponentV2
export struct PlaybackMiniBar {
  @Param forceExpanded: boolean = false
  @Param isStandalone: boolean = false
  @Param miniBarState: MiniBarState = new MiniBarState()
  @Consumer() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Consumer() isPlaying: boolean = false
  @Consumer() showPlay: boolean = false
  @Consumer() preparePlayColor: (() => Promise<void>) | undefined = undefined
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() localPlayItem: LocalPlayItem | undefined = undefined
  @Consumer() isLocalPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Consumer() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Consumer() playStartTime: number = 0
  @Consumer() playedTime: number = 0
  @Consumer() playedPercent: number = 0
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Local fadeInterval: number = -1

  private isExpanded(): boolean {
    return this.forceExpanded || this.miniBarState.expanded
  }

  private canOpenPlayer(): boolean {
    const isExpanding = this.miniBarState.animating &&
      this.miniBarState.targetStyle === HdsBarStyle.EXPAND
    return this.isExpanded() && (!this.miniBarState.animating || isExpanding) && !this.showPlay
  }

  private getCoverSource(): string | Resource {
    if (this.isLocalPlaying) {
      const coverPath = this.localPlayItem?.coverPath ?? ''
      return coverPath ? fileUri.getUriFromPath(coverPath) : $rawfile('nocover.jpg')
    }
    if (!this.baseUrl || !this.playingItem?.libraryItemId) {
      return $rawfile('nocover.jpg')
    }
    return this.baseUrl + `/api/items/${this.playingItem.libraryItemId}/cover?token=${this.apiToken}`
  }

  private getPlaybackSubtitle(): string {
    if (this.isLocalPlaying) {
      return '本地文件'
    }
    if (this.playingItem?.mediaType === 'book') {
      return this.playingItem.mediaMetadata.authors?.map(item => item.name).join(', ') ?? '-'
    }
    return this.playingItem?.displayAuthor ?? '-'
  }

  private getCurrentDuration(): number {
    if (this.isLocalPlaying) {
      return this.localPlayItem?.tracks[this.playingIndex]?.duration ?? 0
    }
    return this.playingItem?.audioTracks[this.playingIndex]?.duration ?? 0
  }

  private isSeekable(): boolean {
    return this.avPlayer !== undefined &&
      ['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer.state)
  }

  private seekBackward() {
    if (!this.isSeekable()) {
      return
    }
    const skipIntervals = this.playSetting?.skipIntervals ?? 10
    this.avPlayer!.seek(this.playedTime - skipIntervals > 0 ?
      (this.playedTime - skipIntervals) * 1000 : 0)
  }

  private seekForward() {
    if (!this.isSeekable()) {
      return
    }
    const skipIntervals = this.playSetting?.skipIntervals ?? 10
    const duration = this.getCurrentDuration()
    this.avPlayer!.seek(this.playedTime + skipIntervals < duration ?
      (this.playedTime + skipIntervals) * 1000 : duration * 1000)
  }

  private fadeIn() {
    if (this.avPlayer === undefined) {
      return
    }
    this.isPlaying = true
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let volume = 0
    const step = 50
    const increment = step / 1000
    this.avPlayer.setVolume(volume)
    this.avPlayer.play()
    const interval = setInterval(() => {
      volume += increment
      if (volume >= 1.0) {
        this.avPlayer!.setVolume(1.0)
        clearInterval(interval)
        this.fadeInterval = -1
      } else {
        this.avPlayer!.setVolume(volume)
      }
    }, step)
    this.fadeInterval = interval
  }

  private fadeOut() {
    if (this.avPlayer === undefined) {
      return
    }
    this.isPlaying = false
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let volume = 1.0
    const step = 50
    const decrement = step / 1000
    const interval = setInterval(() => {
      volume -= decrement
      if (volume <= 0.0) {
        this.avPlayer!.setVolume(0.0)
        clearInterval(interval)
        this.fadeInterval = -1
        this.avPlayer!.pause()
      } else {
        this.avPlayer!.setVolume(volume)
      }
    }, step)
    this.fadeInterval = interval
  }

  private async togglePlayback() {
    if (this.avPlayer === undefined) {
      return
    }
    if (this.isPlaying) {
      if (this.avPlayer.state === 'playing') {
        if (this.playSetting?.fadeInOut) {
          this.fadeOut()
        } else {
          this.avPlayer.pause()
        }
      }
      return
    }
    if (this.avPlayer.state === 'error') {
      this.isPlaying = true
      const savedPosition = this.playedTime
      await this.avPlayer.reset()
      this.playStartTime = savedPosition
      if (this.isLocalPlaying) {
        const file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
        this.avPlayer.fdSrc = { fd: file.fd, offset: 0, length: -1 }
      } else if (this.playingItem) {
        this.avPlayer.url = this.baseUrl + this.playingItem.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
      }
      this.avPlayer.prepare()
    } else if (['paused', 'completed'].includes(this.avPlayer.state)) {
      if (this.playSetting?.fadeInOut) {
        this.fadeIn()
      } else {
        this.avPlayer.play()
      }
    }
  }

  private async openPlayer() {
    if (!this.canOpenPlayer()) {
      return
    }
    if (this.preparePlayColor) {
      await this.preparePlayColor()
    }
    if (!this.canOpenPlayer()) {
      return
    }
    this.showPlay = true
  }

  @Builder
  coverBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.getCoverSource())
        .alt($rawfile('nocover.jpg'))
        .objectFit(ImageFit.Cover)
        .width(this.isExpanded() ? 40 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT - 4)
        .height(this.isExpanded() ? 40 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT - 4)
        .draggable(false)
        .clipShape(new CircleShape({ width: '100%', height: '100%' }))
        .borderRadius(this.isExpanded() ? 20 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT / 2 - 2)
        .clip(true)
        .transition(TransitionEffect.IDENTITY)

      Progress({ value: 100, total: 100, type: ProgressType.Ring })
        .width(this.isExpanded() ? 44 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
        .height(this.isExpanded() ? 44 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
        .color($r('sys.color.comp_background_secondary'))
        .style({
          strokeWidth: 2,
          enableSmoothEffect: false
        })

      Progress({ value: this.playedPercent, total: 100, type: ProgressType.Ring })
        .width(this.isExpanded() ? 44 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
        .height(this.isExpanded() ? 44 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
        .color($r('sys.color.comp_emphasize_secondary'))
        .style({
          strokeWidth: 2,
          enableSmoothEffect: true
        })
    }
    .width(this.isExpanded() ? 48 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
    .height(this.isExpanded() ? 48 : MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
    .margin({ left: this.isExpanded() ? 4 : 0, right: this.isExpanded() ? 4 : 0 })
    .clip(false)
    // Let HdsTabs receive collapsed-bar clicks; the cover only owns clicks once expanded.
    .hitTestBehavior(this.canOpenPlayer() ? HitTestMode.Default : HitTestMode.None)
    .onClick(() => {
      if (this.canOpenPlayer()) {
        this.openPlayer()
      }
    })
  }

  @Builder
  rewindButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(this.gobackwardIcon)
        .fontSize(26)
        .fontColor([$r('sys.color.font_secondary')])
    }
    .width(40)
    .height(40)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.seekBackward()
    })
  }

  @Builder
  playPauseButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
        .fontSize(26)
        .fontColor([$r('sys.color.font_secondary')])
    }
    .width(40)
    .height(40)
    .backgroundColor(Color.Transparent)
    .onClick(async () => {
      await this.togglePlayback()
    })
  }

  @Builder
  forwardButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(this.goforwardIcon)
        .fontSize(26)
        .fontColor([$r('sys.color.font_secondary')])
    }
    .width(40)
    .height(40)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.seekForward()
    })
  }

  @Builder
  barBuilder() {
    Row() {
      this.coverBuilder()

      if (this.isExpanded()) {
        Column() {
          Text(this.playingTitle || '-')
            .width('100%')
            .fontSize(14)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .marqueeOptions({ start: true, loop: -1, delay: 3000, step: 4, fadeout: true })

          Text(this.getPlaybackSubtitle())
            .width('100%')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .marqueeOptions({ start: true, loop: -1, delay: 3000, step: 4, fadeout: true })
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .margin({ right: 4 })
        .clip(false)
        .onClick(() => {
          if (this.canOpenPlayer()) {
            this.openPlayer()
          }
        })

        Row({ space: 0 }) {
          this.rewindButton()
          this.playPauseButton()
          this.forwardButton()
        }
        .margin({ right: 8 })
        .clip(false)
        .onTouch((event: TouchEvent) => {
          event.stopPropagation()
        })
      }
    }
    .height('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(this.isExpanded() ? FlexAlign.Start : FlexAlign.Center)
    .geometryTransition("miniBar")
    .id('miniBarRoot')
    .width(this.isExpanded() && this.isStandalone ? 'calc(100% + 22vp)' : '100%')
    .margin({ right: this.isExpanded() ? (this.isStandalone ? 0 : -8) : 0 })
    .clip(false)
    .hitTestBehavior(this.canOpenPlayer() ? HitTestMode.Default : HitTestMode.None)
    .onClick(() => {
      if (this.canOpenPlayer()) {
        this.openPlayer()
      }
    })
  }

  aboutToDisappear() {
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
  }

  build() {
    this.barBuilder()
  }
}

@ComponentV2
export struct Play {
  private chapterScroller: Scroller = new Scroller();
  private recommendationScroller: Scroller = new Scroller();
  @Env(SystemProperties.WINDOW_AVOID_AREA)
  windowAvoidArea: window.UIEnvWindowAvoidAreaInfoVP
  @Consumer() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Consumer() displayWidth: number = 0
  @Consumer() displayHeight: number = 0
  @Consumer() pageInfos: NavPathStack = new NavPathStack()
  @Consumer() libraryItem: LibraryItem | undefined = undefined
  @Consumer() isPlaying: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Consumer() isIndex: boolean = true
  @Consumer() showPlay: boolean = false
  @Consumer() preparePlayColor: (() => Promise<void>) | undefined = undefined
  @Consumer() playingItem: PlayItem | undefined = undefined
  @Consumer() localPlayItem: LocalPlayItem | undefined = undefined
  @Consumer() isLocalPlaying: boolean = false
  @Consumer() baseUrl: string = ""
  @Consumer() apiToken: string = ""
  @Consumer() playingTitle: string = "-"
  @Consumer() playingIndex: number = 0
  @Consumer() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Consumer() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Consumer() bookmarks: Bookmark[] = []
  @Consumer() user: User | undefined = undefined
  @Consumer() playStartTime: number = 0
  @Consumer() playedTime: number = 0
  @Consumer() playedPercent: number = 0
  @Consumer() currentTrackDuration: number = 0
  @Consumer() sleepTime: number = 0
  @Consumer() sliderMoving: boolean = false
  @Consumer() avPlayer: media.AVPlayer | undefined = undefined
  @Consumer() speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @Local sliderValue: number = 0
  @Local fadeInterval: number = -1
  @Local coverColor: number = 0xff181818
  @Local isFloatingWindow: boolean = false
  @Local colorModeRevision: number = 0
  private colorModeUpdateTimeout: number = -1
  private coverColorRequest: number = 0
  private coverColorLifecycle: number = 0
  private coverColorActive: boolean = false
  private coverColorSession: rcp.Session | undefined = undefined
  private coverColorPromise: Promise<void> | undefined = undefined
  private coverColorPromiseKey: string = ''
  private coverColorPromiseLifecycle: number = -1
  private coverColorReadyKey: string = ''
  private coverColorResolvedKey: string = ''
  private coverColorResolvedLifecycle: number = -1
  private hasSuccessfulCoverColor: boolean = false
  private previousStatusBarContentColor: string = ''
  private playbackWindow: window.Window | undefined = undefined
  private windowStatusCallback: (status: window.WindowStatusType) => void = (status: window.WindowStatusType) => {
    this.isFloatingWindow = status === window.WindowStatusType.FLOATING
  }
  private colorModeUpdateCallback: () => void = () => {
    this.colorModeRevision++
    if (this.colorModeUpdateTimeout !== -1) {
      clearTimeout(this.colorModeUpdateTimeout)
      this.colorModeUpdateTimeout = -1
    }
    if (this.showPlay) {
      this.colorModeUpdateTimeout = setTimeout(() => {
        this.colorModeUpdateTimeout = -1
        if (this.showPlay) {
          this.updateStatusBarContentColor()
        }
      }, 200)
    }
  }

  private get playControlColor(): Color {
    const red = (this.coverColor >>> 16) & 0xff
    const green = (this.coverColor >>> 8) & 0xff
    const blue = this.coverColor & 0xff
    return red * 0.299 + green * 0.587 + blue * 0.114 > 160 ? Color.Black : Color.White
  }

  private get playColorPalette(): PlayColorPalette {
    return this.playControlColor === Color.Black ? {
      primary: '#182431',
      secondary: '#99182431',
      sliderBlock: '#3A3A3B',
      sliderTrack: '#19182431'
    } : {
      primary: '#FFFFFF',
      secondary: '#99FFFFFF',
      sliderBlock: '#BCBCBC',
      sliderTrack: '#19FFFFFF'
    }
  }

  private get playbackCoverHeight(): number {
    return this.displayWidth >= 1000 ? this.displayWidth / 2 : this.displayWidth
  }

  private get shouldOverlayPlaybackControls(): boolean {
    return this.displayHeight > 0 && this.playbackCoverHeight >= this.displayHeight * 2 / 3
  }

  private get playbackControlsHeight(): number {
    return this.shouldOverlayPlaybackControls ? this.displayHeight / 3 :
      Math.max(0, this.displayHeight - this.playbackCoverHeight)
  }

  private get playbackGradientBottomOffset(): number {
    return this.shouldOverlayPlaybackControls ?
      Math.max(0, this.playbackCoverHeight - this.displayHeight * 2 / 3) : 0
  }

  private get shouldAddPlaybackBottomInset(): boolean {
    return deviceInfo.deviceType === '2in1' ||
      this.isFloatingWindow
  }

  @Builder
  playbackSheetTitleBuilder(title: string) {
    Text(title)
      .width('100%')
      .fontSize($r('sys.float.ohos_id_text_size_headline8'))
      .fontWeight(FontWeight.Medium)
      .fontColor(this.playColorPalette.primary)
      .textAlign(TextAlign.Start)
  }

  private playbackSheetSymbol(resource: Resource, color: string): SymbolGlyphModifier {
    const modifier = new SymbolGlyphModifier(resource)
    modifier.fontColor([color])
    return modifier
  }

  private async updateStatusBarContentColor() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      await mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: this.playControlColor === Color.Black ? '#000000' : '#FFFFFF'
      })
    } catch (_) {
    }
  }

  private async restoreStatusBarContentColor() {
    if (!this.previousStatusBarContentColor) {
      return
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      await mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: this.previousStatusBarContentColor
      })
    } catch (_) {
    }
  }

  async aboutToAppear() {
    this.coverColorActive = true
    this.coverColorLifecycle++
    this.preparePlayColor = async () => {
      await this.refreshCoverColor()
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const mainWindow = await window.getLastWindow(context)
      AppStorage.set<boolean>('playStatusBarOverride', this.showPlay)
      setColorModeUpdateCallback(this.colorModeUpdateCallback)
      this.playbackWindow = mainWindow
      this.isFloatingWindow = mainWindow.getWindowStatus() === window.WindowStatusType.FLOATING
      mainWindow.on('windowStatusDidChange', this.windowStatusCallback)
      this.previousStatusBarContentColor = mainWindow.getWindowSystemBarProperties().statusBarContentColor ?? ''
      if (this.showPlay) {
        await this.updateStatusBarContentColor()
      }
      if (this.playingItem?.libraryId) {
        await Promise.all([
          this.refreshCoverColor(true),
          this.loadRecommendations()
        ])
      }
    } catch (_) {
    }
  }

  aboutToDisappear() {
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    this.coverColorActive = false
    this.coverColorLifecycle++
    this.invalidateCoverColorRequest()
    this.preparePlayColor = undefined
    AppStorage.set<boolean>('playStatusBarOverride', false)
    setColorModeUpdateCallback(undefined)
    if (this.colorModeUpdateTimeout !== -1) {
      clearTimeout(this.colorModeUpdateTimeout)
      this.colorModeUpdateTimeout = -1
    }
    if (this.playbackWindow) {
      this.playbackWindow.off('windowStatusDidChange', this.windowStatusCallback)
      this.playbackWindow = undefined
    }
    this.restoreStatusBarContentColor()
  }
  @Local shouldClosePlayer: boolean = false
  @Local lockPlayer: boolean = false
  @Local showProgress: boolean = false
  @Local showBookmark: boolean = false
  @Local showSpeed: boolean = false
  @Local showSleep: boolean = false
  @Local showChapter: boolean = false
  @Local speedIcon: Resource = $r('sys.symbol.speed_100percent')
  @Local tmpBookmarkTitle: string = ""
  @Local tmpBookmarkTime: number = 0
  @Local showEditBookmark: boolean = false
  @Local editBookmarkIndex: number = 0
  @Local selectedSleepOption: number = 0
  @Local maxIntroLine: number = 5
  @Local showMoreIntro: boolean = false
  @Local recommendationItems: LibraryItem[] = []
  @Local recommendationLoading: boolean = false
  @Local recommendationLoadedItemId: string = ''
  @Local recommendationToOpen: LibraryItem | undefined = undefined
  private recommendationRequestId: number = 0
  private recommendationLoadingItemId: string = ''
  @Monitor('playingItem')
  async setSpeed(_: IMonitor) {
    this.sleepTime = 0
    if (this.playSetting?.rememberSpeed === true) {
      this.speed = this.playSetting.globalSpeed
    } else {
      this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
    }
  }

  @Monitor('sleepTime')
  syncSelectedSleepOption(_: IMonitor) {
    if (this.sleepTime === 0) {
      this.selectedSleepOption = 0
    }
  }
  @Monitor('playingItem')
  async refreshPlayingCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('localPlayItem')
  async refreshLocalCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('isLocalPlaying')
  async refreshLocalModeCoverColor(_: IMonitor) {
    await this.refreshCoverColor()
  }
  @Monitor('showPlay')
  async refreshShownCoverColor(_: IMonitor) {
    AppStorage.set<boolean>('playStatusBarOverride', this.showPlay)
    if (this.showPlay) {
      await this.refreshCoverColor()
      this.changeSpeedIcon()
      await this.updateStatusBarContentColor()
    } else {
      await this.restoreStatusBarContentColor()
    }
  }

  @Monitor('playingItem')
  async refreshPlayingRecommendations(_: IMonitor) {
    await this.loadRecommendations()
  }

  private normalizeRecommendationText(value: string): string {
    return value.toLowerCase().replace(/\s/g, '')
  }

  private recommendationTerms(value: string): string[] {
    return value.toLowerCase().split(/[\s,_\-·/|，、;；:：]+/).filter(term => term.length > 0)
  }

  private recommendationTopicGroup(value: string): number {
    const normalized = this.normalizeRecommendationText(value)
    const groups: string[][] = [
      ['游戏', '网游', '网络游戏', '手游', '手机游戏', '端游', '电脑游戏', '电子游戏', '主机游戏', '单机游戏']
    ]
    for (let index = 0; index < groups.length; index++) {
      if (groups[index].some(term => normalized.includes(term))) {
        return index
      }
    }
    return -1
  }

  private recommendationTextScore(left: string, right: string): number {
    const first = this.normalizeRecommendationText(left)
    const second = this.normalizeRecommendationText(right)
    if (!first || !second) {
      return 0
    }
    if (first === second) {
      return 1
    }
    if (first.includes(second) || second.includes(first)) {
      return 0.7
    }
    const firstTopic = this.recommendationTopicGroup(first)
    const secondTopic = this.recommendationTopicGroup(second)
    if (firstTopic >= 0 && firstTopic === secondTopic) {
      return 0.45
    }
    const firstTerms = this.recommendationTerms(left)
    const secondTerms = this.recommendationTerms(right)
    return firstTerms.some(term => secondTerms.includes(term)) ? 0.45 : 0
  }

  private recommendationListScore(left: string[], right: string[]): number {
    if (left.length === 0 || right.length === 0) {
      return 0
    }
    let score = 0
    for (const leftValue of left) {
      let best = 0
      for (const rightValue of right) {
        best = Math.max(best, this.recommendationTextScore(leftValue, rightValue))
      }
      score += best
    }
    return Math.min(1, score / Math.max(left.length, right.length))
  }

  private recommendationAuthors(item: LibraryItem): string[] {
    const authors: string[] = []
    item.media.metadata.authors?.forEach(author => {
      if (author.name && !authors.includes(author.name)) {
        authors.push(author.name)
      }
    })
    const authorNames = [item.media.metadata.authorName, item.media.metadata.author]
    authorNames.forEach(author => {
      if (author && !authors.includes(author)) {
        authors.push(author)
      }
    })
    return authors
  }

  private async recommendationSeriesOrder(libraryId: string): Promise<Map<string, number>> {
    const orders = new Map<string, number>()
    const series = await getSeries(libraryId)
    series.forEach(seriesItem => {
      seriesItem.books?.forEach(book => {
        if (book.sequence !== '') {
          const sequence = Number(book.sequence)
          if (!isNaN(sequence)) {
            orders.set(book.id, sequence)
          }
        }
      })
    })
    return orders
  }

  private async loadRecommendations(): Promise<void> {
    const libraryItemId = this.playingItem?.libraryItemId ?? ''
    if (!this.playingItem?.libraryId || !libraryItemId) {
      this.recommendationRequestId++
      this.recommendationItems = []
      this.recommendationLoadedItemId = ''
      this.recommendationLoadingItemId = ''
      this.recommendationLoading = false
      return
    }
    if (libraryItemId === this.recommendationLoadedItemId ||
      (this.recommendationLoading && libraryItemId === this.recommendationLoadingItemId)) {
      return
    }
    const requestId = ++this.recommendationRequestId
    this.recommendationItems = []
    this.recommendationLoadedItemId = ''

    this.recommendationLoading = true
    this.recommendationLoadingItemId = libraryItemId
    const libraryId = this.playingItem.libraryId
    try {
      const items = await getLibraryItems(libraryId)
      if (requestId !== this.recommendationRequestId) {
        return
      }
      const currentItem = items.find(item => item.id === this.playingItem?.libraryItemId) ?? this.playingItem.libraryItem
      if (!currentItem) {
        return
      }

      const currentTitle = currentItem.media.metadata.title ?? ''
      const currentSeries = currentItem.media.metadata.seriesName ?? ''
      const currentAuthors = this.recommendationAuthors(currentItem)
      const currentTopics = (currentItem.media.metadata.genres ?? []).concat(currentItem.media.tags ?? [])
      const seriesOrders = currentSeries ? await this.recommendationSeriesOrder(libraryId) : new Map<string, number>()
      const candidates: RecommendationCandidate[] = []

      items.forEach(item => {
        if (item.id === currentItem.id || item.libraryId !== libraryId || item.mediaType !== currentItem.mediaType) {
          return
        }
        const itemTitle = item.media.metadata.title ?? ''
        const itemSeries = item.media.metadata.seriesName ?? ''
        const itemAuthors = this.recommendationAuthors(item)
        const itemTopics = (item.media.metadata.genres ?? []).concat(item.media.tags ?? [])
        let weightedScore = 0
        let availableWeight = 0
        if (currentSeries && itemSeries) {
          weightedScore += 0.45 * this.recommendationTextScore(currentSeries, itemSeries)
          availableWeight += 0.45
        }
        if (currentAuthors.length > 0 && itemAuthors.length > 0) {
          weightedScore += 0.3 * this.recommendationListScore(currentAuthors, itemAuthors)
          availableWeight += 0.3
        }
        if (currentTopics.length > 0 && itemTopics.length > 0) {
          weightedScore += 0.25 * this.recommendationListScore(currentTopics, itemTopics)
          availableWeight += 0.25
        }
        if (currentTitle && itemTitle) {
          weightedScore += 0.15 * this.recommendationTextScore(currentTitle, itemTitle)
          availableWeight += 0.15
        }
        const score = availableWeight > 0 ? weightedScore / availableWeight : 0
        const hasTopicMatch = currentTopics.some(leftValue =>
          itemTopics.some(rightValue => this.recommendationTextScore(leftValue, rightValue) >= 0.45))
        const hasTitleMatch = currentTitle !== '' && itemTitle !== '' &&
          this.recommendationTextScore(currentTitle, itemTitle) >= 0.45
        const effectiveScore = hasTopicMatch || hasTitleMatch ? Math.max(score, 0.2) : score
        if (effectiveScore >= 0.2) {
          candidates.push({
            item: item,
            score: effectiveScore,
            sameSeries: currentSeries !== '' && this.recommendationTextScore(currentSeries, itemSeries) === 1,
            seriesOrder: seriesOrders.get(item.id) ?? Number.MAX_VALUE
          })
        }
      })

      candidates.sort((left, right) => {
        if (left.sameSeries !== right.sameSeries) {
          return left.sameSeries ? -1 : 1
        }
        if (left.sameSeries && left.seriesOrder !== right.seriesOrder) {
          return left.seriesOrder - right.seriesOrder
        }
        return right.score - left.score
      })
      const selectedItems = candidates.slice(0, 12).map(candidate => candidate.item)
      const detailedItems: LibraryItem[] = []
      for (const item of selectedItems) {
        detailedItems.push(await getItem(item.id) ?? item)
      }
      if (requestId !== this.recommendationRequestId) {
        return
      }
      this.recommendationItems = detailedItems
    } finally {
      if (requestId === this.recommendationRequestId) {
        this.recommendationLoading = false
        this.recommendationLoadedItemId = libraryItemId
        this.recommendationLoadingItemId = ''
      }
    }
  }

  private openRecommendation(item: LibraryItem) {
    this.pageInfos.clear()
    this.recommendationToOpen = item
    this.showPlay = false
  }

  private recommendationAuthorText(item: LibraryItem): string {
    const authors = this.recommendationAuthors(item)
    return authors.length > 0 ? authors.join(', ') : (item.mediaType === 'book' ? '有声书' : '播客')
  }

  private isRecommendationPending(): boolean {
    const libraryItemId = this.playingItem?.libraryItemId ?? ''
    return libraryItemId !== '' && libraryItemId !== this.recommendationLoadedItemId
  }

  private get recommendationCardBorder(): string {
    return this.playControlColor === Color.Black ?
      ColorMetrics.rgba(255, 255, 255, 0.24).color :
      ColorMetrics.rgba(0, 0, 0, 0.18).color
  }

  private get recommendationCardBackground(): string {
    return this.playControlColor === Color.Black ? '#33182431' : '#33FFFFFF'
  }

  @Builder
  recommendationCard(item: LibraryItem) {
    Row() {
      Image(this.baseUrl + `/api/items/${item.id}/cover?token=${this.apiToken}`)
        .alt($rawfile('nocover.jpg'))
        .objectFit(ImageFit.Cover)
        .width(72)
        .height(72)
        .borderRadius(10)
        .clip(true)
        .draggable(false)

      Column() {
        Text(item.media.metadata.title || '-')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.playColorPalette.primary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 3 })

        Text(this.recommendationAuthorText(item))
          .fontSize(13)
          .fontColor(this.playColorPalette.secondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ bottom: 5 })

        Text(item.mediaType === 'book' ?
          ((item.media.chapters?.length ?? 0) + ' 章节') :
          ((item.media.episodes?.length ?? 0) + ' 剧集'))
          .fontSize(13)
          .fontColor(this.playColorPalette.secondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(88)
    .padding(8)
    .borderRadius(18)
    .backgroundColor(this.recommendationCardBackground)
    .border({
      width: 0.35,
      radius: 18,
      color: this.recommendationCardBorder
    })
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .clip(false)
  }

  @Builder
  recommendationsBuilder() {
    Column() {
      if (this.recommendationLoading || this.isRecommendationPending() || this.recommendationItems.length === 0) {
        Stack({ alignContent: Alignment.Center }) {
          Text('相关推荐')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.playColorPalette.primary)
            .height(28)
            .textAlign(TextAlign.Start)
            .position({ top: 0, left: 20 })

          LoadingProgress()
            .visibility(this.recommendationLoading || this.isRecommendationPending() ? Visibility.Visible : Visibility.None)
            .width(36)
            .height(36)
            .color(this.playColorPalette.primary)

          Text('暂时没有相似内容')
            .visibility(this.recommendationLoading || this.isRecommendationPending() ? Visibility.None : Visibility.Visible)
            .fontSize(18)
            .fontColor(this.playColorPalette.secondary)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List({ scroller: this.recommendationScroller }) {
          ListItem() {
            Text('相关推荐')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.playColorPalette.primary)
              .height(28)
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 12 })
          .clip(false)

          Repeat<LibraryItem>(this.recommendationItems)
            .each((repeatItem: RepeatItem<LibraryItem>) => {
              ListItem() {
                Row() {
                  this.recommendationCard(repeatItem.item)
                }
                .width('100%')
                .height(88)
                .clip(false)
                .hitTestBehavior(HitTestMode.Transparent)
                .onTouchIntercept(() => HitTestMode.Transparent)
                .onClick(() => {
                  this.openRecommendation(repeatItem.item)
                })
              }
              .width('100%')
              .height(88)
              .padding({ left: 20, right: 20 })
              .margin({ bottom: 12 })
              .clip(false)
            })
            .virtualScroll({ totalCount: this.recommendationItems.length })
            .key((item: LibraryItem) => item.id)
        }
        .cachedCount(2)
        .width('100%')
        .height('100%')
        .clip(false)
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(24) })
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      top: (this.windowAvoidArea.statusBar.visible ? this.windowAvoidArea.statusBar.topRect.height : 0) + 12,
      bottom: (this.windowAvoidArea.navigationIndicator.visible ?
        this.windowAvoidArea.navigationIndicator.bottomRect.height : 0) +
        (this.shouldAddPlaybackBottomInset ? 20 : 0)
    })
    .backgroundColor(this.coverColor)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .clip(false)
  }

  private getCoverSource(): string {
    if (this.isLocalPlaying) {
      const coverPath = this.localPlayItem?.coverPath ?? ''
      try {
        return coverPath && fs.accessSync(coverPath) ? fileUri.getUriFromPath(coverPath) : ''
      } catch (_) {
        return ''
      }
    }
    if (!this.baseUrl || !this.playingItem?.libraryItemId) {
      return ''
    }
    return this.baseUrl + `/api/items/${this.playingItem.libraryItemId}/cover?token=${this.apiToken}`
  }

  private getCoverColorSourceKey(coverSource: string): string {
    return !coverSource && this.isLocalPlaying ? 'resource:nocover.jpg' : coverSource
  }

  private isCurrentCoverColorRequest(requestId: number, sourceKey: string, lifecycleId: number): boolean {
    return this.coverColorActive &&
      requestId === this.coverColorRequest &&
      lifecycleId === this.coverColorLifecycle &&
      sourceKey === this.getCoverColorSourceKey(this.getCoverSource())
  }

  private invalidateCoverColorRequest() {
    this.coverColorRequest++
    const session = this.coverColorSession
    this.coverColorSession = undefined
    this.coverColorPromise = undefined
    this.coverColorPromiseKey = ''
    this.coverColorPromiseLifecycle = -1
    if (session) {
      try {
        session.cancel()
      } catch (_) {
      }
      try {
        session.close()
      } catch (_) {
      }
    }
  }

  private async usePreviousCoverColorOrAppBackground(requestId: number, sourceKey: string,
    lifecycleId: number): Promise<void> {
    if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
      return
    }
    if (sourceKey) {
      this.coverColorResolvedKey = sourceKey
      this.coverColorResolvedLifecycle = lifecycleId
    }
    if (this.hasSuccessfulCoverColor) {
      await this.updateStatusBarContentColor()
      return
    }
    let fallbackColor: number = 0xff181818
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      fallbackColor = await context.resourceManager.getColor($r('sys.color.background_secondary'))
    } catch (_) {
    }
    if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
      return
    }
    this.coverColor = fallbackColor
    this.coverColorReadyKey = ''
    await this.updateStatusBarContentColor()
  }

  private getCoverCachePath(coverSource: string): string {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext
    let hash = 0
    for (let index = 0; index < coverSource.length; index++) {
      hash = (hash * 31 + coverSource.charCodeAt(index)) >>> 0
    }
    return `${context.cacheDir}/harmshelf-cover-${hash.toString(16)}`
  }

  private async refreshCoverColor(force: boolean = false): Promise<void> {
    while (this.coverColorActive) {
      const coverSource = this.getCoverSource()
      const useFallbackCover = !coverSource && this.isLocalPlaying
      const sourceKey = this.getCoverColorSourceKey(coverSource)
      const lifecycleId = this.coverColorLifecycle
      if (!sourceKey) {
        this.invalidateCoverColorRequest()
        await this.usePreviousCoverColorOrAppBackground(this.coverColorRequest, sourceKey, lifecycleId)
        return
      }
      if (!force && lifecycleId === this.coverColorResolvedLifecycle &&
        (sourceKey === this.coverColorReadyKey || sourceKey === this.coverColorResolvedKey)) {
        return
      }
      if (this.coverColorPromise && this.coverColorPromiseKey === sourceKey &&
        this.coverColorPromiseLifecycle === lifecycleId) {
        const pendingPromise = this.coverColorPromise
        const pendingRequestId = this.coverColorRequest
        await pendingPromise
        const currentCoverSource = this.getCoverSource()
        const currentSourceKey = this.getCoverColorSourceKey(currentCoverSource)
        if (!this.coverColorActive) {
          return
        }
        if (pendingRequestId === this.coverColorRequest && lifecycleId === this.coverColorLifecycle &&
          sourceKey === currentSourceKey) {
          return
        }
        force = false
        continue
      }
      if (this.coverColorPromise) {
        this.invalidateCoverColorRequest()
      }
      const requestId = ++this.coverColorRequest
      const colorPromise = this.extractCoverColor(coverSource, sourceKey, requestId, lifecycleId, useFallbackCover)
      this.coverColorPromise = colorPromise
      this.coverColorPromiseKey = sourceKey
      this.coverColorPromiseLifecycle = lifecycleId
      try {
        await colorPromise
      } finally {
        if (this.coverColorPromise === colorPromise) {
          this.coverColorPromise = undefined
          this.coverColorPromiseKey = ''
          this.coverColorPromiseLifecycle = -1
        }
      }
      const currentCoverSource = this.getCoverSource()
      const currentSourceKey = this.getCoverColorSourceKey(currentCoverSource)
      if (!this.coverColorActive) {
        return
      }
      if (requestId === this.coverColorRequest && lifecycleId === this.coverColorLifecycle &&
        sourceKey === currentSourceKey) {
        return
      }
      force = false
    }
  }

  private async extractCoverColor(coverSource: string, sourceKey: string, requestId: number, lifecycleId: number,
    useFallbackCover: boolean = false): Promise<void> {
    let session: rcp.Session | undefined = undefined
    let imageSource: image.ImageSource | undefined = undefined
    let pixelMap: image.PixelMap | undefined = undefined
    let fallbackRawFileOpen: boolean = false
    let temporaryCachePath: string = ''
    try {
      if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
        return
      }
      if (useFallbackCover) {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext
        const rawFile = await context.resourceManager.getRawFd('nocover.jpg')
        fallbackRawFileOpen = true
        imageSource = image.createImageSource(rawFile)
      } else if (coverSource.startsWith('http://') || coverSource.startsWith('https://')) {
        const cachePath = this.getCoverCachePath(coverSource)
        let cacheExists: boolean = false
        try {
          cacheExists = fs.accessSync(cachePath)
        } catch (_) {
        }
        if (cacheExists) {
          try {
            imageSource = image.createImageSource(cachePath)
            pixelMap = await imageSource.createPixelMap({
              desiredSize: { width: 32, height: 32 },
              desiredPixelFormat: image.PixelMapFormat.RGBA_8888
            })
          } catch (_) {
            if (pixelMap) {
              try {
                await pixelMap.release()
              } catch (_) {
              }
              pixelMap = undefined
            }
            if (imageSource) {
              try {
                await imageSource.release()
              } catch (_) {
              }
              imageSource = undefined
            }
            if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
              return
            }
            try {
              fs.unlinkSync(cachePath)
            } catch (_) {
            }
          }
        }
        if (!pixelMap) {
          // shortcut: first use still downloads once; subsequent extraction reuses the app cache.
          session = rcp.createSession()
          this.coverColorSession = session
          const request = new rcp.Request(coverSource, 'GET')
          request.configuration = {
            transfer: {
              timeout: {
                connectMs: 3000,
                transferMs: 3000,
                inactivityMs: 3000
              }
            }
          }
          const response = await session.fetch(request)
          if (!response.body) {
            await this.usePreviousCoverColorOrAppBackground(requestId, sourceKey, lifecycleId)
            return
          }
          if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
            return
          }
          try {
            temporaryCachePath = `${cachePath}.${requestId}.tmp`
            try {
              fs.unlinkSync(temporaryCachePath)
            } catch (_) {
            }
            const file = fs.openSync(temporaryCachePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
            try {
              fs.writeSync(file.fd, response.body)
            } finally {
              fs.closeSync(file.fd)
            }
            if (!this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
              return
            }
            fs.renameSync(temporaryCachePath, cachePath)
            temporaryCachePath = ''
            imageSource = image.createImageSource(cachePath)
          } catch (_) {
            imageSource = image.createImageSource(response.body)
          }
        }
      } else if (this.isLocalPlaying && this.localPlayItem?.coverPath) {
        imageSource = image.createImageSource(this.localPlayItem.coverPath)
      } else {
        imageSource = image.createImageSource(coverSource)
      }
      if (!imageSource) {
        await this.usePreviousCoverColorOrAppBackground(requestId, sourceKey, lifecycleId)
        return
      }
      if (!pixelMap) {
        pixelMap = await imageSource.createPixelMap({
          desiredSize: { width: 32, height: 32 },
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        })
      }
      const picker = await effectKit.createColorPicker(pixelMap)
      let color: effectKit.Color | undefined = undefined
      try {
        color = picker.getLargestProportionColor()
      } catch (_) {
        color = picker.getAverageColor()
      }
      if (color && this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
        this.coverColor = 0xff000000 +
          Math.round(color.red) * 0x10000 + Math.round(color.green) * 0x100 + Math.round(color.blue)
        this.coverColorReadyKey = sourceKey
        this.coverColorResolvedKey = sourceKey
        this.coverColorResolvedLifecycle = lifecycleId
        this.hasSuccessfulCoverColor = true
        await this.updateStatusBarContentColor()
      } else {
        await this.usePreviousCoverColorOrAppBackground(requestId, sourceKey, lifecycleId)
      }
    } catch (_) {
      if (this.isCurrentCoverColorRequest(requestId, sourceKey, lifecycleId)) {
        Logger.error('提取封面主色失败')
      }
      await this.usePreviousCoverColorOrAppBackground(requestId, sourceKey, lifecycleId)
    } finally {
      if (temporaryCachePath) {
        try {
          fs.unlinkSync(temporaryCachePath)
        } catch (_) {
        }
      }
      if (pixelMap) {
        try {
          await pixelMap.release()
        } catch (_) {
        }
      }
      if (imageSource) {
        try {
          await imageSource.release()
        } catch (_) {
        }
      }
      if (fallbackRawFileOpen) {
        try {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext
          context.resourceManager.closeRawFdSync('nocover.jpg')
        } catch (_) {
        }
      }
      if (session) {
        if (this.coverColorSession === session) {
          this.coverColorSession = undefined
        }
        try {
          session.close()
        } catch (_) {
        }
      }
    }
  }
  @Monitor('speed')
  async speedMonitoring(_: IMonitor) {
    this.changeSpeedIcon()
  }
  changeSpeedIcon() {
    switch(this.speed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_50_X:
        this.speedIcon = $r('sys.symbol.speed_50percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        this.speedIcon = $r('sys.symbol.speed_75percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        this.speedIcon = $r('sys.symbol.speed_100percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        this.speedIcon = $r('sys.symbol.speed_125percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_50_X:
        this.speedIcon = $r('sys.symbol.speed_150percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        this.speedIcon = $r('sys.symbol.speed_175percent')
        break;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        this.speedIcon = $r('sys.symbol.speed_200percent')
        break;
      default :
        break;
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${month}月 ${day}, ${year} ${hours}:${minutes}`
  }

  formatSeconds(seconds: number): string {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
    } else if (m > 0) {
      return `${m}:${s.toString().padStart(2, '0')}`
    } else {
      return `0:${s.toString().padStart(2, '0')}`
    }
  }

  formatSleepTime(seconds: number): string {
    if (seconds <= 0) {
      return "0 sec"
    }
    if (seconds >= 60) {
      const minutes = Math.round(seconds / 60)
      return `${minutes} min`
    } else {
      const secs = Math.round(seconds)
      return `${secs} sec`
    }
  }

  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    let formattedTime = '';
    if (hours > 0) {
      formattedTime += `${hours} hr `;
    }
    formattedTime += `${minutes} min`;
    return formattedTime;
  }

  getCurrentDuration(): number {
    if (this.isLocalPlaying) {
      return this.currentTrackDuration
    }
    return this.playingItem?.audioTracks[this.playingIndex]?.duration ?? 0
  }

  fadeIn() {
    this.isPlaying = true
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let duration = 1000
    let volume = 0;
    const step = 50; // 调整间隔时间，单位 ms
    const increment = step / duration; // 每次增加的音量比例
    this.avPlayer!.setVolume(volume);
    this.avPlayer!.play();
    const interval = setInterval(() => {
      volume += increment;
      if (volume >= 1.0) {
        this.avPlayer!.setVolume(1.0);
        clearInterval(interval);
        this.fadeInterval = -1
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
    this.fadeInterval = interval
  }

  fadeOut() {
    this.isPlaying = false
    if (this.fadeInterval !== -1) {
      clearInterval(this.fadeInterval)
    }
    let duration = 1000
    let volume = 1.0; // 假设当前音量是最大值
    const step = 50; // 调整间隔时间，单位 ms
    const decrement = step / duration; // 每次减少的音量比例
    const interval = setInterval(() => {
      volume -= decrement;
      if (volume <= 0.0) {
        this.avPlayer!.setVolume(0.0);
        clearInterval(interval);
        this.fadeInterval = -1
        this.avPlayer!.pause(); // 在音量完全降为 0 后暂停
      } else {
        this.avPlayer!.setVolume(volume);
      }
    }, step);
    this.fadeInterval = interval
  }

  async getPlayContent(playItem: PlayItem, time: number) {
    let index: number = 0
    for (let i = 0; i < playItem.audioTracks.length; i++) {
      if (playItem.audioTracks[i].startOffset > time) {
        index = i > 0 ? i - 1 : 0
        break
      }
    }
    this.playingIndex = index
    this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
    this.playStartTime = time - playItem.audioTracks[index].startOffset
    this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
    Logger.info(`共playItem.audioTracks.length条音轨`)
    Logger.info(`播放序号为this.playingIndex`)
    Logger.info(`起始位置为this.playStartTime`)
  }

  @Builder
  editBookmarkBuilder() {
    Column() {
      TextInput({
        placeholder: "书签标题",
        text: this.tmpBookmarkTitle
      })
        .width("100%")
        .height(45)
        .borderRadius(10)
        .border({
          width: 0.35,
          radius: 10,
          color: $r('sys.color.ohos_id_color_focused_outline_transparent')
        })
        .shadow(ShadowStyle.OUTER_DEFAULT_XS)
        .clip(false)
        .margin({ bottom: 20 })
        .caretColor($r('sys.color.font_secondary'))
        .fontSize(18)
        .fontColor(this.playColorPalette.primary)
        .placeholderColor(this.playColorPalette.secondary)
        .placeholderFont({
          size: 18
        })
        .type(InputType.Normal)
        .enterKeyType(EnterKeyType.Done)
        .onChange((value) => {
          this.tmpBookmarkTitle = value
        })

      Row({ space: 20 }) {
        Row() {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            monopolizeActionEvents: false,
            onButtonClick: () => {
              this.showEditBookmark = false
            }
          }) {
            Text("取消")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .height(50)
        .width('50%')
        .layoutWeight(1)
        .clip(false)

        Row() {
          ImmersiveActionButton({
            barWidth: '100%',
            barHeight: 50,
            monopolizeActionEvents: false,
            onButtonClick: async () => {
              let bookmark: Bookmark = {
                libraryItemId: this.playingItem!.libraryItemId,
                title: this.tmpBookmarkTitle,
                time: this.tmpBookmarkTime,
                createdAt: Date.now()
              }
              let status = await createBookmark(this.playingItem!.libraryItemId, bookmark)
              if (status) {
                this.showEditBookmark = false
                this.getUIContext().getPromptAction().showToast({
                  message: '编辑书签成功！',
                  duration: 500
                });
              } else {
                this.getUIContext().getPromptAction().showToast({
                  message: '编辑书签失败，请检查网络！',
                  duration: 500
                });
              }
            }
          }) {
            Text("确认")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
              .hitTestBehavior(HitTestMode.None)
          }
        }
        .height(50)
        .width('50%')
        .layoutWeight(1)
        .clip(false)
      }
    }
    .padding({ left: 20, right: 20, top: 8, bottom: 25 })
  }

  @Builder
  bookmarkEnd(bookmark: Bookmark, index: number) {
    Row() {
      Row() {
        ImmersiveActionButton({
          barWidth: 40,
          barHeight: 40,
          onButtonClick: () => {
            this.showBookmark = false
            this.editBookmarkIndex = index
            this.tmpBookmarkTitle = bookmark.title
            this.tmpBookmarkTime = bookmark.time
            this.showEditBookmark = true
          }
        }) {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(18)
            .fontColor([this.playColorPalette.primary])
            .hitTestBehavior(HitTestMode.None)
        }
      }
      .width(40)
      .height(40)
      .margin({ left: 5, right: 10 })
      .clip(false)

      Row() {
        ImmersiveActionButton({
          barWidth: 40,
          barHeight: 40,
          onButtonClick: async () => {
            let status = await deleteBookmark(this.playingItem!.libraryItemId, bookmark.time)
            if (status) {
              this.showBookmark = false
              this.getUIContext().getPromptAction().showToast({
                message: '删除书签成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '删除书签失败，请检查网络！',
                duration: 500
              });
            }
          }
        }) {
          SymbolGlyph($r('sys.symbol.trash_fill'))
            .fontSize(18)
            .fontColor([Color.Red])
            .hitTestBehavior(HitTestMode.None)
        }
      }
      .width(40)
      .height(40)
      .margin({ left: 10, right: 20 })
      .clip(false)
    }
    .clip(false)
  }

  @Builder
  bookmarkBuilder() {
    Column() {
      Stack() {
        List() {
          Repeat<Bookmark>(this.bookmarks)
            .each((repeatItem: RepeatItem<Bookmark>) => {
             ListItem() {
               HdsListItem({
                 hdsListItemCard: {
                   cardBorderRadius: 10,
                   cardBackgroundColor: Color.Transparent,
                   textItem: {
                     primaryText: {
                       text: repeatItem.item.title.length === 0 ? this.formatTime(repeatItem.item.createdAt) : repeatItem.item.title,
                       modifier: new TextModifier().fontSize(16).fontColor(this.playColorPalette.primary)
                     },
                     primaryPrefixSymbol: {
                       symbol: this.playbackSheetSymbol($r('sys.symbol.bookmark'), this.playColorPalette.secondary)
                     },
                     secondaryText: {
                       text: this.formatSeconds(repeatItem.item.time),
                       modifier: new TextModifier().fontSize(16).fontColor(this.playColorPalette.secondary)
                     },
                     secondaryPrefixSymbol: {
                       symbol: this.playbackSheetSymbol($r('sys.symbol.clock'), this.playColorPalette.secondary)
                     }
                   },
                   onClick: async () => {
                     this.showBookmark = false
                     await this.avPlayer!.reset();
                     this.isPlaying = true
                     await this.getPlayContent(this.playingItem!, repeatItem.item.time)
                     this.getUIContext().getPromptAction().showToast({
                       message: '跳转书签成功！',
                       duration: 500
                     });
                   }
                 }
               })
             }
             .swipeAction({
               end: {
                 builder: () => {
                   this.bookmarkEnd(repeatItem.item, repeatItem.index)
                 }
               }
             })
             .clip(false)
            })
            .virtualScroll({ totalCount: this.bookmarks.length })
            .key((item: Bookmark) => item.createdAt + ':' + item.time)

        }
        .cachedCount(2)
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(true)
        .visibility(!this.showProgress ? Visibility.Visible : Visibility.None)

        Column() {
          LoadingProgress()
            .width("100%")
            .height(45)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 80 })
        .justifyContent(FlexAlign.Center)
        .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .hitTestBehavior(HitTestMode.None)

      Row() {
        TextInput({
          placeholder: this.formatTime(Date.now())
        })
          .width("100%")
          .height(45)
          .layoutWeight(1)
          .borderRadius(10)
          .border({
            width: 0.35,
            radius: 10,
            color: $r('sys.color.ohos_id_color_focused_outline_transparent')
          })
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
          .clip(false)
          .margin({ right: 15 })
          .caretColor($r('sys.color.font_secondary'))
          .fontSize(18)
          .fontColor(this.playColorPalette.primary)
          .placeholderColor(this.playColorPalette.secondary)
          .placeholderFont({
            size: 18
          })
          .type(InputType.Normal)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value) => {
            this.tmpBookmarkTitle = value
          })

        ImmersiveActionButton({
          barWidth: 110,
          barHeight: 45,
          barRadius: 22.5,
          onButtonClick: async () => {
            let time = Date.now()
            let bookmark: Bookmark = {
              libraryItemId: this.playingItem!.libraryItemId,
              title: this.tmpBookmarkTitle.length === 0 ? this.formatTime(time) : this.tmpBookmarkTitle,
              time: this.playingItem!.audioTracks[this.playingIndex].startOffset + this.playedTime,
              createdAt: time
            }
            let status = await createBookmark(this.playingItem!.libraryItemId, bookmark)
            if (status) {
              this.showBookmark = false
              this.getUIContext().getPromptAction().showToast({
                message: '创建书签成功！',
                duration: 500
              });
            } else {
              this.getUIContext().getPromptAction().showToast({
                message: '创建书签失败，请检查网络！',
                duration: 500
              });
            }
          }
        }) {
          Text("创建书签")
            .fontSize(18)
            .fontColor(this.playColorPalette.primary)
        }
      }
      .padding({ top: 10, bottom: 5 })
      .margin({ left: 20, right: 20, bottom: 20 })
      .borderRadius(10)
    }
    .padding({ top: 8 })
  }

  @Builder
  speedBuilder() {
    Scroll() {
      Column({ space: 5 }) {
        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_50_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("0.5x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("0.5x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_0_75_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("0.75x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("0.75x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_00_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("1x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_25_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("1.25x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.25x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_50_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("1.5x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.5x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_50_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_1_75_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("1.75x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("1.75x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }

        if (this.speed === media.PlaybackSpeed.SPEED_FORWARD_2_00_X) {
          Row() {
            ImmersiveActionButton({
              barWidth: '100%',
              barHeight: 50,
              barRadius: 25,
              monopolizeActionEvents: false,
              onButtonClick: () => {
                this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
                this.avPlayer!.setSpeed(this.speed)
                this.showSpeed = false
              }
            }) {
              Text("2x")
                .fontSize(18)
                .fontColor(this.playColorPalette.primary)
            }
          }
          .width('100%')
          .height(50)
          .clip(false)
        } else {
          Button({ type: ButtonType.Normal }) {
            Text("2x")
              .fontSize(18)
              .fontColor(this.playColorPalette.primary)
          }
            .width('100%')
            .height(50)
            .borderRadius(25)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X
              this.avPlayer!.setSpeed(this.speed)
              this.showSpeed = false
            })
        }
      }
      .padding({ left: 20, right: 20, top: 8, bottom: 25 })
    }
    .scrollBar(BarState.Off)
  }

  private selectSleepOption(option: number) {
    if (option === 0) {
      this.sleepTime = 0
    } else if (option === -1) {
      this.sleepTime = this.playingItem!.audioTracks[this.playingIndex].startOffset +
        this.playingItem!.audioTracks[this.playingIndex].duration
    } else {
      this.sleepTime = this.playedTime + this.playingItem!.audioTracks[this.playingIndex].startOffset + option * 60
    }
    this.selectedSleepOption = option
    this.showSleep = false
  }

  @Builder
  sleepOptionBuilder(label: string, option: number) {
    if (option === 0 || this.selectedSleepOption === option) {
      Row() {
        ImmersiveActionButton({
          barWidth: '100%',
          barHeight: 50,
          barRadius: 25,
          monopolizeActionEvents: false,
          onButtonClick: () => {
            this.selectSleepOption(option)
          }
        }) {
          Text(label)
            .fontSize(18)
            .fontColor(this.playColorPalette.primary)
        }
      }
      .width('100%')
      .height(50)
      .clip(false)
    } else {
      Button({ type: ButtonType.Normal }) {
        Text(label)
          .fontSize(18)
          .fontColor(this.playColorPalette.primary)
      }
      .width('100%')
      .height(50)
      .borderRadius(25)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.selectSleepOption(option))
    }
  }

  @Builder
  sleepBuilder() {
    Scroll() {
      Column({ space: 5 }) {
        this.sleepOptionBuilder("5 min", 5)
        this.sleepOptionBuilder("10 min", 10)
        this.sleepOptionBuilder("15 min", 15)
        this.sleepOptionBuilder("30 min", 30)
        this.sleepOptionBuilder("45 min", 45)
        this.sleepOptionBuilder("60 min", 60)
        this.sleepOptionBuilder("90 min", 90)
        this.sleepOptionBuilder("章节结束", -1)
        this.sleepOptionBuilder("清除定时", 0)
      }
      .padding({ left: 20, right: 20, top: 8, bottom: 25 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  chapterBuilder() {
    Column() {
      if (this.isLocalPlaying) {
        List({ scroller: this.chapterScroller }) {
          Repeat<LocalTrack>(this.localPlayItem!.tracks)
            .each((repeatItem: RepeatItem<LocalTrack>) => {
            ListItem() {
              if (this.playingIndex === repeatItem.index) {
                Row() {
                  ImmersiveActionButton({
                    barWidth: '100%',
                    barHeight: 50,
                    barRadius: 25,
                    monopolizeActionEvents: false,
                    onButtonClick: async () => {
                      this.showChapter = false
                      await this.avPlayer!.reset();
                      this.playingIndex = repeatItem.index
                      this.playingTitle = repeatItem.item.title
                      try {
                        const file = fs.openSync(repeatItem.item.filePath, fs.OpenMode.READ_ONLY)
                        try {
                          this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                        } catch (_) {
                          fs.closeSync(file)
                        }
                      } catch (_) {
                        this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                      }
                    }
                  }) {
                    Row() {
                      Text(repeatItem.item.title)
                        .fontSize(16)
                        .fontColor(this.playColorPalette.primary)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .padding({ left: 15, right: 15 })
                  }
                }
                .width('100%')
                .height(50)
                .clip(false)
              } else {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Text(repeatItem.item.title)
                      .fontSize(16)
                      .fontColor(this.playColorPalette.primary)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .padding({ left: 27, right: 27 })
                }
                .width('100%')
                .height(50)
                .padding({ left: 0, right: 0 })
                .borderRadius(25)
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  this.showChapter = false
                  await this.avPlayer!.reset();
                  this.playingIndex = repeatItem.index
                  this.playingTitle = repeatItem.item.title
                  try {
                    const file = fs.openSync(repeatItem.item.filePath, fs.OpenMode.READ_ONLY)
                    try {
                      this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                    } catch (_) {
                      fs.closeSync(file)
                    }
                  } catch (_) {
                    this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                  }
                })
              }
            }
            .clip(false)
            })
            .virtualScroll({ totalCount: this.localPlayItem!.tracks.length })
            .key((item: LocalTrack) => item.filePath)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(false)
        .clipContent(ContentClipMode.BOUNDARY)
        .cachedCount(2)
      } else {
        List({ scroller: this.chapterScroller }) {
          Repeat<Chapter>(this.playingItem!.chapters)
            .each((repeatItem: RepeatItem<Chapter>) => {
            ListItem() {
              if (this.playingIndex === repeatItem.index) {
                Row() {
                  ImmersiveActionButton({
                    barWidth: '100%',
                    barHeight: 50,
                    barRadius: 25,
                    monopolizeActionEvents: false,
                    onButtonClick: async () => {
                      this.showChapter = false
                      await this.avPlayer!.reset();
                      this.isPlaying = true
                      this.playingIndex = repeatItem.index
                      this.playingTitle = repeatItem.item.title
                      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                    }
                  }) {
                    Row() {
                      Text(repeatItem.item.title)
                        .fontSize(16)
                        .fontColor(this.playColorPalette.primary)
                        .width('100%')
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text(this.formatSeconds(repeatItem.item.start))
                        .fontSize(16)
                        .fontColor(this.playColorPalette.secondary)
                        .margin({ left: 10 })
                    }
                    .padding({ left: 15, right: 15 })
                  }
                }
                .width('100%')
                .height(50)
                .clip(false)
              } else {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Text(repeatItem.item.title)
                      .fontSize(16)
                      .fontColor(this.playColorPalette.primary)
                      .width('100%')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(this.formatSeconds(repeatItem.item.start))
                      .fontSize(16)
                      .fontColor(this.playColorPalette.secondary)
                      .margin({ left: 10 })
                  }
                  .padding({ left: 27, right: 27 })
                }
                .width('100%')
                .height(50)
                .padding({ left: 0, right: 0 })
                .borderRadius(25)
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                  this.showChapter = false
                  await this.avPlayer!.reset();
                  this.isPlaying = true
                  this.playingIndex = repeatItem.index
                  this.playingTitle = repeatItem.item.title
                  this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                })
              }
            }
            .clip(false)
            })
            .virtualScroll({ totalCount: this.playingItem!.chapters.length })
            .key((item: Chapter) => item.start + ':' + item.title)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20, bottom: 25 })
        .scrollBar(BarState.Off)
        .borderRadius(10)
        .clip(false)
        .clipContent(ContentClipMode.BOUNDARY)
        .cachedCount(2)
      }
    }
    .clip(false)
    .padding({ top: 8 })
  }

  @Builder
  playBuilder() {
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
      GridCol({ span: 1 }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Stack({ alignContent: Alignment.TopStart }) {
            Stack({ alignContent: Alignment.Bottom }) {
              if (!this.isLocalPlaying) {
                Image(this.baseUrl + `/api/items/${this.playingItem?.libraryItemId}/cover?token=${this.apiToken}`)
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .transition(TransitionEffect.IDENTITY)
                  .id('remotePlayerCover')
              } else if (this.localPlayItem?.coverPath) {
                Image(fileUri.getUriFromPath(this.localPlayItem.coverPath))
                  .alt($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .transition(TransitionEffect.IDENTITY)
                  .id('localPlayerCover')
              } else {
                Image($rawfile('nocover.jpg'))
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .aspectRatio(1)
                  .draggable(false)
                  .transition(TransitionEffect.IDENTITY)
                  .id('fallbackPlayerCover')
              }

              Stack({ alignContent: Alignment.Bottom }) {
                Column()
                .width('100%')
                .height(200)
                .linearGradient({
                  direction: GradientDirection.Bottom,
                  colors: [[ColorMetrics.rgba(
                    (this.coverColor >>> 16) & 0xff,
                    (this.coverColor >>> 8) & 0xff,
                    this.coverColor & 0xff,
                    0
                  ).color, 0], [this.coverColor, 1]]
                })

              }
              .width('100%')
              .height(200)
              .position({ bottom: this.playbackGradientBottomOffset })

              if (this.displayWidth >= 1000) {
                Column()
                  .width(200)
                  .height('100%')
                  .position({ right: 0 })
                  .linearGradient({
                    direction: GradientDirection.Right,
                    colors: [[ColorMetrics.rgba(
                      (this.coverColor >>> 16) & 0xff,
                      (this.coverColor >>> 8) & 0xff,
                      this.coverColor & 0xff,
                      0
                    ).color, 0], [this.coverColor, 1]]
                  })
              }
            }
            .width('100%')
            .aspectRatio(1)
            .clip(false)

            Stack({ alignContent: Alignment.TopStart }) {
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(this.coverColor)
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

              Column() {
                Row()
                  .height(0)

                Column() {
                  Text(this.playingTitle)
                    .width('100%')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.playColorPalette.primary)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.isLocalPlaying ? "本地文件" :
                    (this.playingItem?.mediaType === 'book' ?
                    this.playingItem?.mediaMetadata.authors?.map(item => item.name).join(", ") :
                    this.playingItem?.displayAuthor))
                    .width('100%')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.playColorPalette.secondary)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 6 })

                }
                .width('100%')

                  Column() {
                  Row() {
                    Text(this.formatSeconds(this.playedPercent * this.getCurrentDuration() / 100))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.playColorPalette.primary)

                    Text(this.formatSeconds(this.getCurrentDuration()))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.playColorPalette.primary)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ left: 20, right: 20 })

                  Slider({
                    value: this.playedPercent,
                    min: 0,
                    max: 100,
                    step: 0.01,
                    style: this.lockPlayer ? SliderStyle.NONE : SliderStyle.OutSet
                  })
                    .width('100%')
                    .margin({ top: -4 })
                    .trackThickness(5)
                    .selectedBorderRadius(5)
                    .blockSize({
                      width: 14,
                      height: 14
                    })
                    .padding({ left: this.lockPlayer ? 20 : 10, right: this.lockPlayer ? 20 : 10 })
                    .blockColor(this.playColorPalette.sliderBlock)
                    .trackColor(this.playColorPalette.sliderTrack)
                    .selectedColor(this.playColorPalette.secondary)
                    .sliderInteractionMode(SliderInteraction.SLIDE_AND_CLICK_UP)
                    .onChange((value: number, mode: SliderChangeMode) => {
                      if (mode === SliderChangeMode.Begin) {
                        this.sliderMoving = true
                      }
                      if (mode === SliderChangeMode.End && this.sliderMoving === true) {
                        let dur = this.getCurrentDuration()
                        let seekTime = value * dur * 10
                        if (seekTime < 0) {
                          seekTime = 0
                        } else if (seekTime > dur * 1000) {
                          seekTime = dur * 1000
                        }
                        if (['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) {
                          this.avPlayer!.seek(seekTime)
                        }
                        this.sliderMoving = false
                      }
                    })
                    .hitTestBehavior(this.lockPlayer ? HitTestMode.None : HitTestMode.Default)
                  }
                  .width('100%')

                Row() {
                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.backward_end_fill'))
                      .fontSize(28)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex > 0 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex--
                    if (this.isLocalPlaying) {
                      this.playingTitle = this.localPlayItem!.tracks[this.playingIndex].title
                      try {
                        let file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                        this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                      } catch (_) {
                        this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                      }
                    } else {
                      this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
                      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                    }
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.gobackwardIcon)
                      .fontSize(32)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
                    this.avPlayer!.seek(this.playedTime - this.playSetting!.skipIntervals > 0 ? (this.playedTime - this.playSetting!.skipIntervals) * 1000 : 0)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Row() {
                    ImmersiveActionButton({
                      barWidth: 75,
                      barHeight: 75,
                      barRadius: 37.5,
                      onButtonClick: async () => {
                        if (this.isPlaying) {
                          if (this.avPlayer!.state === 'playing') {
                            if (this.playSetting?.fadeInOut) {
                              this.fadeOut()
                            } else {
                              this.avPlayer!.pause()
                            }
                          }
                        } else {
                          if (this.avPlayer!.state === 'error') {
                            this.isPlaying = true
                            const savedPosition = this.playedTime
                            await this.avPlayer!.reset()
                            this.playStartTime = savedPosition
                            if (this.isLocalPlaying) {
                              const file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                              this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                            } else {
                              this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                            }
                            this.avPlayer!.prepare()
                          } else if (['prepared', 'paused', 'completed'].includes(this.avPlayer!.state)) {
                            if (this.playSetting?.fadeInOut) {
                              this.fadeIn()
                            } else {
                              this.avPlayer!.play()
                            }
                          }
                        }
                      }
                    }) {
                      SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
                        .fontSize(34)
                        .fontColor([this.playColorPalette.secondary])
                    }
                  }
                  .height(75)
                  .width(75)
                  .margin({ left: 6, right: 6 })
                  .clip(false)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.goforwardIcon)
                      .fontSize(32)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(50)
                  .width(50)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    if (!['prepared', 'playing', 'paused', 'completed'].includes(this.avPlayer!.state)) return
                    let dur = this.getCurrentDuration()
                    this.avPlayer!.seek(this.playedTime + this.playSetting!.skipIntervals < dur ? (this.playedTime + this.playSetting!.skipIntervals) * 1000 : dur * 1000)
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.forward_end_fill'))
                      .fontSize(28)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(40)
                  .width(40)
                  .backgroundColor(Color.Transparent)
                  .enabled(this.playingIndex < (this.isLocalPlaying ? (this.localPlayItem?.tracks.length ?? 0) : (this.playingItem?.audioTracks.length ?? 0)) - 1 ? true : false)
                  .onClick(async () => {
                    await this.avPlayer!.reset();
                    this.playingIndex++
                    if (this.isLocalPlaying) {
                      this.playingTitle = this.localPlayItem!.tracks[this.playingIndex].title
                      try {
                        let file = fs.openSync(this.localPlayItem!.tracks[this.playingIndex].filePath, fs.OpenMode.READ_ONLY)
                        this.avPlayer!.fdSrc = { fd: file.fd, offset: 0, length: -1 }
                      } catch (_) {
                        this.getUIContext().getPromptAction().showToast({ message: '播放失败，格式不支持或文件不存在！', duration: 500 })
                      }
                    } else {
                      this.playingTitle = this.playingItem!.chapters?.[this.playingIndex]?.title ?? this.playingItem!.displayTitle
                      this.avPlayer!.url = this.baseUrl + this.playingItem!.audioTracks[this.playingIndex].contentUrl + "?token=" + this.apiToken
                    }
                  })
                  .visibility(this.lockPlayer ? Visibility.Hidden : Visibility.Visible)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .padding({ left: 10, right: 10 })

                Row() {
                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.bookmark'))
                      .fontSize(26)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(!this.isLocalPlaying && this.playingItem?.mediaType === 'book' ? true : false)
                  .onClick(() => {
                    this.tmpBookmarkTitle = ""
                    this.showBookmark = !this.showBookmark;
                  })
                  .bindSheet(this.showBookmark, this.bookmarkBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                    title: this.playbackSheetTitleBuilder("书签 " + this.bookmarks.length),
                    showClose: false,
                    onWillAppear: async () => {
                      this.showProgress = true
                      this.bookmarks = (await getBookmarks(this.user!.id)).filter(bookmark => bookmark.libraryItemId ===
                      this.playingItem!.libraryItemId)
                      this.showProgress = false
                    },
                    onDisappear: () => {
                      this.showBookmark = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph(this.speedIcon)
                      .fontSize(26)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showSpeed = !this.showSpeed;
                  })
                  .bindSheet(this.showSpeed, this.speedBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                    title: this.playbackSheetTitleBuilder("速度"),
                    showClose: false,
                    onDisappear: () => {
                      this.showSpeed = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.moon_z'))
                      .fontSize(26)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showSleep = !this.showSleep;
                  })
                  .bindSheet(this.showSleep, this.sleepBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                    title: this.playbackSheetTitleBuilder("睡眠定时"),
                    showClose: false,
                    onDisappear: () => {
                      this.showSleep = false
                    }
                  })

                  Button({ type: ButtonType.Circle }) {
                    SymbolGlyph($r('sys.symbol.list_bullet'))
                      .fontSize(26)
                      .fontColor([this.playColorPalette.secondary])
                  }
                  .height(45)
                  .width(45)
                  .backgroundColor(Color.Transparent)
                  .enabled(!this.isLocalPlaying ? this.playingItem?.mediaType === 'book' : (this.localPlayItem?.tracks.length ?? 0) > 1)
                  .onClick(() => {
                    this.showChapter = !this.showChapter;
                  })
                  .bindSheet(this.showChapter, this.chapterBuilder(), {
                    height: SheetSize.MEDIUM,
                    preferType: SheetType.CENTER,
                    systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                    title: this.playbackSheetTitleBuilder(this.isLocalPlaying ? ("章节 " + this.localPlayItem!.tracks.length) : ("章节 " + this.playingItem?.chapters.length)),
                    showClose: false,
                    onWillAppear: () => {
                      this.chapterScroller.scrollToIndex(this.playingIndex, false, ScrollAlign.CENTER)
                    },
                    onDisappear: () => {
                      this.showChapter = false
                    }
                  })
                }
                .width('100%')
                .padding({ left: 20, right: 20 })
                .justifyContent(FlexAlign.SpaceBetween)
                .bindSheet(this.showEditBookmark, this.editBookmarkBuilder(), {
                  height: SheetSize.FIT_CONTENT,
                  preferType: SheetType.CENTER,
                  systemMaterial: new uiMaterial.ImmersiveMaterial({ style: uiMaterial.ImmersiveStyle.THIN }),
                  title: this.playbackSheetTitleBuilder("编辑书签 " + this.formatSeconds(this.bookmarks[this.editBookmarkIndex]?.time??0)),
                  showClose: false,
                  onDisappear: () => {
                    this.showEditBookmark = false
                  }
                })
              }
              .width('100%')
              .height(this.playbackControlsHeight)
              .justifyContent(FlexAlign.SpaceBetween)
              .padding({
                left: 20,
                right: 20,
                bottom: (this.windowAvoidArea.navigationIndicator.visible ?
                  this.windowAvoidArea.navigationIndicator.bottomRect.height : 0) +
                  (this.shouldAddPlaybackBottomInset ? 20 : 0)
              })
            }
            .width('100%')
            .height(this.playbackControlsHeight)
            .position({ top: this.displayHeight - this.playbackControlsHeight })
          }
          .width('100%')
          .height('100%')
          .clip(false)
        Row() {
          ImmersiveActionButton({
            barWidth: 40,
            barHeight: 40,
            barRadius: 20,
            onButtonClick: () => {
              this.showPlay = false
            }
          }) {
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(32)
              .fontColor([this.playColorPalette.secondary])
          }

          Row() {
            ImmersiveActionButton({
              barWidth: 165,
              barHeight: 40,
              barRadius: 20,
              monopolizeActionEvents: false
            }) {
              Text("睡眠定时 " + ((this.sleepTime !== 0 && !this.isLocalPlaying && this.playingItem!.audioTracks !== undefined) ? this.formatSleepTime(this.sleepTime - this.playedTime - this.playingItem!.audioTracks[this.playingIndex].startOffset) : 0))
                .fontSize(18)
                .fontColor(this.playColorPalette.secondary)
            }
          }
          .width(165)
          .height(40)
          .clip(false)
          .visibility(this.sleepTime !== 0 ? Visibility.Visible : Visibility.None)

          ImmersiveActionButton({
            barWidth: 40,
            barHeight: 40,
            barRadius: 20,
            menuItems: [{
              symbolIcon: new SymbolGlyphModifier(this.lockPlayer ? $r('sys.symbol.lock') :
                $r('sys.symbol.lock_open')),
              value: this.lockPlayer ? "解锁播放器" : "锁定播放器",
              action: async () => {
                this.lockPlayer = !this.lockPlayer
              }
            }, {
              symbolIcon: new SymbolGlyphModifier($r('sys.symbol.xmark')),
              value: "关闭播放器",
              action: () => {
                this.avPlayer!.stop()
                this.shouldClosePlayer = true
                this.showPlay = false
              }
            }]
          }) {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontSize($r('sys.float.ohos_id_text_size_headline7'))
              .fontColor([this.playColorPalette.secondary])
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: 20,
          right: 20,
          top: (this.windowAvoidArea.statusBar.visible ? this.windowAvoidArea.statusBar.topRect.height : 0) + 8
        })
      }
      .width('100%')
      .height(LayoutPolicy.matchParent)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .transition(TransitionEffect.IDENTITY)
          .clip(false)
        }
      if (this.displayWidth >= 1000) {
        GridCol({ span: 1 }) {
          this.recommendationsBuilder()
        }
      }
    }
    .width('100%')
    .height('100%')

      Column()
        .width('100%')
        .height(this.windowAvoidArea.statusBar.visible ? this.windowAvoidArea.statusBar.topRect.height : 0)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [[ColorMetrics.rgba(
            (this.coverColor >>> 16) & 0xff,
            (this.coverColor >>> 8) & 0xff,
            this.coverColor & 0xff,
            (this.windowAvoidArea.statusBar.visible ? this.windowAvoidArea.statusBar.topRect.height : 0) / 200
          ).color, 0], [ColorMetrics.rgba(
            (this.coverColor >>> 16) & 0xff,
            (this.coverColor >>> 8) & 0xff,
            this.coverColor & 0xff,
            0
          ).color, 1]]
        })
        .position({ top: 0, left: 0 })
        .hitTestBehavior(HitTestMode.None)
  }

  private isBottomTabDevice(): boolean {
    return deviceInfo.deviceType === 'phone' || deviceInfo.deviceType === 'tablet'
  }

  @Builder
  desktopMiniBarBuilder() {
    Row() {
      ImmersiveActionButton({
        barWidth: '100%',
        barHeight: MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT,
        barRadius: MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT / 2,
        monopolizeActionEvents: false
      }) {
        PlaybackMiniBar({ forceExpanded: true, isStandalone: true })
      }
    }
    .width('calc(100% - 40vp)')
    .constraintSize({ maxWidth: 600 })
    .height(MOBILE_BOTTOM_TAB_BAR_VISUAL_HEIGHT)
    .padding({ left: 0, right: 0 })
    .margin({ bottom: MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN })
    .clip(false)
    .transition(TransitionEffect.OPACITY.animation({
      duration: 280,
      curve: Curve.Friction
    }))
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if ((!this.isBottomTabDevice() || !this.isIndex) && this.isStartPlaying) {
        this.desktopMiniBarBuilder()
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .bindContentCover(this.showPlay, this.playBuilder(), {
      onDisappear: () => {
        this.showPlay = false
        if (this.shouldClosePlayer) {
          this.isStartPlaying = false
          this.isPlaying = false
          this.shouldClosePlayer = false
        }
        if (this.recommendationToOpen) {
          const target = this.recommendationToOpen
          this.recommendationToOpen = undefined
          this.libraryItem = target
          this.pageInfos.pushPathByName('libraryItemDetail', null)
        }
      }
    })
  }
}
