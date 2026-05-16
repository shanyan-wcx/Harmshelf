<div align="center">

# ArkTS Syntax Assistant

[English](./README.en.md) | 简体中文

![GitHub License](https://img.shields.io/github/license/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;
![GitHub Release](https://img.shields.io/github/v/release/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;
![GitHub Repo stars](https://img.shields.io/github/stars/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;

</div>

> ArkTS 语言学习与开发助手，提供语法参考、TypeScript 迁移指导和高性能编程实践

这是一个支持多平台的 ArkTS 语法助手技能，兼容 claude-code、opencode、cursor、trea 等 AI 编码助手。ArkTS 是 OpenHarmony 应用的默认开发语言，在 TypeScript 基础上做了静态类型强化，提升程序稳定性和性能。

## 功能特性

- **语法学习**：涵盖 ArkTS 基础语法（声明、类型、函数、类、泛型、模块等）
- **TypeScript 迁移**：详细的 TS 到 ArkTS 迁移指南，包括语法约束、类型系统差异、不兼容特性
- **高性能编程**：内存优化、循环优化、数组处理、异常处理等最佳实践
- **编译错误解决**：常见编译错误的诊断和修复方案
- **代码示例**：丰富的对比示例，展示正确与错误写法

## 开发工具支持

这个技能可以帮助您的AI助手轻松编写ArkTS代码，但如果您也需要自己编写和修改代码，却对DevEco Studio缺少Tab补全功能感到困扰，欢迎在VSCode（及同类IDE）中安装ArkTS语言支持插件：

<div align="center">

### Naily's ArkTS Support
[![](https://img.shields.io/badge/VSCode-Plugin-informational?style=for-the-badge&logo=visual-studio-code&logoColor=white&color=007ACC)](https://marketplace.visualstudio.com/items?itemName=NailyZero.vscode-naily-ets)

</div>

> [!NOTE]  
> **[Naily's ArkTS Support](https://github.com/ohosvscode/arkTS)** 是一个为VSCode设计的ArkTS语言支持插件，提供了语法高亮、智能补全等功能，让开发者在VSCode中也能获得良好的ArkTS开发体验。

## 安装

### 推荐方式：使用 npx skills add（一键安装）

```bash
npx skills add https://github.com/SummerKaze/skill-arkts-syntax-assistant.git
```

这是最简单快速的安装方式，会自动下载并配置技能。

### 方式一：通过 Release 安装

1. 访问 [Releases](https://github.com/SummerKaze/skill-arkts-syntax-assistant/releases) 页面
2. 下载最新版本的压缩包
3. 解压到 Claude Code 的技能目录

### 方式二：克隆仓库

```bash
cd ~/.claude/skills/
git clone https://github.com/SummerKaze/skill-arkts-syntax-assistant.git
```

## 文档导航

根据需求选择对应文档：

| 场景 | 参考文档 |
|------|----------|
| **语法学习** | [references/zh/introduction-to-arkts.md](references/zh/introduction-to-arkts.md) |
| **快速概览** | [references/zh/arkts-get-started.md](references/zh/arkts-get-started.md) |
| **TS 迁移** | [references/zh/typescript-to-arkts-migration-guide.md](references/zh/typescript-to-arkts-migration-guide.md) |
| **迁移背景** | [references/zh/arkts-migration-background.md](references/zh/arkts-migration-background.md) |
| **性能优化** | [references/zh/arkts-high-performance-programming.md](references/zh/arkts-high-performance-programming.md) |
| **更多案例** | [references/zh/arkts-more-cases.md](references/zh/arkts-more-cases.md) |

## 快速开始

### 使用技能

在 Claude Code 中，当你遇到以下问题时，此技能会自动激活：

- 学习 ArkTS 基础语法
- 从 TypeScript 迁移到 ArkTS
- ArkTS 高性能编程优化
- 解决 ArkTS 编译错误或运行时问题
- HarmonyOS/OpenHarmony 应用开发中的语言相关问题

### 常见问题速查

**Q: 如何处理 JSON.parse 返回值？**

```typescript
// 错误
let data = JSON.parse(str);

// 正确
let data: Record<string, Object> = JSON.parse(str);
```

**Q: 如何定义对象类型？**

```typescript
// TS 写法（ArkTS 不支持）
type Person = { name: string, age: number }

// ArkTS 写法
interface Person {
  name: string;
  age: number;
}
```

**Q: TypeScript 到 ArkTS 迁移规则速查**

| TS 写法 | ArkTS 替代 |
|---------|-----------|
| `var x` | `let x` |
| `any`/`unknown` | 具体类型 |
| `{n: 42}` 对象字面量 | 先定义 class/interface |
| `[index: T]: U` 索引签名 | `Record<T, U>` |
| `A & B` 交叉类型 | `interface C extends A, B` |
| `<Type>value` 类型断言 | `value as Type` |
| 解构赋值 `[a, b] = arr` | 逐个访问 `arr[0]`, `arr[1]` |
| `for..in` | `for` 循环或 `for..of` |

## 编译脚本

项目提供快速编译脚本（包含依赖安装）：

| 平台 | 脚本 | 用途 |
|------|------|------|
| macOS/Linux | `scripts/run.sh` | 执行 `ohpm install` + `hvigorw assembleApp` |
| Windows | `scripts/run.ps1` | 执行 `ohpm install` + `hvigorw assembleApp` |

使用方式：
```bash
# macOS/Linux
bash scripts/run.sh

# Windows PowerShell
.\scripts\run.ps1
```

## 核心特性

- **强制静态类型**：编译时确定所有类型，减少运行时检查
- **禁止动态对象布局**：对象结构在编译时固定，不可运行时修改
- **限制运算符语义**：部分运算符行为受限，鼓励清晰代码
- **不支持 Structural typing**：当前版本不支持结构化类型

## 禁止使用的 API

以下在 ArkTS 中禁止使用：

- **全局**：`eval`
- **Object**：`__proto__`、`defineProperty`、`freeze`、`getPrototypeOf` 等
- **Reflect**：`apply`、`construct`、`defineProperty` 等
- **Proxy**：所有 handler 方法

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=SummerKaze/skill-arkts-syntax-assistant&type=date&legend=top-left)](https://www.star-history.com/#SummerKaze/skill-arkts-syntax-assistant&type=date&legend=top-left)

## License

[MIT](./LICENSE.txt)

Copyright (c) 2025 SummerKaze
