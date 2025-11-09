import { AbilityConstant, appRecovery, Configuration, ConfigurationConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { env } from '../utils/Class';
import app, { AppResponse } from '@system.app';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

let callback: errorManager.ErrorObserver = {
  onUnhandledException(errMsg) {
    console.log(errMsg);
    appRecovery.saveAppState();
    appRecovery.restartApp();
  }
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    env.colorMode = this.context.config.colorMode;
    app.setImageFileCacheSize(256 * 1024 * 1024);
    appRecovery.enableAppRecovery(appRecovery.RestartFlag.ALWAYS_RESTART,
      appRecovery.SaveOccasionFlag.SAVE_WHEN_ERROR | appRecovery.SaveOccasionFlag.SAVE_WHEN_BACKGROUND,
      appRecovery.SaveModeFlag.SAVE_WITH_FILE);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    errorManager.on('error', callback);

    windowStage.setWindowRectAutoSave(true, true);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      windowStage.getMainWindow().then((data: window.Window) => {
        data.setWindowLayoutFullScreen(true)
        let deviceTypeInfo: string = deviceInfo.deviceType;
        if (deviceTypeInfo === '2in1') {
          data.setWindowDecorVisible(false);
          data.setWindowDecorHeight(55);
          data.setDecorButtonStyle({
            buttonBackgroundSize: 40,
            spacingBetweenButtons: 12,
            closeButtonRightMargin: 10
          });
        }
        data.setWindowSystemBarEnable(["status"]);
        data.setWindowSystemBarProperties({
          statusBarColor: "#00000000"
        })

        let orientation = window.Orientation.AUTO_ROTATION_UNSPECIFIED;
        try {
          data.setPreferredOrientation(orientation).then(() => {
            console.info('Succeeded in setting the window orientation.');
          }).catch((err: BusinessError) => {
            console.error(`Failed to set the window orientation. Cause code: ${err.code}, message: ${err.message}`);
          });
        } catch (exception) {
          console.error(`Failed to set window orientation. Cause code: ${exception.code}, message: ${exception.message}`);
        }
      })
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  async onConfigurationUpdate(newConfig: Configuration) {
    env.colorMode = newConfig.colorMode;
    let mainWindow = await window.getLastWindow(this.context)
    if (env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: '#FFFFFF',
      })
    } else {
      mainWindow.setWindowSystemBarProperties({
        statusBarContentColor: '#000000',
      })
    }
  }
}