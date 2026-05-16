import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    Logger.debug('onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    Logger.debug('onRestore ok ' + JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}