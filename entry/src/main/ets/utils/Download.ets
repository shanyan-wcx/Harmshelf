import request from '@ohos.request';
import common from '@ohos.app.ability.common';  // 假设这样拿 context 类型
import { BusinessError } from '@ohos.base';
import { fileUri, fileIo as fs } from '@kit.CoreFileKit';

export enum DownloadStatus {
  Idle = 'Idle',
  Downloading = 'Downloading',
  Paused = 'Paused',
  Completed = 'Completed',
  Failed = 'Failed',
  Removed = 'Removed',
}

export interface DownloadTaskInfo {
  mediaType: string;
  folder: string;
  id: string;
  title: string;
  url: string;
  filePath: string;
  status: DownloadStatus;
  progress: number;
  background?: boolean;
}

type ProgressCallback = (info: DownloadTaskInfo) => void;
type StatusCallback = (info: DownloadTaskInfo) => void;

interface InternalTask {
  info: DownloadTaskInfo;
  downloadTask?: request.agent.Task;
  onProgress?: ProgressCallback;
  onStatusChange?: StatusCallback;
}

export class DownloadManager {
  private context: common.UIAbilityContext;
  private tasks: Map<string, InternalTask> = new Map();
  private activeDownloads: Set<string> = new Set(); // 正在下载的任务 id
  private MAX_CONCURRENT_DOWNLOADS = 6;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // 添加任务
  add(
    mediaType: string,
    folder: string,
    id: string,
    title: string,
    url: string,
    filePath: string,
    onProgress?: ProgressCallback,
    onStatusChange?: StatusCallback
  ): void {
    if (this.tasks.has(id)) {
      console.log(`任务 ${id} 已存在`);
      return;
    }
    const info: DownloadTaskInfo = {
      mediaType,
      folder,
      id,
      title,
      url,
      filePath,
      status: DownloadStatus.Idle,
      progress: 0,
      background: true,
    };
    this.tasks.set(id, { info, onProgress, onStatusChange });
    this._checkQueue(); // 尝试启动下载
  }

  // 内部：检查等待队列并启动下载
  private async _checkQueue(): Promise<void> {
    if (this.activeDownloads.size >= this.MAX_CONCURRENT_DOWNLOADS) return;

    const keyIterator = this.tasks.keys(); // 返回 IterableIterator<string>
    while (true) {
      const next = keyIterator.next();
      if (next.done) {
        break;
      }
      const id = next.value;
      const task = this.tasks.get(id);
      if (task != undefined) {
        if (this.activeDownloads.size >= this.MAX_CONCURRENT_DOWNLOADS) break;
        if (
          task.info.status === DownloadStatus.Idle ||
            task.info.status === DownloadStatus.Paused ||
            task.info.status === DownloadStatus.Failed
        ) {
          await this._startDownload(task);
        }
      }
    }
  }

  // 内部：启动下载任务
  private async _startDownload(task: InternalTask): Promise<void> {
    const id = task.info.id;
    if (this.activeDownloads.has(id)) return;

    try {
      task.info.status = DownloadStatus.Downloading;
      task.onStatusChange?.(task.info);
      this.activeDownloads.add(id);

      const file = fs.openSync(task.info.filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.closeSync(file.fd);
      let config: request.agent.Config = {
        action: request.agent.Action.DOWNLOAD,
        url: task.info.url,
        saveas: fileUri.getUriFromPath(task.info.filePath),
        gauge: true,
        overwrite: true,
        network: request.agent.Network.ANY,
        mode: request.agent.Mode.FOREGROUND,
      };

      const downloadTask = await request.agent.create(this.context!, config)
      downloadTask.start((err: BusinessError) => {
        if (err) {
          console.error(`Failed to start the download task, Code: ${err.code}  message: ${err.message}`);
          return;
        }
      });
      task.downloadTask = downloadTask;

      downloadTask.on('progress', async (progress) => {
        task.info.progress = progress.processed / progress.sizes[0] * 100;
        task.onProgress?.(task.info);
      });

      const finishHandler = () => {
        this.activeDownloads.delete(id);
        this.tasks.delete(id);
        this._checkQueue(); // 完成后检查队列启动新任务
      };

      downloadTask.on('completed', async (progress) => {
        task.info.status = DownloadStatus.Completed;
        request.agent.remove(downloadTask.tid);
        task.onStatusChange?.(task.info);
        finishHandler();
      });

      downloadTask.on('failed', () => {
        task.info.status = DownloadStatus.Failed;
        task.onStatusChange?.(task.info);
        finishHandler();
      });

      downloadTask.on('pause', () => {
        task.info.status = DownloadStatus.Paused;
        task.onStatusChange?.(task.info);
        finishHandler();
      });

      downloadTask.on('remove', () => {
        task.info.status = DownloadStatus.Removed;
        task.onStatusChange?.(task.info);
        finishHandler();
      });
    } catch (err) {
      task.info.status = DownloadStatus.Failed;
      task.onStatusChange?.(task.info);
      this.activeDownloads.delete(id);
      this._checkQueue();
    }
  }

  // 暂停单个任务
  pause(id: string): void {
    const task = this.tasks.get(id);
    if (!task) return;
    task.downloadTask?.pause();
  }

  // 恢复单个任务
  async resume(id: string): Promise<void> {
    const task = this.tasks.get(id);
    if (!task) return;

    if (task.info.status === DownloadStatus.Downloading) return;

    await this._checkQueue();
  }

  // 暂停全部
  pauseAll(): void {
    for (const task of this.tasks.values()) {
      if (task.info.status === DownloadStatus.Downloading) {
        task.downloadTask?.pause();
      }
    }
  }

  // 恢复全部
  async resumeAll(): Promise<void> {
    await this._checkQueue();
  }

  // 删除单个任务
  remove(id: string): void {
    const task = this.tasks.get(id);
    if (!task) {
      console.log(`不存在任务 ${id}`);
      return;
    }

    if (task.downloadTask) {
      request.agent.remove(task.downloadTask.tid);
    }

    this.activeDownloads.delete(id);
    this.tasks.delete(id);

    this._checkQueue();
  }

  // 清除所有任务
  clearAll(): void {
    for (const id of Array.from(this.tasks.keys())) {
      const task = this.tasks.get(id);
      if (task?.downloadTask) {
        request.agent.remove(task.downloadTask.tid);
      }
      this.activeDownloads.delete(id);
      this.tasks.delete(id);
    }
    this._checkQueue();
  }

  // 查询单个任务状态
  getTaskInfo(id: string): DownloadTaskInfo | undefined {
    const task = this.tasks.get(id);
    return task?.info;
  }

  // 查询所有任务状态
  getAllTaskInfo(): DownloadTaskInfo[] {
    const infos: DownloadTaskInfo[] = [];
    const keyIterator = this.tasks.keys(); // 返回 IterableIterator<string>
    while (true) {
      const next = keyIterator.next();
      if (next.done) {
        break;
      }
      const id = next.value;
      const task = this.tasks.get(id);
      if (task != undefined) {
        const info: DownloadTaskInfo = {
          mediaType: task.info.mediaType,
          folder: task.info.folder,
          id: task.info.id,
          title: task.info.title,
          url: task.info.url,
          filePath: task.info.filePath,
          status: task.info.status,
          progress: task.info.progress,
          background: task.info.background
        };
        infos.push(info);
      }
    }
    return infos;
  }
}
