---
name: arkts-syntax-assistant
description: |-
  ArkTS 开发助手，用于 HarmonyOS/OpenHarmony 应用开发。遇到 .ets 文件、
  ArkTS 关键字、HarmonyOS/OpenHarmony 上下文、@ohos 包时激活。涵盖语法
  参考、TypeScript 迁移、性能优化、编译错误、状态管理、组件开发和语言
  相关问题指导。
license: MIT
tags:
  - arkts
  - harmonyos
  - typescript
  - migration
  - development
  - syntax
---

# ArkTS 语法助手

[English](SKILL.md)

---

## 概述

ArkTS 是 OpenHarmony 应用的默认开发语言，在 TypeScript 基础上做了静态类型强化，提升程序稳定性和性能。

## 核心特性

- **强制静态类型**：编译时确定所有类型，减少运行时检查
- **禁止动态对象布局**：对象结构在编译时固定，不可运行时修改
- **限制运算符语义**：部分运算符行为受限，鼓励清晰代码
- **不支持 Structural typing**：当前版本不支持结构化类型

## 参考文档导航

根据需求选择对应文档：

| 场景 | 参考文档 |
|------|----------|
| **语法学习** | [references/zh/introduction-to-arkts.md](references/zh/introduction-to-arkts.md) |
| **快速概览** | [references/zh/arkts-get-started.md](references/zh/arkts-get-started.md) |
| **TS 迁移** | [references/zh/typescript-to-arkts-migration-guide.md](references/zh/typescript-to-arkts-migration-guide.md) |
| **迁移背景** | [references/zh/arkts-migration-background.md](references/zh/arkts-migration-background.md) |
| **性能优化** | [references/zh/arkts-high-performance-programming.md](references/zh/arkts-high-performance-programming.md) |
| **更多案例** | [references/zh/arkts-more-cases.md](references/zh/arkts-more-cases.md) |

## 工作流程

### 1. 语法问题处理流程

```
用户提问 -> 判断问题类型 -> 查阅对应文档 -> 提供代码示例
```

**常见语法问题**：
- 变量声明 -> 使用 `let`/`const`，需显式类型或推断
- 函数定义 -> 支持可选参数、默认值、rest 参数、箭头函数
- 类与接口 -> 必须初始化字段，支持继承和实现
- 泛型使用 -> 支持约束、默认值
- 空安全 -> 可空类型 ((T | null))，非空断言 ((!))，可选链 ((?.))

### 2. TypeScript 迁移问题流程

```
识别 TS 代码 -> 检查不兼容特性 -> 查阅迁移规则 -> 提供 ArkTS 替代方案
```

**关键迁移规则速查**：

| TS 写法 | ArkTS 替代 |
|---------|-----------|
| `var x` | `let x` |
| `any`/`unknown` | 具体类型 |
| `{n: 42}` 对象字面量 | 先定义 class/interface |
| `[index: T]: U` 索引签名 | `Record<T, U>` |
| `A & B` 交叉类型 | `interface C extends A, B` |
| `function(){}` 函数表达式 | `() => {}` 箭头函数 |
| `<Type>value` 类型断言 | `value as Type` |
| 解构赋值 `[a, b] = arr` | 逐个访问 `arr[0]`, `arr[1]` |
| `for..in` | `for` 循环或 `for..of` |
| constructor 参数属性 | 显式声明字段 |

### 3. 性能优化问题流程

```
分析代码 -> 识别性能问题 -> 查阅优化建议 -> 提供优化方案
```

**高性能编程要点**：

- **声明**：不变量用 `const`；避免整型浮点混用
- **循环**：提取循环不变量；避免数值溢出
- **函数**：参数传递优于闭包；避免可选参数
- **数组**：数值用 TypedArray；避免稀疏数组；避免联合类型数组
- **异常**：避免循环中抛异常；用返回值代替

### 4. 编译错误处理流程

```
获取错误信息 -> 在迁移规则中搜索 -> 查找对应案例 -> 提供修复方案
```

## 常见问题速查

### Q: 如何处理 JSON.parse 返回值？

```typescript
// 错误
let data = JSON.parse(str);

// 正确
let data: Record<string, Object> = JSON.parse(str);
```

### Q: 如何定义对象类型？

```typescript
// TS 写法（ArkTS 不支持）
type Person = { name: string, age: number }

// ArkTS 写法
interface Person {
  name: string;
  age: number;
}

// 使用对象字面量
let p: Person = { name: 'John', age: 25 };
```

### Q: 如何替代 globalThis？

```typescript
// 错误
globalThis.value = 'xxx';

// 使用单例模式
export class GlobalContext {
  private constructor() {}
  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  getObject(key: string): Object | undefined {
    return this._objects.get(key);
  }

  setObject(key: string, value: Object): void {
    this._objects.set(key, value);
  }
}
```

### Q: 如何处理 catch 中的错误类型？

```typescript
// 错误
try {} catch (e: BusinessError) {}

// 正确
try {} catch (error) {
  let e: BusinessError = error as BusinessError;
}
```

### Q: 如何使用 Record 类型？

```typescript
// TS 索引签名
function foo(data: { [key: string]: string }) {}

// ArkTS Record
function foo(data: Record<string, string>) {}

// 使用示例
let map: Record<string, number> = {
  'John': 25,
  'Mary': 21,
};
```

### Q: 工厂函数如何替代构造签名？

```typescript
// TS 构造签名
type ControllerCtor = {
  new (value: string): Controller;
}

// ArkTS 工厂函数
type ControllerFactory = () => Controller;

class Menu {
  createController: ControllerFactory = () => {
    return new Controller('default');
  }
}
```

## 禁止使用的标准库 API

以下在 ArkTS 中禁止使用：

- **全局**：`eval`
- **Object**：`__proto__`、`defineProperty`、`freeze`、`getPrototypeOf` 等
- **Reflect**：`apply`、`construct`、`defineProperty` 等
- **Proxy**：所有 handler 方法

## 编译脚本

scripts 目录提供 ArkTS 项目快速编译脚本（包含依赖安装）：

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

脚本执行步骤：
1. 安装依赖（`ohpm install --all`）
2. 编译项目（`hvigorw assembleApp`）

## 强制性要求

**关键要求**：当此技能生成 ArkTS 代码时，必须遵循以下工作流程：

1. **编译验证**：生成代码后，必须使用构建脚本编译项目：
   - macOS/Linux: `bash scripts/run.sh`
   - Windows: `.\scripts\run.ps1`

2. **重试策略**：如果编译失败：
   - 分析错误输出
   - 修复问题并重试编译
   - 最多 **3 次编译尝试**

3. **用户介入**：3 次编译失败后，使用 `AskUserQuestion` 询问用户：
   ```
   问题：编译已失败 3 次。您希望如何继续？
   选项：
   - 继续重试（尝试再次修复）
   - 手动介入（等待您的指导）
   - 跳过编译（不验证继续进行）
   ```

4. **错误报告**：失败时始终显示完整的编译错误输出。

## 回答指南

1. **优先提供代码示例**：展示正确写法和错误写法对比
2. **引用官方文档**：需要详细说明时，指引用户查阅 references/ 中的对应文档
3. **解释原因**：说明为什么 ArkTS 有此限制（性能、稳定性）
4. **提供替代方案**：不支持的特性要给出可行的替代方案

## 许可证

MIT License - 详见 [LICENSE.txt](LICENSE.txt)
