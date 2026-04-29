# Neorv32 文档质量分析

> 日期：2026-04-28 | 来源：Neorv32 Data Sheet、56 个 VHDL 源文件结构分析 | 对 VeriAI 用途：SRS/HID 模板优化、外设文档模板、模块拆解参考

---

## 一、Data Sheet 整体架构

Neorv32 Data Sheet 采用 6 章结构，自上而下：

```
1. Overview                    — 项目概览、特性列表、快速开始
2. NEORV32 Processor (SoC)     — SoC 顶层、内存、外设、总线
3. NEORV32 CPU                 — CPU 微架构、流水线、ISA
4. Software Framework          — 驱动库、启动代码、编译工具链
5. On-Chip Debugger (OCD)      — JTAG 调试、Trace
6. Legal                       — 许可证
```

**核心特点**：硬件文档驱动软件文档。"要理解一个外设，从 Data Sheet 一章就够了"——这是 Neorv32 文档的最高目标。

---

## 二、外设章节模板（Peripheral Chapter Template）

### 2.1 标准模板结构

每个外设章节严格遵循以下模板：

```
N.N 外设名
├── 元数据头
│   ├── Hardware source files:   neorv32_xxx.vhd
│   ├── Software driver files:   neorv32_xxx.c / neorv32_xxx.h
│   ├── Top entity ports:        (信号表)
│   ├── Configuration generics:  (参数表)
│   └── CPU interrupts:          (中断号或 none)
├── Key Features                 (要点列表)
├── Overview                     (架构概述)
├── 寄存器映射表                  (地址/名称/位宽/访问/描述)
├── 寄存器位域详述                (每位/每域单独说明)
├── 时序图 (如有)                 (ASCII art 波形图)
└── Code Examples                (C 代码示例)
```

### 2.2 元数据头格式

```
Hardware source files:
  - rtl/core/neorv32_spi.vhd

Software driver files:
  - sw/lib/source/neorv32_spi.c
  - sw/lib/include/neorv32_spi.h

Top entity ports:
  Name          Width   Direction   Default   Description
  spi_sck       1       out         -         SPI clock
  spi_mosi      1       out         -         Master-out/slave-in
  spi_miso      1       in          -         Master-in/slave-out
  spi_csn       8       out         all 1     Chip select (one-hot)

Configuration generics:
  Generic        Type     Default    Description
  IO_SPI_EN      boolean  false      Enable SPI when true
  IO_SPI_FIFO    natural  4          FIFO depth (0=no FIFO)

CPU interrupts:
  - SPI interrupt (fast IRQ channel 2)
```

### 2.3 寄存器表格式

```
Address  Name [CN]  Bits  Access  Reset   Description
0xFFFFFF80  CTRL    31:0  R/W     0x0000  Control register
            [0]             r/w     0       SPI enable
            [1]             r/w     0       CPOL (clock polarity)
            [2]             r/w     0       CPHA (clock phase)
            [7:3]           r/w     0       Prescaler select
            [15:8]          r/w     0       Clock divider
0xFFFFFF84  DATA    7:0   R/W     0x00    Data register
```

---

## 三、SoC 模块拆分模式

### 3.1 文件组织（56 个 VHDL 文件）

```
rtl/core/
├── neorv32_top.vhd              # SoC 顶层
├── neorv32_package.vhd          # 全局常量/类型/地址映射
├── neorv32_cpu.vhd              # CPU 顶层
│   ├── neorv32_cpu_control.vhd  # 控制通路
│   ├── neorv32_cpu_frontend.vhd # 取指前端
│   ├── neorv32_cpu_regfile.vhd  # 寄存器文件
│   ├── neorv32_cpu_lsu.vhd      # 访存单元
│   ├── neorv32_cpu_pmp.vhd      # 物理内存保护
│   ├── neorv32_cpu_counters.vhd # 性能计数器
│   └── neorv32_cpu_alu*.vhd     # ALU (8个文件：基础/位操作/条件/浮点/乘除/移位/加密/CFU)
├── 内存系统
│   ├── neorv32_imem*.vhd        # 指令内存 (4文件)
│   ├── neorv32_dmem*.vhd        # 数据内存 (2文件)
│   ├── neorv32_cache*.vhd       # 缓存 (2文件)
│   └── neorv32_bootrom*.vhd     # 启动 ROM (3文件)
├── 总线与互联
│   ├── neorv32_bus.vhd          # 内部总线
│   ├── neorv32_xbus.vhd         # 外部总线 (Wishbone)
│   └── neorv32_dma.vhd          # DMA
├── 外设 (每个外设一个文件)
│   ├── neorv32_gpio.vhd         # GPIO
│   ├── neorv32_uart.vhd         # UART
│   ├── neorv32_spi.vhd          # SPI
│   ├── neorv32_twi.vhd          # I2C (Two-Wire)
│   ├── neorv32_pwm.vhd          # PWM
│   ├── neorv32_gptmr.vhd        # 通用定时器
│   ├── neorv32_wdt.vhd          # 看门狗
│   ├── neorv32_trng.vhd         # 真随机数
│   ├── neorv32_neoled.vhd       # NeoPixel LED
│   ├── neorv32_slink.vhd        # AXI-Stream 链路
│   └── ...
└── 调试与系统
    ├── neorv32_debug_dm.vhd     # 调试模块
    ├── neorv32_debug_dtm.vhd    # 调试传输模块
    ├── neorv32_tracer.vhd       # 指令追踪
    └── neorv32_sysinfo.vhd      # 系统信息
```

### 3.2 模块拆分原则

1. **每个外设一个文件**：不合并相关外设，保持独立性
2. **CPU 内部按功能拆分**：控制/前端/ALU/访存/寄存器文件各自独立文件
3. **接口与实现分离**：`neorv32_xxx.vhd` 是主模块，`neorv32_xxx_ram.vhd` 是存储实现
4. **全局定义集中**：所有地址映射、常量、类型都在 `neorv32_package.vhd` 中

---

## 四、与 VeriAI 模板的对照评估

### 4.1 SRS 模板 vs Neorv32 Data Sheet

| SRS 模板字段 | Neorv32 对应 | 评估 |
|-------------|-------------|------|
| FR（功能需求） | Key Features 列表 | ✅ 对齐良好 |
| NFR（非功能需求） | Configuration generics | ⚠️ SRS 缺乏"参数化配置"字段 |
| C（约束） | Top entity ports（接口约束） | ✅ 对齐良好 |
| 验证方式 | 文档中缺乏显式验证说明 | ❌ Neorv32 文档不包含验证方法 |
| 来源追溯 | 无（Neorv32 文档不需要） | N/A |
| RTM | 代码中的地址映射 | ⚠️ 隐式存在，非显式矩阵 |

### 4.2 HID 模板 vs Neorv32 Top Entity

| HID 模板字段 | Neorv32 对应 | 评估 |
|-------------|-------------|------|
| 端口列表 | Top entity ports（Name/Width/Direction/Description） | ✅ 格式一致 |
| 时钟域 | 未显式列出（全 SoC 单时钟） | ⚠️ Neorv32 单时钟域简化了这个 |
| 复位策略 | 未显式文档化 | ❌ HID 模板应增加复位行为描述 |
| 参数/泛型 | Configuration generics | ✅ 格式基本一致 |
| 中断映射 | CPU interrupts | ✅ 格式一致 |
| 寄存器映射 | Register map address table | ❌ HID 模板缺少寄存器映射节！ |

### 4.3 关键差距：VeriAI 模板缺失项

1. **寄存器映射子模板**：Neorv32 的寄存器表（Address/Name/Bits/Access/Reset/Description）是 VeriAI HID 模板最需要补充的内容
2. **参数化配置节**：Neorv32 的 Configuration generics 格式应在 SRS 中有对应
3. **寄存器位域文档**：每个 bit/field 的独立说明比整体寄存器描述更有用
4. **C 代码示例**：Neorv32 提供寄存器使用示例，VeriAI 可以生成等效的验证代码

---

## 五、对 VeriAI 的具体建议

### 5.1 HID 模板增强（基于 Neorv32 模板）

建议在 HID 模板中增加以下节：

```yaml
# 寄存器映射（新增）
registers:
  - address: 0xFFFFFF80
    name: CTRL
    description: "控制寄存器"
    fields:
      - bits: "0"
        name: "enable"
        access: rw
        reset: 0
        description: "模块使能"
      - bits: "2:1"
        name: "mode"
        access: rw
        reset: 0
        description: "工作模式"

# 参数化配置（增强）
parameters:
  - name: FIFO_DEPTH
    type: integer
    default: 4
    description: "FIFO 深度（0=无 FIFO）"
    constraint: "0 或 2 的幂"

# 中断映射（增强）
interrupts:
  - name: "spi_irq"
    channel: 2
    type: "fast"
    description: "SPI 传输完成中断"
```

### 5.2 SRS 模板增强

```markdown
## 参数化需求（新增）

| 参数 | 类型 | 默认值 | 约束 | 对应需求 |
|------|------|--------|------|---------|
| FIFO_DEPTH | integer | 4 | 0 或 2 的幂 | NFR-003 (资源可配置) |
```

### 5.3 模块组织模板

Neorv32 的"一个外设一个文件 + 全局 package 集中定义"模式，可以直接作为 VeriAI RTL Agent 的模块生成组织策略。

---

## 六、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：Neorv32 文档模板分析、SoC 模块拆分、与 VeriAI 模板对照评估 |
