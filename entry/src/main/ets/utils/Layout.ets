import { deviceInfo } from '@kit.BasicServicesKit';

// Keep 75vp as the mobile bottom-content avoidance baseline; include the 16vp floating bottom margin.
export const MOBILE_BOTTOM_TAB_BAR_HEIGHT: number = 75;
export const MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN: number = 16;
const MOBILE_BOTTOM_TAB_INSET: number =
  MOBILE_BOTTOM_TAB_BAR_HEIGHT + MOBILE_BOTTOM_TAB_BAR_BOTTOM_MARGIN;

function isBottomTabDevice(): boolean {
  return deviceInfo.deviceType === 'phone' || deviceInfo.deviceType === 'tablet';
}

export function getBottomContentInset(unplayedInset: number, isStartPlaying: boolean = false,
  playingInset: number = unplayedInset, hasBottomTab: boolean = true): number {
  if (isBottomTabDevice()) {
    return hasBottomTab ? Math.max(MOBILE_BOTTOM_TAB_INSET, unplayedInset) : unplayedInset;
  }
  return isStartPlaying ? playingInset : unplayedInset;
}
