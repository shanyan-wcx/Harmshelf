# 鸿蒙面板标题颜色调研

## 结论

本地 API 26 SDK 的 `SheetTitleOptions` 仅声明：

- `title: ResourceStr`
- `subtitle?: ResourceStr`

没有标题字体颜色字段。`SheetOptions.title` 的类型是 `SheetTitleOptions | CustomBuilder`，因此可以使用自定义 builder 绘制标题并调用 `Text.fontColor()`。

`TextInput` 同时支持 `fontColor(ResourceColor)` 和 `placeholderColor(ResourceColor)`，可分别绑定播放页主色和次级色。

## 依据

- SDK：`C:/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/ets/component/common.d.ts`
- 鸿蒙文档：半模态转场 `SheetOptions.title` 及 `SheetTitleOptions` 说明；`bindSheet` 支持 `title: CustomBuilder`。
- 项目现状：`entry/src/main/ets/pages/Play.ets` 已有 `playColorPalette.primary/secondary`，播放页标题、时间、控件 symbol 和 slider 已使用该调色板。
