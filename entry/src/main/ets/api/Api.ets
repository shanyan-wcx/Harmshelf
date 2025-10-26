import axios, { Axios, AxiosResponse } from '@ohos/axios'
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import {
  LoginInfo,
  User,
  Library,
  LibraryItem,
  Chapter,
  Progress,
  PlayItem,
  PlayData,
  UpdateProgress,
  Author,
  Series,
  UpdateSession,
  ListeningStats,
  Bookmark,
  RssFeed,
  Collection
} from './Interface'
import { JSON } from '@kit.ArkTS';

axios.defaults.headers.post['Content-Type'] = 'application/json'

let authToken: string = ""
let userId: string = ""
let baseUrl = ""

const session = rcp.createSession();

function createApi() {
  const api: Axios = axios.create({
    baseURL: baseUrl,
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    }
  });
  return api
}

export async function getLogin(loginInfo: LoginInfo): Promise<string[] | null> {
  let user: User = {
    username: loginInfo.username,
    password: loginInfo.password
  }
  baseUrl = loginInfo.server
  try {
    const response: AxiosResponse = await axios.post<string, AxiosResponse<string>, User>('/login', user, {
      baseURL: baseUrl,
      timeout: 10000
    })
    authToken = response.data.user.token
    userId = response.data.user.id
    console.log("Token", authToken);
    return [authToken, userId]
  } catch (error) {
    console.error(JSON.stringify(error));
    return null
  }
}

export async function getLogout() {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>>('/logout', {
      timeout: 10000
    })
    console.log("退出登录！")
  } catch (error) {
    console.error(JSON.stringify(error));
  }
}

export async function getLibraries(): Promise<Library[]> {
  let libraries: Library[] = []
  let libraryNames: string[] = []
  const api: Axios = createApi()
  try {
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>('/api/libraries', {
      timeout: 10000
    })
    console.log("获取媒体库成功！")

    libraries = response.data.libraries
    //   .filter((item: Library) => {
    //   return item.mediaType === "book";
    // });
    libraries.forEach(element => {
      libraryNames.push(element.name)
    });
    console.log("媒体库", libraryNames)
  } catch (error) {
    console.log("获取媒体库失败！")
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取媒体库失败，请检查网络！',
      duration: 500
    });
  }
  return libraries
}

export async function getLibrarieItems(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items`, {
        params: { minified: true },
        timeout: 10000
      })
    response.data.results.forEach((element: LibraryItem) => {
      libraryItems.push(element)
      itemTitles.push(element.media.metadata.title)
    });
    console.log("项目", itemTitles.toString());
    return libraryItems
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取媒体库内容失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getLibrarieItemsInProgress(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items?filter=progress.aW4tcHJvZ3Jlc3M%3D`,
        {
          params: { minified: true },
          timeout: 50000,
          readTimeout: 10000
        })
    response.data.results.forEach((element: LibraryItem) => {
      libraryItems.push(element)
      itemTitles.push(element.media.metadata.title)
    });
    console.log("进行中项目", itemTitles.toString());
    return libraryItems
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取进行中项目失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getLibrarieItemsFinished(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items?filter=progress.ZmluaXNoZWQ%3D`,
        {
          params: { minified: true },
          timeout: 50000,
          readTimeout: 10000
        })
    response.data.results.forEach((element: LibraryItem) => {
      libraryItems.push(element)
      itemTitles.push(element.media.metadata.title)
    });
    console.log("已完成项目", itemTitles.toString());
    return libraryItems
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取已完成项目失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getItem(itemId: string): Promise<Chapter[]> {
  const api: Axios = createApi()
  let chapters: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/items/${itemId}`, {
        timeout: 10000
      })
    response.data.media.chapters.forEach((element: Chapter) => {
      chapters.push(element.title)
    });
    console.log("Chapters:", chapters);
    return response.data.media.chapters
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取章节失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getCover(itemId: string) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/items/${itemId}/cover?format=jpeg&width=1024`,
        {
          params: { responseType: 'arraybuffer' },
          timeout: 10000
        })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取封面失败，请检查网络！',
      duration: 500
    });
  }
}

export async function getProgress(itemId: string): Promise<Progress> {
  const api: Axios = createApi()
  let progress: Progress = {
    id: '',
    libraryItemId: itemId,
    episodeId: '',
    duration: 0,
    progress: 0,
    currentTime: 0,
    isFinished: false,
    hideFromContinueListening: false,
    lastUpdate: 0,
    startedAt: 0,
    finishedAt: null
  }
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/me/progress/${itemId}`, {
        timeout: 10000
      })
    progress = response.data
    return progress
  } catch (error) {
    progress.libraryItemId = itemId
    return progress
  }
}

export async function getPlayItem(itemId: string): Promise<PlayItem> {
  const api: Axios = createApi();
  let playItem: PlayItem = {
    id: '',
    userId: '',
    libraryId: '',
    libraryItemId: itemId,
    bookId: '',
    episodeId: null,
    mediaType: '',
    metadata: {
      title: '',
      titleIgnorePrefix: '',
      subtitle: null,
      authorName: '',
      authorNameLF: '',
      narratorName: '',
      seriesName: '',
      genres: [],
      publishedYear: '',
      publishedDate: null,
      publisher: null,
      description: '',
      isbn: null,
      asin: null,
      language: '',
      explicit: false,
      abridged: false,
    },
    chapters: [],
    displayTitle: '',
    displayAuthor: '',
    coverPath: '',
    duration: 0,
    playMethod: 0,
    mediaPlayer: '',
    deviceInfo: {
      id: '',
      userId: '',
      deviceName: '',
      clientVersion: '',
      clientName: '',
    },
    serverVersion: '',
    date: '',
    dayOfWeek: '',
    timeListening: 0,
    startTime: 0,
    currentTime: 0,
    startedAt: 0,
    updatedAt: 0,
    audioTracks: [],
    videoTrack: null
  }
  let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
  let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, PlayData>(`/api/items/${itemId}/play`, {
        deviceInfo: {
          id: '00000000',
          userId: userId,
          deviceName: deviceInfo.productModel,
          clientName: 'Abs-HarmonyOS',
          clientVersion: bundleInfo.versionName
        },
        forceDirectPlay: true
      }, {
        timeout: 10000
      })
    playItem = response.data
    console.log("获取到播放项目", playItem.libraryItemId)
    console.log("当前位置", playItem.currentTime)
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取播放项目失败，请检查网络！',
      duration: 500
    });
  }
  return playItem
}

export async function updateProgress(itemId: string, progress: UpdateProgress) {
  let req = new rcp.Request(baseUrl + `/api/me/progress/${itemId}`, 'PATCH')
  req.content = JSON.stringify(progress)
  req.headers = {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json'
  }
  const timeout: rcp.Timeout = {
    inactivityMs: 500,
  };
  req.configuration = {
    transfer: {
      timeout: timeout,
    }
  };
  try {
    const response: rcp.Response = await session.fetch(req)
    console.log("上传进度", response);
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function getAuthors(libraryId: string): Promise<Author[]> {
  const api: Axios = createApi()
  let authors: Author[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/authors`, {
        timeout: 10000
      })
    authors = response.data.authors
    return authors
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取作者失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getSeries(libraryId: string): Promise<Series[]> {
  const api: Axios = createApi()
  let series: Series[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/series`, {
        params: { limit: 99999 },
        timeout: 10000
      })
    series = response.data.results
    return series
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取系列失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getCollections(libraryId: string): Promise<Collection[]> {
  const api: Axios = createApi()
  let collections: Collection[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/collections`, {
        params: { limit: 99999 },
        timeout: 10000
      })
    collections = response.data.results
    return collections
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取收藏失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function syncSession(sessionId: string, updateSession: UpdateSession) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, UpdateSession>(`api/session/${sessionId}/sync`, updateSession, {
        timeout: 500
      })
    console.log("同步会话", response.data);
  } catch (error) {
    console.error(JSON.stringify(error));
  }
}

export async function closeSession(sessionId: string, updateSession: UpdateSession) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, UpdateSession>(`api/session/${sessionId}/close`, updateSession)
    console.log("关闭会话成功", response.data);
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '关闭会话失败，请检查网络！',
      duration: 500
    });
  }
}

export async function getStats(): Promise<ListeningStats> {
  let listeningStats: ListeningStats = {
    totalTime: 0,
    items: {},
    days: {},
    dayOfWeek: {},
    today: 0,
    recentSessions: []
  }
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, UpdateSession>('/api/me/listening-stats')
    listeningStats = response.data
    console.log("获取统计数据成功");
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取统计数据失败，请检查网络！',
      duration: 500
    });
  }
  return listeningStats
}

export async function getBookmarks(userId: string): Promise<Bookmark[]> {
  const api: Axios = createApi()
  let bookmarks: Bookmark[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/users/${userId}`)
    bookmarks = response.data.bookmarks
    return bookmarks
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取书签失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function createBookmark(itemId: string, bookmark: Bookmark) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, Bookmark>(`/api/me/item/${itemId}/bookmark`, bookmark)
    console.log("创建书签成功", JSON.stringify(response.data));
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '创建书签失败，请检查网络！',
      duration: 500
    });
  }
}

export async function deleteBookmark(itemId: string, time: number) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/me/item/${itemId}/bookmark/${time}`)
    console.log("删除书签成功", JSON.stringify(response.data));
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '删除书签失败，请检查网络！',
      duration: 500
    });
  }
}

export async function searchPodcasts(term: string) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>>(`api/search/podcast?term=${term}`)
    console.log("搜索播客成功，共" + response.data.length + "个结果");
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '搜索播客失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getFeed(feed: string) {
  const api: Axios = createApi()
  let rssFeed: RssFeed = {
    rssFeed: feed
  }
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, RssFeed>(`/api/podcasts/feed`, rssFeed)
    return response.data.podcast.episodes
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取剧集失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getRecentEpisodes(libraryId: string) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>>(`/api/libraries/${libraryId}/recent-episodes?limit=100`)
    return response.data.episodes
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取最新剧集失败，请检查网络！',
      duration: 500
    });
    return []
  }
}