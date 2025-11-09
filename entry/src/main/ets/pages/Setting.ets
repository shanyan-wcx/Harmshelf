import { common, ConfigurationConstant } from "@kit.AbilityKit"
import { PersistenceV2 } from "@kit.ArkUI";
import { ColorMode, PlaySetting, ServerIndex, ServerSetting } from "../pages/Index";
import { getLibraries, getLogin, getUser } from "../utils/Api";
import { env } from "../utils/Class";
import { Library, LoginInfo, User } from "../utils/Interface";

@ComponentV2
export struct Setting {
  @Consumer() selectThemeIndex: number = 0
  @Consumer() serverIndex: ServerIndex | undefined = PersistenceV2.connect(ServerIndex, () => new ServerIndex());
  @Consumer() serverSetting: ServerSetting | undefined = PersistenceV2.connect(ServerSetting, () => new ServerSetting());
  @Consumer() colorMode: ColorMode | undefined = PersistenceV2.connect(ColorMode, () => new ColorMode());
  @Consumer() playSetting: PlaySetting | undefined = PersistenceV2.connect(PlaySetting, () => new PlaySetting());
  @Consumer() themeIcon: Resource = $r('sys.symbol.circle_righthalf_inset_filled')
  @Consumer() gobackwardIcon: Resource = $r('sys.symbol.gobackward_10')
  @Consumer() goforwardIcon: Resource = $r('sys.symbol.goforward_10')
  @Consumer() context: common.UIAbilityContext | undefined = undefined
  @Consumer() serverName: string = ""
  @Consumer() baseUrl: string = ""
  @Consumer() username: string = ""
  @Consumer() password: string = ""
  @Consumer() libraries: Library[] = []
  @Consumer() library: Library | undefined = undefined
  @Consumer() selectLibraryIndex: number = 0
  @Consumer() selectOptions: SelectOption[] = []
  @Consumer() user: User | undefined = undefined
  @Consumer() isConnect: boolean = false
  @Consumer() isStartPlaying: boolean = false
  @Local showProgress:boolean = false
  @Local showAddServer: boolean = false
  @Local showEditServer: boolean = false
  @Local editServerIndex: number = -1
  @Local tmpServername: string = ""
  @Local tmpBaseurl: string = ""
  @Local tmpUrl: string = ""
  @Local tmpUsername: string = ""
  @Local tmpPassword: string = ""
  @Local urlHeadIdx: number = 0
  @Local urlHead: string[] = ["http://", "https://"]
  @Local themes: SelectOption[] = [{
    value: "跟随系统"
  }, {
    value: "明亮模式"
  }, {
    value: "黑暗模式"
  }]

  @Builder
  AddServerBuilder() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            Text("名称")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: '服务器名称'
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.Normal)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpServername = value
              })
          }
          .width('100%')

          Row() {
            Text("服务器")
              .width(60)
              .fontSize(20)
            Select([{ value: this.urlHead[0] }, { value: this.urlHead[1] }])
              .value(this.urlHead[0])
              .selected(0)
              .zIndex(999)
              .backgroundColor($r('app.color.textInput'))
              .onSelect((index) => {
                this.urlHeadIdx = index
              })
              .font({
                size: 20,
                weight: FontWeight.Normal
              })
              .height(40)
              .borderRadius(8)
              .margin({ left: 15 })
              .optionWidth(80)
            TextInput({
              placeholder: 'server-url'
            })
              .width("100%")
              .height(40)
              .offset({
                x: -20
              })
              .padding({ left: 22 })
              .margin({ right: -20 })
              .layoutWeight(1)
              .borderRadius(8)
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.URL)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpUrl = value
              })
          }
          .width('100%')
          .margin({ top: 20 })

          Row() {
            Text("账号")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: 'username'
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.USER_NAME)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpUsername = value
              })
          }
          .width('100%')
          .margin({ top: 20 })

          Row() {
            Text("密码")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: 'password'
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.Password)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpPassword = value
              })
          }
          .width('100%')
          .margin({ top: 20, bottom: 20 })

          Button({ type: ButtonType.Normal }) {
            Text("保存")
              .fontSize(20)
          }
          .width('100%')
          .height(50)
          .borderRadius(8)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(8)
          .onClick(async () => {
            if (this.tmpUrl === "") {
              this.getUIContext().getPromptAction().showToast({
                message: '服务器地址不能为空！',
                duration: 500
              });
            } else {
              this.showProgress = true
              this.tmpBaseurl = this.urlHead[this.urlHeadIdx] + this.tmpUrl
              let loginInfo: LoginInfo = {
                name: this.tmpServername,
                server: this.tmpBaseurl,
                username: this.tmpUsername,
                password: this.tmpPassword
              }
              let info = await getLogin(loginInfo)
              if (info !== null) {
                this.serverSetting!.loginInfos.push(loginInfo)
                this.showProgress = false
                this.showAddServer = false
                this.getUIContext().getPromptAction().showToast({
                  message: '添加服务器成功！',
                  duration: 500
                });
              } else {
                this.showProgress = false
                this.getUIContext().getPromptAction().showToast({
                  message: '连接服务器失败！',
                  duration: 500
                });
              }
            }
          })
        }
        .padding({ left: 20, right: 20, bottom: 25 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Column(){
        LoadingProgress()
          .width("100%")
          .height(72)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })
      .justifyContent(FlexAlign.Center)
      .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  EditServerBuilder() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            Text("名称")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: '服务器名称',
              text: this.tmpServername
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.Normal)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpServername = value
              })
          }
          .width('100%')

          Row() {
            Text("服务器")
              .width(60)
              .fontSize(20)
            Select([{ value: this.urlHead[0] }, { value: this.urlHead[1] }])
              .value(this.urlHead[0])
              .selected(0)
              .zIndex(999)
              .backgroundColor($r('app.color.textInput'))
              .onSelect((index) => {
                this.urlHeadIdx = index
              })
              .font({
                size: 20,
                weight: FontWeight.Normal
              })
              .height(40)
              .borderRadius(8)
              .margin({ left: 15 })
              .optionWidth(80)
            TextInput({
              placeholder: 'server-url',
              text: this.tmpUrl
            })
              .width("100%")
              .height(40)
              .offset({
                x: -20
              })
              .padding({ left: 22 })
              .margin({ right: -20 })
              .layoutWeight(1)
              .borderRadius(8)
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.URL)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpUrl = value
              })
          }
          .width('100%')
          .margin({ top: 20 })

          Row() {
            Text("账号")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: 'username',
              text: this.tmpUsername
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.USER_NAME)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpUsername = value
              })
          }
          .width('100%')
          .margin({ top: 20 })

          Row() {
            Text("密码")
              .width(60)
              .fontSize(20)
            TextInput({
              placeholder: 'password',
              text: this.tmpPassword
            })
              .width("100%")
              .height(40)
              .layoutWeight(1)
              .borderRadius(8)
              .margin({ left: 15 })
              .caretColor($r('sys.color.font_secondary'))
              .fontSize(20)
              .placeholderFont({
                size: 20
              })
              .type(InputType.Password)
              .enterKeyType(EnterKeyType.Next)
              .onChange((value) => {
                this.tmpPassword = value
              })
          }
          .width('100%')
          .margin({ top: 20, bottom: 20 })

          Row({ space: 20 }) {
            Button({ type: ButtonType.Normal }) {
              Text("保存")
                .fontSize(20)
            }
            .width('50%')
            .layoutWeight(1)
            .height(50)
            .borderRadius(8)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
            .onClick(async () => {
              if (this.tmpUrl === "") {
                this.getUIContext().getPromptAction().showToast({
                  message: '服务器地址不能为空！',
                  duration: 500
                });
              } else {
                this.showProgress = true
                this.tmpBaseurl = this.urlHead[this.urlHeadIdx] + this.tmpUrl
                let loginInfo: LoginInfo = {
                  name: this.tmpServername,
                  server: this.tmpBaseurl,
                  username: this.tmpUsername,
                  password: this.tmpPassword
                }
                let info = await getLogin(loginInfo)
                if (info !== null) {
                  this.serverSetting!.loginInfos[this.editServerIndex] = loginInfo
                  this.isConnect = true
                  this.serverName = loginInfo.name
                  this.baseUrl = loginInfo.server
                  this.username = loginInfo.username
                  this.password = loginInfo.password
                  this.libraries = await getLibraries()
                  this.selectOptions = []
                  if (this.libraries.length > 0) {
                    this.library =
                      this.library ? this.libraries.find(library => library.id === this.library!.id) : this.libraries[0]
                    this.libraries.forEach((library, index) => {
                      this.selectOptions.push({ value: library.name })
                    })
                    this.selectLibraryIndex = this.libraries.findIndex(library => library.id === this.library!.id)
                  }
                  this.user = await getUser()
                  this.showProgress = false
                  this.showEditServer = false
                  this.getUIContext().getPromptAction().showToast({
                    message: '编辑服务器成功！',
                    duration: 500
                  });
                } else {
                  this.showProgress = false
                  this.getUIContext().getPromptAction().showToast({
                    message: '连接服务器失败！',
                    duration: 500
                  });
                }
              }
            })

            Button({ type: ButtonType.Normal }) {
              Text("删除")
                .fontSize(20)
            }
            .width('50%')
            .layoutWeight(1)
            .height(50)
            .borderRadius(8)
            .backgroundColor($r('sys.color.warning'))
            .borderRadius(8)
            .onClick(async () => {
              if (this.editServerIndex !== this.serverIndex?.serverIndex) {
                this.serverSetting!.loginInfos.splice(this.editServerIndex, 1)
                this.showEditServer = false
                this.getUIContext().getPromptAction().showToast({
                  message: '删除服务器成功！',
                  duration: 500
                });
              } else {
                this.getUIContext().getPromptAction().showToast({
                  message: '无法删除选中的服务器！',
                  duration: 500
                });
              }
            })
          }
        }
        .padding({ left: 20, right: 20, bottom: 25 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Column(){
        LoadingProgress()
          .width("100%")
          .height(72)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })
      .justifyContent(FlexAlign.Center)
      .visibility(this.showProgress ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear() {
    if (this.baseUrl === "") {
      this.showAddServer = true
    }
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Text("服务器设置")
            .width('100%')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 20, right: 20 })
            .margin({ top: 20, bottom: 5 })
            .textAlign(TextAlign.Center)

          ForEach(this.serverSetting?.loginInfos, (loginInfo: LoginInfo, index) => {
            Row() {
              Button({ type: ButtonType.Normal }) {
                Row() {
                  Radio({ value: loginInfo.server, group: 'url', indicatorType: RadioIndicatorType.TICK })
                    .width(20)
                    .checked(this.serverIndex?.serverIndex === index)
                    .radioStyle({
                      checkedBackgroundColor: $r('sys.color.comp_emphasize_secondary'),
                      indicatorColor: $r('app.color.start_window_background')
                    })
                  Text(loginInfo.name !== "" ? loginInfo.name : loginInfo.server)
                    .width('100%')
                    .layoutWeight(1)
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .margin({ left: 5 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .wordBreak(WordBreak.BREAK_ALL)
                }
                .width('100%')
              }
              .height(40)
              .width('100%')
              .layoutWeight(1)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .backgroundColor(Color.Transparent)
              .hitTestBehavior(HitTestMode.Block)
              .onClick(async () => {
                if (this.serverIndex && this.serverSetting) {
                  if (index === this.serverIndex.serverIndex){
                    this.serverIndex.serverIndex = -1
                    this.serverName = ""
                    this.baseUrl = ""
                    this.username = ""
                    this.password = ""
                    this.libraries = []
                    this.library = undefined
                    this.selectOptions = []
                    this.user = undefined
                    this.isConnect = false
                  } else {
                    let info = await getLogin({
                      name: this.serverSetting.loginInfos[index].name,
                      server: this.serverSetting.loginInfos[index].server,
                      username: this.serverSetting.loginInfos[index].username,
                      password: this.serverSetting.loginInfos[index].password
                    })
                    if (info !== null) {
                      this.isConnect = true
                      this.serverIndex.serverIndex = index
                      this.serverName = this.serverSetting.loginInfos[index].name
                      this.baseUrl = this.serverSetting.loginInfos[index].server
                      this.username = this.serverSetting.loginInfos[index].username
                      this.password = this.serverSetting.loginInfos[index].password
                      this.libraries = await getLibraries()
                      this.selectOptions = []
                      if (this.libraries.length > 0) {
                        this.library = this.library ? this.libraries.find(library => library.id === this.library!.id) : this.libraries[0]
                        this.libraries.forEach((library, index) => {
                          this.selectOptions.push({ value: library.name })
                        })
                        this.selectLibraryIndex = this.libraries.findIndex(library => library.id === this.library!.id)
                      }
                      this.user = await getUser()
                    } else {
                      this.getUIContext().getPromptAction().showToast({
                        message: '连接服务器失败！',
                        duration: 500
                      });
                    }
                  }
                }
              })

              Button({ type: ButtonType.Normal }) {
                SymbolGlyph($r('sys.symbol.square_and_pencil'))
                  .fontWeight(FontWeight.Medium)
                  .fontSize(22)
                  .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
                  .hitTestBehavior(HitTestMode.None)
              }
              .height(40)
              .width(40)
              .borderRadius(8)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.editServerIndex = index
                this.tmpServername = this.serverSetting?.loginInfos[this.editServerIndex].name??""
                this.tmpUrl = this.serverSetting?.loginInfos[this.editServerIndex].server.replace(/^https?:\/\//, "")??""
                this.tmpUsername = this.serverSetting?.loginInfos[this.editServerIndex].username??""
                this.tmpPassword = this.serverSetting?.loginInfos[this.editServerIndex].password??""
                this.showEditServer = true
              })
            }
            .width('100%')
          })

          Button({ type: ButtonType.Normal }) {
            Text("添加")
              .fontSize(20)
              .fontColor($r('sys.color.font'))
          }
          .width('100%')
          .height(50)
          .borderRadius(8)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .margin({ top: 10 })
          .borderRadius(8)
          .bindSheet(this.showAddServer, this.AddServerBuilder(), {
            height: 380,
            preferType: SheetType.CENTER,
            title: {
              title: "添加服务器"
            },
            showClose: false,
            onDisappear: () => {
              this.showAddServer = false
              this.tmpServername = ""
              this.tmpUrl = ""
              this.tmpUsername = ""
              this.tmpPassword = ""
            }
          })
          .onClick(() => {
            this.showAddServer = !this.showAddServer;
          })
        }
        .width('100%')
        .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
          env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
          this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
          $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
        .borderRadius(8)
        .padding({ left: 20, right: 20, bottom: 20 })
        .margin({ top: 14 })
        .bindSheet(this.showEditServer, this.EditServerBuilder(), {
          height: 380,
          preferType: SheetType.CENTER,
          title: {
            title: "编辑服务器"
          },
          showClose: false,
          onDisappear: () => {
            this.showEditServer = false
            this.editServerIndex = -1
            this.tmpServername = ""
            this.tmpUrl = ""
            this.tmpUsername = ""
            this.tmpPassword = ""
          }
        })

        Column() {
          Text("外观设置")
            .width('100%')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 20, right: 20 })
            .margin({ top: 20, bottom: 15 })
            .textAlign(TextAlign.Center)

          Row() {
            Text("主题")
              .fontSize(20)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Select(this.themes)
              .selected($$this.selectThemeIndex)
              .value(this.themes[this.selectThemeIndex].value)
              .font({
                weight: FontWeight.Medium
              })
              .menuBackgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
              .selectedOptionFontColor($r('sys.color.select_font_color'))
              .onSelect((index: number) => {
                this.selectThemeIndex = index
                if (index === 0) {
                  this.colorMode!.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
                  this.context!.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
                  this.themeIcon = $r('sys.symbol.circle_righthalf_inset_filled')
                } else if (index === 1) {
                  this.colorMode!.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
                  this.context!.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
                  this.themeIcon = $r('sys.symbol.sun_max_fill')
                } else if (index === 2) {
                  this.colorMode!.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  this.context!.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
                  this.themeIcon = $r('sys.symbol.moon_fill')
                }
              })
              .border({
                radius: 8
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
          env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
          this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
          $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
        .borderRadius(8)
        .padding({ left: 20, right: 20, bottom: 20 })
        .margin({ top: 14 })

        Column() {
          Text("播放设置")
            .width('100%')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .padding({ left: 20, right: 20 })
            .margin({ top: 20, bottom: 15 })
            .textAlign(TextAlign.Center)

          Row() {
            Text("淡入淡出")
              .fontSize(20)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Toggle({ type: ToggleType.Switch, isOn: this.playSetting?.fadeInOut })
              .selectedColor($r('sys.color.comp_emphasize_secondary'))
              .onClick(() => {
                if (this.playSetting) {
                  this.playSetting.fadeInOut = !this.playSetting.fadeInOut
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text("快退时间")
              .fontSize(20)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Button({ type: ButtonType.Circle }) {
              SymbolGlyph(this.gobackwardIcon)
                .fontSize(30)
                .fontColor([$r('sys.color.font')])
            }
            .height(40)
            .width(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.playSetting) {
                if (this.playSetting.gobackwardTime === 10) {
                  this.playSetting.gobackwardTime = 15
                  this.gobackwardIcon = $r('sys.symbol.gobackward_15')
                } else if (this.playSetting.gobackwardTime === 15) {
                  this.playSetting.gobackwardTime = 30
                  this.gobackwardIcon = $r('sys.symbol.gobackward_30')
                } else {
                  this.playSetting.gobackwardTime = 10
                  this.gobackwardIcon = $r('sys.symbol.gobackward_10')
                }
              }
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text("快进时间")
              .fontSize(20)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Button({ type: ButtonType.Circle }) {
              SymbolGlyph(this.goforwardIcon)
                .fontSize(30)
                .fontColor([$r('sys.color.font')])
            }
            .height(40)
            .width(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.playSetting) {
                if (this.playSetting.goforwardTime === 10) {
                  this.playSetting.goforwardTime = 15
                  this.goforwardIcon = $r('sys.symbol.goforward_15')
                } else if (this.playSetting.goforwardTime === 15) {
                  this.playSetting.goforwardTime = 30
                  this.goforwardIcon = $r('sys.symbol.goforward_30')
                } else {
                  this.playSetting.goforwardTime = 10
                  this.goforwardIcon = $r('sys.symbol.goforward_10')
                }
              }
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')
        .backgroundColor((this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET &&
          env.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) ||
          this.colorMode?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ?
          $r('sys.color.background_primary') : $r('sys.color.background_tertiary'))
        .borderRadius(8)
        .padding({ left: 20, right: 20, bottom: 20 })
        .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
    .scrollBar(BarState.Off)
    .padding({ left: 20, right: 20, top: 56, bottom: this.isStartPlaying ? 102 : 20 })
    .align(Alignment.Top)
  }
}