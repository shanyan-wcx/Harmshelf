import request from '@ohos.request';
import common from '@ohos.app.ability.common';  // 假设这样拿 context 类型
import { BusinessError } from '@ohos.base';
import { fileUri, picker, fileIo as fs } from '@kit.CoreFileKit';

export enum DownloadStatus {
  Idle = 'Idle',
  Downloading = 'Downloading',
  Paused = 'Paused',
  Completed = 'Completed',
  Failed = 'Failed',
  Removed = 'Removed',
}

export interface DownloadTaskInfo {
  mediaType: string,
  folder: string,
  id: string;
  title: string;
  url: string;
  filePath: string;
  status: DownloadStatus;
  receivedSize: number;
  totalSize: number;
  error?: BusinessError;
  background?: boolean;
}

type ProgressCallback = (info: DownloadTaskInfo) => void;
type StatusCallback = (info: DownloadTaskInfo) => void;

interface InternalTask {
  info: DownloadTaskInfo;
  downloadTask?: request.DownloadTask;
  onProgress?: ProgressCallback;
  onStatusChange?: StatusCallback;
}

export class DownloadManager {
  private context: common.UIAbilityContext;
  private tasks: Map<string, InternalTask> = new Map();
  private activeDownloads: Set<string> = new Set(); // 正在下载的任务 id
  private MAX_CONCURRENT_DOWNLOADS = 1;

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
      receivedSize: 0,
      totalSize: 0,
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

      const downloadTask = await request.downloadFile(this.context, {
        url: task.info.url,
        filePath: task.info.filePath,
      });
      task.downloadTask = downloadTask;

      downloadTask.on('progress', (received: number, total: number) => {
        task.info.receivedSize = received;
        task.info.totalSize = total;
        task.onProgress?.(task.info);
      });

      const finishHandler = () => {
        this.activeDownloads.delete(id);
        this._checkQueue(); // 完成后检查队列启动新任务
      };

      const transferFile = () => {
        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD
        const documentViewPicker = new picker.DocumentViewPicker(this.context);
        documentViewPicker.save(documentSaveOptions)
          .then(async (documentSaveResult) => {
            let uri = documentSaveResult[0];
            let path: string = new fileUri.FileUri(uri).path
            let subPath = task.info.mediaType === 'book' ?  "/有声书" : "/播客"
            if (!fs.accessSync(path + subPath)) {
              fs.mkdirSync(path + subPath)
            }
            if (!fs.accessSync(path + subPath + "/" + task.info.folder)) {
              fs.mkdirSync(path + subPath + "/" + task.info.folder)
            }
            let filePath: string = path + task.info.filePath.slice(this.context.filesDir.length)
            let sanFile = fs.openSync(task.info.filePath, fs.OpenMode.READ_ONLY)
            let pubFile = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC)
            fs.copyFileSync(sanFile.fd, pubFile.fd)
            fs.closeSync(sanFile.fd)
            fs.closeSync(pubFile.fd)
            fs.unlinkSync(task.info.filePath);
          }).catch((err: Error) => {
          console.error(`调用documentPicker.select失败, message is ${err.message}`);
        })
      }

      downloadTask.on('complete', () => {
        task.info.status = DownloadStatus.Completed;
        task.onStatusChange?.(task.info);
        finishHandler();
        transferFile();
      });

      downloadTask.on('fail', (err: number | BusinessError) => {
        task.info.status = DownloadStatus.Failed;
        if (typeof err === 'object') {
          task.info.error = err;
        } else {
          task.info.error = {
            code: err as number,
            message: `Download failed with code ${err}`,
          } as BusinessError;
        }
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
      task.info.error = err as BusinessError;
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
      task.downloadTask.remove();
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
        task.downloadTask.remove();
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
          receivedSize: task.info.receivedSize,
          totalSize: task.info.totalSize,
          error: task.info.error,
          background: task.info.background
        };
        infos.push(info);
      }
    }
    return infos;
  }
}
