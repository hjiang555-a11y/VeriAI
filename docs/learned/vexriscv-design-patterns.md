# VexRiscv 设计模式分析

> 日期：2026-04-28 | 来源：VexRiscv README、Pipeline/Services 源码、插件目录结构 | 学习重点：思想而非代码

---

## 一、核心设计哲学

VexRiscv 用一句话概括其设计哲学：

> **"A very software oriented approach" — 用软件工程的插件化思想构建硬件 CPU**

传统 CPU 设计：写死流水线、写死功能集、每种变体需要改代码。
VexRiscv 的做法：**CPU = 空流水线骨架 + 插件列表**。功能通过插件组合，不通过代码分支。

---

## 二、插件化架构

### 2.1 三层模型

```
┌─────────────────────────────────────────────┐
│              VexRiscvConfig                  │
│    (一个配置对象，包含插件列表 + 流水线级数)    │
├─────────────────────────────────────────────┤
│             Pipeline (流水线骨架)             │
│    - 定义 Stage (Fetch/Decode/Execute/...)   │
│    - 管理 Stage 间的信号传递                  │
│    - 提供 Service 注册与查找                  │
├─────────────────────────────────────────────┤
│          Plugins (功能插件，40+)              │
│    IBusSimple / DBusCached / DecoderSimple   │
│    IntAlu / Mul / Div / Fpu / Branch / Csr   │
│    HazardSimple / Mmu / Pmp / Debug / ...    │
└─────────────────────────────────────────────┘
```

### 2.2 插件分类

| 类别 | 插件 | 职责 |
|------|------|------|
| **取指** | IBusSimplePlugin, IBusCachedPlugin | 指令获取、分支预测、缓存 |
| **译码** | DecoderSimplePlugin | 指令译码、非法指令检测 |
| **执行** | IntAluPlugin, MulPlugin, DivPlugin, ShiftPlugins, BranchPlugin | ALU、乘除、移位、分支 |
| **访存** | DBusSimplePlugin, DBusCachedPlugin | 数据读写、数据缓存 |
| **冒险** | HazardSimplePlugin, HazardPessimisticPlugin | 流水线冲突处理 |
| **特权** | CsrPlugin, MmuPlugin, PmpPlugin, PrivilegeService | CSR、MMU、物理内存保护 |
| **调试** | DebugPlugin, EmbeddedRiscvJtag | 调试支持 |
| **扩展** | FpuPlugin, AesPlugin, CfuPlugin, VfuPlugin | 浮点、加密、自定义指令 |

### 2.3 核心洞见：组合优于继承

不同配置 = 不同的插件列表，不是不同的代码分支：

```
GenSmallest:  [IBusSimple, DecoderSimple, IntAlu, RegFile, HazardSimple, Csr, DBusSimple]
GenFull:      [IBusCached, DecoderSimple, IntAlu, Mul, Div, Shift, Branch, RegFile, HazardSimple, Csr, DBusCached, Debug]
GenLinux:     [IBusCached, DecoderSimple, IntAlu, Mul, Div, Shift, Branch, RegFile, HazardSimple, Csr, DBusCached, Mmu, Pmp, Debug]
GenFullMaxPerf: [...GenFull + dynamic branch prediction + optimized execute stage]
```

---

## 三、Service 系统：插件间通信

### 3.1 设计模式

```
Plugin A 提供 Service X ──→ 注册到 Pipeline
Plugin B 需要 Service X ──→ 从 Pipeline 获取
```

这不是简单的函数调用，而是硬件信号级别的接口抽象。

### 3.2 关键 Service 类型

| Service | 提供者 | 消费者 | 作用 |
|---------|--------|--------|------|
| `JumpService` | BranchPlugin | Fetch | 跳转目标地址传递 |
| `ExceptionService` | CsrPlugin | 所有执行插件 | 异常/中断请求 |
| `DecoderService` | DecoderSimple | 所有执行插件 | 指令译码信息 |
| `MemoryTranslator` | MmuPlugin | IBus/DBus | 虚拟→物理地址转换 |
| `RegFileService` | RegFilePlugin | Decoder | 寄存器文件读口位置 |
| `PrivilegeService` | CsrPlugin | Mmu/Pmp | 当前特权级别 |
| `ReportService` | 各插件 | 调试/文档 | 诊断信息收集 |

### 3.3 核心洞见

**Service = 硬件接口契约**。每个 Service 是一个 trait（接口），定义了该服务提供的硬件信号端口。Plugin A 实现该端口并注册，Plugin B 通过类型查找获取端口并连接。

这本质上是**硬件级别的依赖注入**。

---

## 四、流水线抽象

### 4.1 Stage 模型

```
Fetch ──→ Decode ──→ Execute ──→ Memory ──→ WriteBack
  │         │          │           │            │
  └─────────┴──────────┴───────────┴────────────┘
              插件可以在任意 Stage 之间插入数据
              (automatic pipelining)
```

### 4.2 自动化流水线

核心机制：Plugin 在 Stage N 插入数据 → Plugin 在 Stage M (M > N) 获取数据 → Pipeline 自动管理数据传递

这消除了手动连线，是 VexRiscv 最巧妙的设计之一。

### 4.3 流水线控制

| 参数 | 含义 | 面积/性能权衡 |
|------|------|-------------|
| 流水线级数 | 2-5+ 级 | 级数越多 → 频率越高，面积越大 |
| Fetch 级 | 可去除 | 去 Fetch → 面积↓，性能↓ |
| Memory 级 | 可去除 | 去 Memory → 面积↓，访存延迟↑ |
| WriteBack 级 | 可去除 | 去 WB → 面积↓ |
| 冒险处理 | bypass vs interlock | bypass → 性能↑，面积↑；interlock → 反之 |

---

## 五、总线解耦模式

### 5.1 内部-外部总线分离

```
CPU Pipeline (内部)
    │
    ▼
IBusSimpleBus / DBusSimpleBus (内部简单总线)
    │
    ├──→ AXI4 适配器 ──→ AXI4 外部总线
    ├──→ Wishbone 适配器 ──→ Wishbone 外部总线
    ├──→ Avalon 适配器 ──→ Avalon 外部总线
    └──→ AHB-Lite3 适配器 ──→ AHB 外部总线
```

**核心洞见**：CPU 内部不关心外部总线标准。内部总线是最简单的 valid/ready 握手，通过适配器桥接到任何外部总线。这与 LiteX 的 Wishbone 桥接模式完全一致。

### 5.2 适配器参数

| 参数 | 含义 |
|------|------|
| `pendingMax` | 最大未完成请求数（控制流水线深度） |
| `busLatencyMin` | 最小总线延迟 |
| `resetVector` | 复位入口地址 |
| `catchAccessFault` | 是否捕获访问错误 |
| `memoryTranslatorPortConfig` | MMU 配置（可选） |

---

## 六、面积/性能连续谱

VexRiscv 的设计让面积和性能之间形成一个可调节的连续谱：

```
面积最小 ←────────────────────────────→ 性能最高
GenSmallest    GenSmall    GenFull    GenFullMaxPerf    GenLinux
  RV32I         RV32I      RV32IM      RV32IM+           RV32IMA+
  无缓存         无缓存      有缓存       动态分支预测       MMU+权限
  2级流水        3级         5级          5级优化           5级完整
  0.52 DMIPS     ~0.8        ~1.2         1.44              1.3+
```

**核心洞见**：这不是 4 个不同的 CPU，而是**同一套插件的 4 种组合**。

---

## 七、对 VeriAI 的启示

### 7.1 直接可借鉴的思想

| VexRiscv 模式 | 对 VeriAI 的启发 |
|-------------|----------------|
| 插件化组合 | **SRS → 模块分解**：不同 SRS 需求组合不同 IP 模块，而非生成完全不同的代码 |
| Service 系统 | **模块间接口契约**：在 HID 中定义标准化的模块间通信接口 |
| 配置即插件列表 | **参数化生成策略**：AI 根据 SRS 选择模块组合，而非每次从头生成 |
| 内部总线抽象 | **模块互联抽象层**：VeriAI 生成的模块可输出到 Wishbone/AXI-Lite/AXI-Stream |
| 自动化流水线 | **数据流自动推断**：从 SRS 数据流描述自动生成流水线连接 |

### 7.2 VeriAI 可以建立的映射

```
VexRiscv 插件        →  VeriAI 模块库 (lib/)
VexRiscv Service     →  VeriAI HID 接口契约
VexRiscv Config      →  VeriAI SRS (需求组合)
VexRiscv Pipeline    →  VeriAI 数据流图
VexRiscv 适配器       →  VeriAI 总线桥接模板
```

### 7.3 关键行动项

1. **在 VeriAI 模块库中引入"插件化"概念**：模块不应是孤立的，而应该有标准化的 Service 接口
2. **建立"模块选择策略"**：AI 根据 SRS 需求从模块库中选择合适组合，类似 VexRiscv 从插件库中选择
3. **总线适配器模板**：为 `lib/` 中的模块自动生成 Wishbone/AXI-Lite 适配器

---

## 八、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：VexRiscv 插件化架构、Service 系统、流水线抽象、总线解耦分析 |
