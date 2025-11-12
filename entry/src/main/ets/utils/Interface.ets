export interface LoginInfo {
  name: string;
  server: string,
  username: string,
  password: string
}

export interface LoginUser {
  username: string,
  password: string
}

export interface Config {
  loginInfo: LoginInfo,
  autoLogin: Boolean,
  jumpTime: number
}

export interface Permissions {
  download: boolean
  update: boolean
  delete: boolean
  upload: boolean
  accessAllLibraries: boolean
  accessAllTags: boolean
  accessExplicitContent: boolean
}

export interface User {
  id: string
  username: string
  type: string
  token: string
  mediaProgress: Progress[]
  seriesHideFromContinueListening: string[]
  bookmarks: string[]
  isActive: boolean
  isLocked: boolean
  lastSeen: number
  createdAt: number
  permissions: Permissions
  librariesAccessible: string[]
  itemTagsAccessible: string[]
}

export interface LibrarySettings {
  coverAspectRatio: number;
  disableWatcher: boolean;
  skipMatchingMediaWithAsin: boolean;
  skipMatchingMediaWithIsbn: boolean;
  autoScanCronExpression: string | null;
}

export interface Folder {
  id: string;
  fullPath: string;
  libraryId: string;
  addedAt?: number;
}

export interface Library {
  id: string;
  name: string;
  folders: Folder[];
  displayOrder: number;
  icon: string;
  mediaType: string;
  provider: string;
  settings: LibrarySettings;
  createdAt: number;
  lastUpdate: number;
}

export interface Metadata {
  title: string;
  titleIgnorePrefix: string;
  subtitle?: string | null;
  authorName?: string;
  authorNameLF?: string;
  narratorName?: string;
  seriesName?: string;
  genres: string[];
  publishedYear?: string;
  publishedDate?: string | null;
  publisher?: string | null;
  description: string;
  isbn?: string | null;
  asin?: string | null;
  language: string;
  explicit: boolean;
  abridged?: boolean;
  author?: string;
  authors?: Author[];
  narrators?: string[];
  releaseDate?: string;
  feedUrl?: string;
  imageUrl?: string;
  itunesPageUrl?: string;
  itunesId?: string;
  itunesArtistId?: string | null,
  type?: string;
}

export interface AudioFileMetadata {
  filename: string;
  ext: string;
  path: string;
  relPath: string;
  size: number;
  mtimeMs: number;
  ctimeMs: number;
  birthtimeMs: number;
}

export interface AudioFile {
  index: number;
  ino: string;
  metadata: AudioFileMetadata;
  addedAt: number;
  updatedAt: number;
  trackNumFromMeta: number | null;
  discNumFromMeta: number | null;
  trackNumFromFilename: number;
  discNumFromFilename: number | null;
  manuallyVerified: boolean;
  exclude: boolean;
  error: string | null;
  format: string;
  duration: number;
  bitRate: number;
  language: string;
  codec: string;
  timeBase: string;
  channels: number;
  channelLayout: string;
  chapters: string[];
  embeddedCoverArt: string | null;
  metaTags: Record<string, string>;
  mimeType: string;
}

export interface Chapter {
  id: number;
  start: number;
  end: number;
  title: string;
}

export interface Track {
  index: number;
  startOffset: number;
  duration: number;
  title: string;
  contentUrl: string;
  mimeType: string;
  codec: string;
  metadata: AudioFileMetadata;
}

export interface Media {
  id: string;
  libraryItemId: string;
  metadata: Metadata;
  coverPath: string;
  tags: string[];
  audioFiles?: AudioFile[];
  chapters?: Chapter[];
  episodes?: Episode[];
  duration: number;
  size: number;
  tracks: Track[];
  ebookFile: string | null;
}

export interface LibraryItem {
  id: string;
  ino: string;
  oldLibraryItemId?: string | null;
  libraryId: string;
  folderId: string;
  path: string;
  relPath: string;
  isFile: boolean;
  mtimeMs: number;
  ctimeMs: number;
  birthtimeMs: number;
  addedAt: number;
  updatedAt: number;
  isMissing: boolean;
  isInvalid: boolean;
  mediaType: string;
  media: Media;
  numFiles: number;
  size: number;
  episodes?: Episode[];
  recentEpisode?: Episode;
}

export interface Progress {
  id: string;
  libraryItemId: string;
  episodeId: string;
  duration: number;
  progress: number;
  currentTime: number;
  isFinished: boolean;
  hideFromContinueListening: boolean;
  lastUpdate: number;
  startedAt: number;
  finishedAt: number | null;
}

export interface UpdateProgress {
  duration: number;
  currentTime: number;
  progress: number;
  isFinished: boolean;
}

export interface UpdateSession {
  deviceInfo: DeviceInfo;
  mediaPlayer: string;
  currentTime: number;
  timeListened: number;
}

export interface PlayItem {
  id: string;
  userId: string;
  libraryId: string;
  libraryItemId: string;
  bookId: string | null;
  episodeId: string | null;
  mediaType: string;
  mediaMetadata: Metadata;
  chapters: Chapter[];
  displayTitle: string;
  displayAuthor: string;
  coverPath: string;
  duration: number;
  playMethod: number;
  mediaPlayer: string;
  deviceInfo: DeviceInfo;
  serverVersion: string;
  date: string;
  dayOfWeek: string;
  timeListening: number;
  startTime: number;
  currentTime: number;
  startedAt: number;
  updatedAt: number;
  audioTracks: Track[];
  videoTrack: string | null;
  libraryItem?: LibraryItem;
}

export interface DeviceInfo {
  id: string;
  userId: string;
  deviceName: string;
  clientVersion: string;
  clientName: string;
}

export interface PlayData {
  deviceInfo: DeviceInfo;
  forceDirectPlay: boolean;
  mediaPlayer?: string;
}

export interface Author {
  id: string;
  asin?: string | null;
  name: string;
  description?: string | null;
  imagePath?: string | null;
  addedAt?: number;
  updatedAt?: number;
  numBooks?: number;
}

export interface Narrator {
  name: string;
  numBooks: number;
}

export interface Book {
  id: string;
  ino: string;
  libraryId: string;
  folderId: string;
  path: string;
  relPath: string;
  isFile: boolean;
  mtimeMs: number;
  ctimeMs: number;
  birthtimeMs: number;
  addedAt: number;
  updatedAt: number;
  isMissing: boolean;
  isInvalid: boolean;
  mediaType: string;
  media: Media;
  numFiles: number;
  size: number;
  sequence: string;
}

export interface Book1 {
  id: string;
}

export interface Series {
  id: string;
  name: string;
  nameIgnorePrefix: string;
  nameIgnorePrefixSort: string;
  type: string;
  books: Book[];
  addedAt: number;
  totalDuration: number;
}

export interface Collection {
  id: string;
  libraryId: string;
  userId: string;
  name: string;
  description: string | null;
  books: Book[];
  lastUpdate: number;
  createdAt: number;
}

export interface Collection1 {
  libraryId: string;
  name: string;
  description?: string | null;
  books: string[];
}

export interface ListeningStats {
  totalTime: number;
  items: Record<string, ListeningStatsItem>;
  days: Record<string, number>;
  dayOfWeek: Record<string, number>;
  today: number;
  recentSessions: RecentSession[];
}

export interface ListeningStatsItem {
  id: string;
  timeListening: number;
  mediaMetadata: Metadata;
}

export interface RecentSession {
  id: string;
  userId: string;
  libraryId: string;
  libraryItemId: string;
  episodeId: string;
  mediaType: string;
  mediaMetadata: Metadata;
  chapters: Chapter[];
  displayTitle: string;
  displayAuthor: string;
  coverPath: string;
  duration: number;
  playMethod: number;
  mediaPlayer: string;
  deviceInfo: DeviceInfo;
  date: string;
  dayOfWeek: string;
  timeListening: number;
  startTime: number;
  currentTime: number;
  startedAt: number;
  updatedAt: number;
}

export interface Bookmark {
  libraryItemId: string;
  title: string;
  time: number;
  createdAt: number;
}

export interface SearchPodcast {
  id: number;
  artistId: number;
  title: string;
  artistName: string;
  description: string;
  descriptionPlain: string;
  releaseDate: string;
  genres: string[];
  cover: string;
  trackCount: number;
  feedUrl: string;
  pageUrl: string;
  explicit: boolean;
}

export interface Feed {
  podcast: Podcast;
}

export interface Podcast {
  metadata: PodcastMetadata;
  episodes: Episode[];
}

export interface PodcastMetadata {
  image: string;
  categories: string[];
  feedUrl: string;
  description: string;
  descriptionPlain: string;
  title: string;
  language: string;
  explicit: string;
  author: string;
  pubDate: string;
  link: string;
}

export interface Enclosure {
  url: string;
  type: string;
  length: string;
}

export interface RssFeed {
  rssFeed: string;
}

export interface Episode {
  libraryItemId?: string;
  id?: string;
  index?: number;
  season: string;
  episode: string;
  episodeType: string;
  title: string;
  subtitle: string;
  description: string;
  descriptionPlain?: string;
  enclosure: Enclosure;
  pubDate: string;
  audioFile?: AudioFile;
  audioTrack?: AudioTrack;
  publishedAt?: number;
  addedAt?: number;
  updatedAt?: number;
  duration: number;
  size?: number;
  podcast?: Podcast;
  author?: string;
}

export interface AudioMetadata {
  filename: string;
  ext: string;
  path: string;
  relPath: string;
  size: number;
  mtimeMs: number;
  ctimeMs: number;
  birthtimeMs: number;
}

export interface MetaTags {
  tagAlbum: string;
  tagArtist: string;
  tagGenre: string;
  tagTitle: string;
  tagDate: string;
  tagEncoder: string;
}

export interface AudioTrack {
  index: number;
  startOffset: number;
  duration: number;
  title: string;
  contentUrl: string;
  mimeType: string;
  metadata: AudioMetadata;
}

export interface PlaylistItem {
  libraryItemId: string;
  episodeId: string | null;
  libraryItem?: LibraryItem;
  episode?: Episode;
}

export interface Playlist {
  id?: string;
  libraryId: string;
  userId?: string;
  name: string;
  description?: string | null;
  coverPath?: string | null;
  items: PlaylistItem[];
  lastUpdate?: number;
  createdAt?: number;
}

export interface Response {
  results: LibraryItem[] | Series[] | Collection[] | Playlist[];
  total: number;
  limit: number;
  page: number;
}

export interface LibraryItemSearchResult {
  libraryItem: LibraryItem;
  matchKey?: string;
  matchText?: string;
}

export interface SearchResult {
  book?: LibraryItemSearchResult[];
  podcast?: LibraryItemSearchResult[];
  episodes?: LibraryItemSearchResult[];
  tags?: string[];
  genres?: string[];
  authors?: Author[];
  narrators?: Narrator[];
  series?: Series[];
}

export interface HomeSection {
  id: string;
  label: string;
  labelStringKey: string;
  type: "book" | "series" | "authors";
  entities: (LibraryItem | Series | Author)[];
  category: string;
}

export interface Filter1 {
  criteria: string;
  type: string;
}