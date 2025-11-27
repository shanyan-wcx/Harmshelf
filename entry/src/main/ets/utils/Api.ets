import axios, { Axios, AxiosResponse, FormData } from '@ohos/axios'
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import {
  LoginInfo,
  LoginUser,
  Library,
  LibraryItem,
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
  Collection,
  Playlist,
  SearchResult,
  HomeSection,
  Episode,
  User,
  PlaylistItem,
  Collection1,
  Book1,
  Podcast,
  CreatePodcast,
  SearchPodcast
} from './Interface'
import { JSON, util } from '@kit.ArkTS';

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

export async function healthCheck() {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>>('/healthcheck', {
      timeout: 30000
    })
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function getLogin(loginInfo: LoginInfo): Promise<string[] | null> {
  let user: LoginUser = {
    username: loginInfo.username,
    password: loginInfo.password
  }
  baseUrl = loginInfo.server
  try {
    const response: AxiosResponse = await axios.post<string, AxiosResponse<string>, LoginUser>('/login', user, {
      baseURL: baseUrl,
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
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
      timeout: 30000
    })
    baseUrl = ""
    authToken = ""
    userId = ""
    console.log("退出登录！")
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function getUser(): Promise<User | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/me`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取用户失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function getHome(libraryId: string): Promise<HomeSection[]> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/personalized`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取首页失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function getLibraries(): Promise<Library[]> {
  let libraries: Library[] = []
  let libraryNames: string[] = []
  const api: Axios = createApi()
  try {
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>('/api/libraries', {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    console.log("获取媒体库成功！")

    libraries = response.data.libraries
    libraries.forEach(element => {
      libraryNames.push(element.name)
    });
    console.log("媒体库：", libraryNames)
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

export async function getLibraryItems(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items`, {
        params: { minified: true },
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    libraryItems = response.data.results
    libraryItems.forEach((element: LibraryItem) => {
      itemTitles.push(element.media.metadata.title)
    });
    console.log("项目：", itemTitles.toString());
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

export async function getLibraryItemsInProgress(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items?filter=progress.aW4tcHJvZ3Jlc3M%3D`,
        {
          params: { minified: true },
          timeout: 30000,
          readTimeout: 30000,
          connectTimeout: 30000
        })
    libraryItems = response.data.results
    libraryItems.forEach((element: LibraryItem) => {
      itemTitles.push(element.media.metadata.title)
    });
    console.log("进行中项目：", itemTitles.toString());
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

export async function getLibraryItemsFinished(libraryId: string): Promise<LibraryItem[]> {
  const api: Axios = createApi()
  let libraryItems: LibraryItem[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/items?filter=progress.ZmluaXNoZWQ%3D`,
        {
          params: { minified: true },
          timeout: 30000,
          readTimeout: 30000,
          connectTimeout: 30000
        })
    libraryItems = response.data.results
    libraryItems.forEach((element: LibraryItem) => {
      itemTitles.push(element.media.metadata.title)
    });
    console.log("已完成项目：", itemTitles.toString());
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

export async function getItem(itemId: string): Promise<LibraryItem | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/items/${itemId}?expanded=1`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取项目失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function getEpisode(itemId: string, EpisodeId: string): Promise<Episode | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/podcasts/${itemId}/episode/${EpisodeId}?expanded=1`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取项目失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function searchLibrary(libraryId: string, query: string): Promise<SearchResult | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/search?q=${query}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '搜索失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function getCover(itemId: string) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/items/${itemId}/cover`,
        {
          params: { responseType: 'arraybuffer' },
          timeout: 30000,
          readTimeout: 30000,
          connectTimeout: 30000
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

export async function getProgress(itemId: string, episodeId?: string): Promise<Progress | undefined> {
  const api: Axios = createApi()
  let progress: Progress | undefined = undefined
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/me/progress/${itemId}` + (episodeId ? `/${episodeId}` : ""), {
        timeout: 30000
      })
    console.log("手动获取项目进度：" + JSON.stringify(response))
    progress = response.data
    return progress
  } catch (error) {
    return progress
  }
}

export async function getPlayItem(itemId: string, episodeId?: string): Promise<PlayItem | undefined> {
  const api: Axios = createApi();
  let playItem: PlayItem | undefined = undefined
  let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
  let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags)
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, PlayData>(`/api/items/${itemId}/play` + (episodeId ? `/${episodeId}` : ""), {
        deviceInfo: {
          id: deviceInfo.displayVersion,
          userId: userId,
          deviceName: deviceInfo.marketName,
          clientName: "Harmshelf",
          clientVersion: bundleInfo.versionName
        },
        mediaPlayer: "avPlayer",
        forceDirectPlay: true
      }, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    playItem = response.data
    console.log("获取到播放项目", playItem?.libraryItemId)
    console.log("当前位置", playItem?.currentTime)
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取播放项目失败，请检查网络！',
      duration: 500
    });
  }
  return playItem
}

export async function updateProgress(progress: UpdateProgress, itemId: string, episodeId?: string) {
  let req = new rcp.Request(baseUrl + `/api/me/progress/${itemId}` + (episodeId ? `/${episodeId}` : ""), 'PATCH')
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
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/authors`, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
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
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/series?limit=99999999999`, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    series = response.data.results
    series.forEach((element: Series) => {
      itemTitles.push(element.name)
    });
    console.log("系列：", itemTitles.toString());
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
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/collections`, {
      timeout: 90000,
      readTimeout: 90000,
      connectTimeout: 90000
    })
    collections = response.data.results
    collections.forEach((element: Collection) => {
      itemTitles.push(element.name)
    });
    console.log("收藏：", itemTitles.toString());
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

export async function addToCollection(collectionId: string, bookId: string): Promise<Collection | undefined> {
  const api: Axios = createApi()
  let collection: Collection | undefined = undefined
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>, Book1>(`api/collections/${collectionId}/book`, {
      id: bookId
    }, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    collection = response.data
    console.log("添加成功");
    promptAction.showToast({
      message: '添加成功！',
      duration: 500
    });
    return collection
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '添加失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function removeFromCollection(collectionId: string, bookId: string): Promise<Collection | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/collections/${collectionId}/book/${bookId}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("移除成功");
    promptAction.showToast({
      message: '移除成功！',
      duration: 500
    });
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '移除失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function createCollection(collection: Collection1): Promise<Collection | undefined> {
  const api: Axios = createApi()
  let collection1: Collection | undefined = undefined
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>, Collection1>(`/api/collections`, collection, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    collection1 = response.data
    console.log("创建成功");
    return collection1
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function updateCollection(collectionId: string, name: string, description: string): Promise<Collection | undefined> {
  let collection: Collection | undefined = undefined
  let req = new rcp.Request(baseUrl + `/api/collections/${collectionId}`, 'PATCH')
  req.content = JSON.stringify({
    name: name,
    description: description.length > 0 ? description : null
  })
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
    if (response.body) {
      const decoder = new util.TextDecoder();
      const uint8Array = new Uint8Array(response.body);
      const bodyString = decoder.decodeWithStream(uint8Array);
      const parsed = JSON.parse(bodyString) as Collection;
      collection = parsed;
      console.log("更新成功");
    }
    return collection
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function deleteCollection(collectionId: string): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/collections/${collectionId}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("删除成功");
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function getPlaylists(libraryId: string): Promise<Playlist[]> {
  const api: Axios = createApi()
  let playlists: Playlist[] = []
  let itemTitles: string[] = []
  try {
    const response: AxiosResponse = await api.get<string, AxiosResponse<string>, null>(`/api/libraries/${libraryId}/playlists`, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    playlists = response.data.results
    playlists.forEach((element: Playlist) => {
      itemTitles.push(element.name)
    });
    console.log("播放列表：", itemTitles.toString());
    return playlists
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取收藏失败，请检查网络！',
      duration: 500
    });
    return []
  }
}

export async function addToPlaylist(playlistId: string, libraryItemId: string, episodeId?: string): Promise<Playlist | undefined> {
  const api: Axios = createApi()
  let playlist: Playlist | undefined = undefined
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>, PlaylistItem>(`/api/playlists/${playlistId}/item`, {
      libraryItemId: libraryItemId,
      episodeId: episodeId??null
    }, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    playlist = response.data
    console.log("添加成功");
    promptAction.showToast({
      message: '添加成功！',
      duration: 500
    });
    return playlist
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '添加失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function removeFromPlaylist(playlistId: string, libraryItemId: string, episodeId?: string): Promise<Playlist | undefined> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/playlists/${playlistId}/item/${libraryItemId}` + (episodeId ? `/${episodeId}` : ""), {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("移除成功");
    promptAction.showToast({
      message: '移除成功！',
      duration: 500
    });
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '移除失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function createPlaylist(playlist: Playlist): Promise<Playlist | undefined> {
  const api: Axios = createApi()
  let playlist1: Playlist | undefined = undefined
  try {
    const response: AxiosResponse = await api.post<string, AxiosResponse<string>, Playlist>(`/api/playlists`, playlist, {
      timeout: 30000,
      readTimeout: 30000,
      connectTimeout: 30000
    })
    playlist1 = response.data
    console.log("创建成功");
    return playlist1
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function updatePlaylist(playlistId: string, name: string, description: string): Promise<Playlist | undefined> {
  let playlist: Playlist | undefined = undefined
  let req = new rcp.Request(baseUrl + `/api/playlists/${playlistId}`, 'PATCH')
  req.content = JSON.stringify({
    name: name,
    description: description.length > 0 ? description : null
  })
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
    if (response.body) {
      const decoder = new util.TextDecoder();
      const uint8Array = new Uint8Array(response.body);
      const bodyString = decoder.decodeWithStream(uint8Array);
      const parsed = JSON.parse(bodyString) as Playlist;
      playlist = parsed;
      console.log("更新成功");
    }
    return playlist
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function deletePlaylist(playlistId: string): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/playlists/${playlistId}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("删除成功");
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function syncSession(sessionId: string, updateSession: UpdateSession): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, UpdateSession>(`api/session/${sessionId}/sync`, updateSession, {
        timeout: 5000,
        readTimeout: 5000,
        connectTimeout: 5000
      })
    console.log("同步会话", response.data);
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function closeSession(sessionId: string, updateSession: UpdateSession): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, UpdateSession>(`api/session/${sessionId}/close`, updateSession, {
        timeout: 5000,
        readTimeout: 5000,
        connectTimeout: 5000
      })
    console.log("关闭会话成功", response.data);
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '关闭会话失败，请检查网络！',
      duration: 500
    });
    return false
  }
}

export async function getStats(): Promise<ListeningStats | undefined> {
  let listeningStats: ListeningStats | undefined = undefined
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, UpdateSession>('/api/me/listening-stats', {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    listeningStats = response.data
    console.log("获取统计数据成功");
    return listeningStats
  } catch (error) {
    console.error(JSON.stringify(error));
    promptAction.showToast({
      message: '获取统计数据失败，请检查网络！',
      duration: 500
    });
    return undefined
  }
}

export async function getBookmarks(userId: string): Promise<Bookmark[]> {
  const api: Axios = createApi()
  let bookmarks: Bookmark[] = []
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/me`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
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

export async function createBookmark(itemId: string, bookmark: Bookmark): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, Bookmark>(`/api/me/item/${itemId}/bookmark`, bookmark, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("创建书签成功", JSON.stringify(response.data));
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function deleteBookmark(itemId: string, time: number): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/me/item/${itemId}/bookmark/${time}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("删除书签成功", JSON.stringify(response.data));
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function searchPodcasts(term: string) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>, null>(`/api/search/podcast?term=${encodeURIComponent(term)}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
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

export async function getFeed(feed: string): Promise<Podcast | undefined> {
  const api: Axios = createApi()
  let rssFeed: RssFeed = {
    rssFeed: feed
  }
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, RssFeed>(`/api/podcasts/feed`, rssFeed, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data.podcast
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function addPodcast(libraryId: string, folderId: string, path:string, searchPodcast: SearchPodcast, podcast: Podcast, autoDownload: boolean): Promise<Podcast | undefined> {
  const api: Axios = createApi()
  let data: CreatePodcast = {
    libraryId: libraryId,
    folderId: folderId,
    path: path,
    media: {
      metadata: {
        title: searchPodcast.title,
        author: searchPodcast.artistName,
        description: podcast.metadata.description,
        genres: searchPodcast.genres,
        feedUrl: searchPodcast.feedUrl,
        imageUrl: searchPodcast.cover,
        explicit: searchPodcast.explicit,
        language: podcast.metadata.language,
        itunesPageUrl: searchPodcast.pageUrl,
        itunesId: searchPodcast.id,
        itunesArtistId: searchPodcast.title,
        releaseDate: searchPodcast.releaseDate,
      },
      autoDownloadEpisodes: autoDownload
    },
    episodesToDownload: podcast.episodes
  }
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, CreatePodcast>(`/api/podcasts`, data, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return response.data
  } catch (error) {
    console.error(JSON.stringify(error));
    return undefined
  }
}

export async function getRecentEpisodes(libraryId: string, page: number) {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.get<string, AxiosResponse<string>>(`/api/libraries/${libraryId}/recent-episodes?limit=50&page=${page}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
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

export async function downloadEpisodes(podcastId: string, episodes: Episode[]): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.post<string, AxiosResponse<string>, Episode[]>(`/api/podcasts/${podcastId}/download-episodes`, episodes, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}

export async function deleteFromServer(podcastId: string, episodeId: string): Promise<boolean> {
  const api: Axios = createApi()
  try {
    const response: AxiosResponse =
      await api.delete<string, AxiosResponse<string>, null>(`/api/podcasts/${podcastId}/episode/${episodeId}`, {
        timeout: 30000,
        readTimeout: 30000,
        connectTimeout: 30000
      })
    console.log("删除剧集成功");
    return true
  } catch (error) {
    console.error(JSON.stringify(error));
    return false
  }
}