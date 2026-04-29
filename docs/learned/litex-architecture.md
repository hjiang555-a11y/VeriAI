# LiteX 架构分析与设计模式总结

> 日期：2026-04-28 | 来源：LiteX 源码阅读 + Migen DSL 实践 | 对 VeriAI 用途：RAG 知识库、代码生成模板、CSR 自动生成参考

---

## 一、LiteX 整体架构

```
┌──────────────────────────────────────────────────┐
│                  SoCCore                          │
│  (CPU + ROM + SRAM + UART + Timer + CSRs)        │
│  ┌────────────────────────────────────────────┐  │
│  │         Wishbone Interconnect              │  │
│  │  Arbiter ── Decoder ── Crossbar ── SRAM   │  │
│  │  Converter ── Wishbone2CSR                 │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │              CSR System                     │  │
│  │  CSRField ── CSRStatus ── CSRStorage       │  │
│  │  AutoCSR ── GenericBank                    │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │           Migen FHDL (AST)                  │  │
│  │  Module ── Signal ── sync/comb ── specials │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

三层清晰分离：
- **Migen FHDL**：硬件描述 AST，负责生成 Verilog
- **CSR System**：寄存器抽象层，负责配置/状态寄存器的自动化
- **Wishbone Bus**：片上互联总线，负责模块间通信

---

## 二、Migen DSL → Verilog 生成链路

### 2.1 核心 DSL 原语

| Migen DSL | 对应 Verilog | 含义 |
|-----------|-------------|------|
| `Signal(n)` | `reg [n-1:0]` 或 `wire [n-1:0]` | n 位信号 |
| `self.sync += x.eq(y)` | `always @(posedge clk) x <= y` | 同步赋值 |
| `self.comb += x.eq(y)` | `assign x = y` | 组合赋值 |
| `If(cond, ...)` | `if (cond) ...` | 条件语句 |
| `self.submodules.x = Module()` | 子模块实例化 | 层次化设计 |
| `Case(sel, cases)` | `case (sel) ... endcase` | 多路选择 |

### 2.2 生成链路

```
Python Module 对象
    │
    ▼
Migen FHDL AST（Module + Signal + Statement）
    │
    ▼
verilog.convert(module, ios={...})
    │
    ▼
Verilog 文本字符串
```

**关键发现**：Migen 的 `verilog.convert()` 是纯 Python 的 Verilog 后端正——不需要任何外部工具即可生成可综合 Verilog。

### 2.3 子模块组合模型

```python
class Parent(Module):
    def __init__(self):
        self.submodules.child = Child()
```

`self.submodules +=` 自动处理：
- 子模块纳入顶层模块
- 信号名称自动加前缀
- 复位和时钟自动连接

---

## 三、CSR 自动生成系统（VeriAI 重点参考）

### 3.1 CSR 类型层次

```
_CSRBase (name, size)
├── CSR            — 单地址寄存器（≤ busword）
├── _CompoundCSR   — 多地址寄存器（≥ busword）
│   ├── CSRStatus  — 只读状态寄存器（硬件 → CPU）
│   └── CSRStorage — 读写控制寄存器（CPU ↔ 硬件，支持 atomic write）
├── CSRConstant    — 只读常量寄存器
└── CSRField       — 寄存器内位域（含描述、复位值、枚举值、脉冲模式）
```

### 3.2 CSRField 设计（直接可被 VeriAI SRS 模板引用）

```python
class CSRField(Signal):
    def __init__(self, name, size=1, offset=None, reset=0,
                 description=None, pulse=False, access=None, values=None):
```

| 字段 | 含义 | 对应 SRS 需求 |
|------|------|-------------|
| `name` | 位域名称 | FR 中寄存器位域描述 |
| `size` | 位宽 | HID 中端口宽度 |
| `offset` | 偏移 | 寄存器地址映射 |
| `reset` | 复位值 | NFR 中复位行为 |
| `description` | 功能描述 | FR 中功能需求 |
| `access` | 读写权限 | C 中访问约束 |
| `pulse` | 脉冲模式 | 自清除信号 |
| `values` | 枚举值列表 | 状态编码表 |

### 3.3 AutoCSR：反射式寄存器自动发现

```python
class AutoCSR:
    def get_csrs(self):
        # 遍历 self 的所有属性
        # 找到 CSR 实例 → 收集
        # 找到有 get_csrs() 的子对象 → 递归收集 + 前缀
```

**核心机制**：Python 反射（`xdir`）+ 命名前缀链，实现任意深度的寄存器树自动扁平化。

### 3.4 寄存器拼接（CSRFieldAggregate）

```python
fields = [
    CSRField("enable",    offset=0, size=1,  description="模块使能"),
    CSRField("divider",   offset=1, size=15, description="时钟分频比"),
    CSRField("mode",      offset=16,size=2,  description="工作模式",
             values=[("0b00","IDLE"), ("0b01","TX"), ("0b10","RX")]),
]
agg = CSRFieldAggregate(fields, access=CSRAccess.ReadWrite)
# agg.get_size() → 18
# agg.get_reset() → 0
```

### 3.5 CSR → Wishbone 桥接

`Wishbone2CSR` 将 Wishbone 总线周期转换为 CSR 读写：
- Wishbone write → `csr.re` + `csr.r`（写选通 + 写数据）
- Wishbone read → `csr.we` + `csr.w`（读选通 + 读数据）

---

## 四、Wishbone 总线互联

### 4.1 总线接口定义

| 信号 | 方向 | 含义 |
|------|------|------|
| `adr` | M→S | 地址 |
| `dat_w` | M→S | 写数据 |
| `dat_r` | S→M | 读数据 |
| `sel` | M→S | 字节使能 |
| `cyc` | M→S | 总线周期 |
| `stb` | M→S | 选通 |
| `ack` | S→M | 应答 |
| `we` | M→S | 写使能 |
| `err` | S→M | 错误 |

### 4.2 互联拓扑

| 类型 | 实现 | 场景 |
|------|------|------|
| Point-to-Point | 直连 | 单主单从 |
| Shared Bus | Arbiter + Decoder | 多主多从，低资源 |
| Crossbar | Decoder × M + Arbiter × S | 多主多从，高带宽 |

### 4.3 数据宽度转换

`Converter` 自动处理不同数据宽度的总线连接：
- `DownConverter`：宽主→窄从（拆分访问）
- `UpConverter`：窄主→宽从（合并访问）

---

## 五、SoC 组装模式

### 5.1 SoCCore 初始化流程

```python
class SoCCore(LiteXSoC):
    def __init__(self, platform, clk_freq, ...):
        # 1. 初始化 LiteXSoC（创建总线、CSR 总线、中断控制器）
        # 2. 按参数条件添加模块：
        #    - CPU（VexRiscv 等）
        #    - ROM（含 BIOS）
        #    - SRAM / Main RAM
        #    - UART / JTAGBone / UARTBone
        #    - Timer / Watchdog
        #    - SoCController
```

### 5.2 内存映射

```
0x0000_0000  ROM
0x0100_0000  SRAM
0x4000_0000  Main RAM
0xF000_0000  CSRs
```

### 5.3 设计模式总结

| 模式 | LiteX 实现 | VeriAI 可借鉴 |
|------|-----------|-------------|
| **参数化工厂** | `SoCCore(platform, clk_freq, cpu_type=..., with_uart=...)` | SRS → 参数化模块生成 |
| **反射式发现** | `AutoCSR.get_csrs()` 自动收集寄存器 | 从 SRS 自动生成寄存器映射 |
| **总线抽象** | Wishbone Interface 统一所有模块互连 | 模块互联规范模板 |
| **描述即文档** | `CSRField(description=...)` | 寄存器文档自动生成 |
| **分层组装** | Migen → CSR → Wishbone → SoCCore | 四层分阶段生成策略 |

---

## 六、对 VeriAI 的具体影响

### 6.1 立即可用的模式

1. **CSRField 设计**：可直接作为 VeriAI HID 模板中"寄存器映射"子模板的字段定义
2. **CSRFieldAggregate 拼接逻辑**：寄存器位域自动拼接算法，可内嵌到 RTL Agent
3. **Wishbone 总线模板**：作为 `lib/wishbone/` 金标准模块的参考实现

### 6.2 需要进一步研究

1. **Migen 的 Verilog 后端正**：是否可以作为 VeriAI 的另一种代码生成后端？
2. **SpinalHDL 的对比**：VexRiscv 使用 SpinalHDL，与 Migen 同属 DSL→RTL 范畴，Phase 6.2 深入对比
3. **CSR 文档自动生成**：LiteX 的 `soc/doc/csr.py` 可从 CSR 定义自动生成 RST 文档——VeriAI 可以做类似的事

### 6.3 不适用 VeriAI 的部分

- LiteX 的目标是 Python→SoC，VeriAI 的目标是 Spec→RTL，输入范式不同
- LiteX 的 Wishbone 绑定方式依赖 Python 反射，VeriAI 需要自己的"从 Spec 到互联"的映射机制
- Migen 的 AST 生成方式需要用户编程，VeriAI 可以用 LLM 替代这部分

---

## 七、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：LiteX 三层架构、CSR 系统、Wishbone 总线、SoC 组装模式分析 |
