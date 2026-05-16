<div align="center">

# ArkTS Syntax Assistant

English | [简体中文](./README.md)

![GitHub License](https://img.shields.io/github/license/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;
![GitHub Release](https://img.shields.io/github/v/release/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;
![GitHub Repo stars](https://img.shields.io/github/stars/SummerKaze/skill-arkts-syntax-assistant?style=flat)&nbsp;

</div>

> ArkTS language learning and development assistant providing syntax reference, TypeScript migration guidance, and high-performance programming practices

This is a multi-platform ArkTS syntax assistant skill compatible with claude-code, opencode, cursor, trea, and other AI coding assistants. ArkTS is the default development language for OpenHarmony applications, built upon TypeScript with enhanced static typing to improve program stability and performance.

## Features

- **Syntax Learning**: Covers ArkTS basic syntax (declarations, types, functions, classes, generics, modules, etc.)
- **TypeScript Migration**: Detailed TS to ArkTS migration guide, including syntax constraints, type system differences, and incompatible features
- **High-Performance Programming**: Best practices for memory optimization, loop optimization, array handling, exception handling, etc.
- **Compile Error Resolution**: Diagnosis and fixes for common compilation errors
- **Code Examples**: Rich comparison examples showing correct vs incorrect syntax

## Development Tooling

This skill can help your AI agent easily write ArkTS code, but if you also need to write and modify code yourself, and are annoyed by the lack of tab completion in DevEco Studio, you're welcome to install the ArkTS language support plugin in VSCode (and similar IDEs):

<div align="center">

### Naily's ArkTS Support
[![](https://img.shields.io/badge/VSCode-Plugin-informational?style=for-the-badge&logo=visual-studio-code&logoColor=white&color=007ACC)](https://marketplace.visualstudio.com/items?itemName=NailyZero.vscode-naily-ets)

</div>

> [!NOTE]  
> **[Naily's ArkTS Support](https://github.com/ohosvscode/arkTS/blob/next/README-en.md)** is a VSCode extension designed for ArkTS language support, providing syntax highlighting, intelligent completion, and other features that allow developers to enjoy a great ArkTS development experience in VSCode.

## Installation

### Recommended: npx skills add (One-Command Installation)

```bash
npx skills add https://github.com/SummerKaze/skill-arkts-syntax-assistant.git
```

This is the simplest and fastest installation method, automatically downloading and configuring the skill.

### Method 1: Install via Release

1. Visit the [Releases](https://github.com/SummerKaze/skill-arkts-syntax-assistant/releases) page
2. Download the latest version archive
3. Extract to Claude Code's skills directory

### Method 2: Clone Repository

```bash
cd ~/.claude/skills/
git clone https://github.com/SummerKaze/skill-arkts-syntax-assistant.git
```

## Documentation

Select the appropriate document based on your needs:

| Scenario | Document |
|----------|----------|
| **Syntax Learning** | [references/en/introduction-to-arkts.md](references/en/introduction-to-arkts.md) |
| **Quick Overview** | [references/en/arkts-get-started.md](references/en/arkts-get-started.md) |
| **TS Migration** | [references/en/typescript-to-arkts-migration-guide.md](references/en/typescript-to-arkts-migration-guide.md) |
| **Migration Background** | [references/en/arkts-migration-background.md](references/en/arkts-migration-background.md) |
| **Performance** | [references/en/arkts-high-performance-programming.md](references/en/arkts-high-performance-programming.md) |
| **More Cases** | [references/en/arkts-more-cases.md](references/en/arkts-more-cases.md) |

## Quick Start

### Using the Skill

In Claude Code, this skill will automatically activate when you encounter:

- Learning ArkTS basic syntax
- Migrating from TypeScript to ArkTS
- ArkTS high-performance programming optimization
- Resolving ArkTS compile errors or runtime issues
- Language-related questions in HarmonyOS/OpenHarmony application development

### Common Questions Quick Reference

**Q: How to handle JSON.parse return value?**

```typescript
// Error
let data = JSON.parse(str);

// Correct
let data: Record<string, Object> = JSON.parse(str);
```

**Q: How to define object types?**

```typescript
// TypeScript syntax (not supported in ArkTS)
type Person = { name: string, age: number }

// ArkTS syntax
interface Person {
  name: string;
  age: number;
}
```

**Q: TypeScript to ArkTS Migration Quick Reference**

| TypeScript | ArkTS Alternative |
|------------|-------------------|
| `var x` | `let x` |
| `any`/`unknown` | Specific types |
| `{n: 42}` object literal | Define class/interface first |
| `[index: T]: U` index signature | `Record<T, U>` |
| `A & B` intersection type | `interface C extends A, B` |
| `<Type>value` type assertion | `value as Type` |
| Destructuring `[a, b] = arr` | Individual access `arr[0]`, `arr[1]` |
| `for..in` | `for` loop or `for..of` |

## Build Scripts

The project provides quick compilation scripts (including dependency installation):

| Platform | Script | Purpose |
|----------|--------|---------|
| macOS/Linux | `scripts/run.sh` | Execute `ohpm install` + `hvigorw assembleApp` |
| Windows | `scripts/run.ps1` | Execute `ohpm install` + `hvigorw assembleApp` |

Usage:
```bash
# macOS/Linux
bash scripts/run.sh

# Windows PowerShell
.\scripts\run.ps1
```

## Core Features

- **Static Typing**: All types determined at compile time, reducing runtime checks
- **No Dynamic Object Layout**: Object structure fixed at compile time, cannot be modified at runtime
- **Restricted Operators**: Some operator behaviors are restricted to encourage clearer code semantics
- **No Structural Typing**: Structural typing is currently not supported

## Prohibited Standard Library APIs

The following are prohibited in ArkTS:

- **Global**: `eval`
- **Object**: `__proto__`, `defineProperty`, `freeze`, `getPrototypeOf`, etc.
- **Reflect**: `apply`, `construct`, `defineProperty`, etc.
- **Proxy**: All handler methods

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=SummerKaze/skill-arkts-syntax-assistant&type=date&legend=top-left)](https://www.star-history.com/#SummerKaze/skill-arkts-syntax-assistant&type=date&legend=top-left)

## License

[MIT](./LICENSE.txt)

Copyright (c) 2025 SummerKaze
