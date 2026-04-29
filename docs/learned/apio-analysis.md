# apio 工具链分析

> 日期：2026-04-28 | 来源：apio CLI、oss-cad-suite 工具链、78 个示例项目、82 个板级定义 | 对 VeriAI 用途：目标板约束数据库、项目模板、测试框架参考

---

## 一、apio 架构概述

```
apio CLI
├── packages/         # 工具链管理
│   ├── oss-cad-suite # yosys + nextpnr + iverilog + icepack
│   ├── definitions   # 82 个板级定义 + FPGA 定义
│   ├── examples      # 78 个示例项目
│   └── verible       # SystemVerilog lint/format
├── 命令层
│   ├── build         # 综合 + 布局布线 + 比特流
│   ├── sim / test    # 仿真 / 批量测试
│   ├── lint / format # 代码检查
│   ├── upload        # 下载到 FPGA
│   └── examples      # 示例管理
└── 项目结构 (apio.ini + .v + .pcf)
```

---

## 二、项目结构模式

### 2.1 标准项目布局

```
project/
├── apio.ini        # 项目配置（必须）
├── *.v             # Verilog 源文件
├── pinout.pcf      # 物理约束（引脚映射）
├── *_tb.v          # Testbench 文件
└── *_tb.gtkw       # GTKWave 波形配置（可选）
```

### 2.2 apio.ini 格式

```ini
[env:default]
board = alhambra-ii
top-module = main
default-testbench = main_tb.v
```

### 2.3 子目录组织（bcd-counter 示例）

```
bcd-counter/
├── main.v              # 顶层模块
├── main_tb.v           # 顶层 testbench
├── bcd/
│   ├── bcd_digit.v     # BCD 数字模块
│   └── bcd_digit_tb.v  # 子模块 testbench
├── util/
│   ├── ticker.v        # 时钟分频
│   ├── ticker_tb.v     # 分频 testbench
│   ├── reset_gen.v     # 复位生成
└── testing/
    └── apio_testing.vh # 测试宏定义
```

**核心洞见**：每个功能模块独立目录，自带 testbench。这是 VeriAI 可以借鉴的模块组织模式。

---

## 三、板级约束系统

### 3.1 三层定义

```
Board (boards.jsonc)        FPGA (fpgas.jsonc)
├── alhambra-ii ──────────→ ice40hx4k-tq144-8k
├── icebreaker ───────────→ ice40up5k-sg48
├── go-board ─────────────→ ice40hx1k-vq100
├── colorlight-5a-75b-v8 → lfe5u-25f-6bg256c
└── sipeed-tang-nano-9k ─→ gw1nr-lv9qn88pc6/i5
                                 │
                                 ▼
                          PCF 约束文件（引脚映射）
```

### 3.2 PCF 约束格式

```
# 时钟
set_io -nowarn CLK 49  # input

# LED
set_io -nowarn LED7 37  # output

# 按钮
set_io -nowarn SW1 34   # input

# UART
set_io -nowarn TX 61    # output
set_io -nowarn RX 62    # input
```

### 3.3 FPGA 家族分布

| 家族 | 型号 | 开发板数 | 典型 LUT |
|------|------|---------|---------|
| iCE40 HX | ICE40HX1K/4K/8K | ~25 | 1K-8K |
| iCE40 UP | ICE40UP5K | ~12 | 5K |
| iCE40 LP | ICE40LP1K/8K | ~5 | 1K-8K |
| ECP5 | LFE5U-12F/25F/45F/85F | ~20 | 12K-85K |
| Gowin | GW1N/GW1NR/GW2AR | ~8 | 1K-18K |

---

## 四、示例分类（VeriAI 入门推荐 Top 10）

### 入门级（零基础可用）

| # | 示例 | 知识点 | 适合场景 |
|---|------|--------|---------|
| 1 | alhambra-ii/ledon | 端口赋值、引脚约束 | 第一个 FPGA 项目 |
| 2 | icebreaker/led-green | 单 LED 控制 | 验证工具链 |
| 3 | alhambra-ii/blinky | 计数器、时钟分频 | 理解时序 |
| 4 | icezum/wire | 连续赋值 | 组合逻辑入门 |
| 5 | go-board/leds | 多端口控制 | 总线概念 |

### 进阶级（有基础）

| # | 示例 | 知识点 | 适合场景 |
|---|------|--------|---------|
| 6 | icebreaker/buttons | 输入去抖、条件控制 | 交互式设计 |
| 7 | alhambra-ii/bcd-counter | 层次化设计、多 testbench | 模块化设计 |
| 8 | tinyfpga-bx/clock-divider | 分频器、相位输出 | 时钟域基础 |

### 高级

| # | 示例 | 知识点 | 适合场景 |
|---|------|--------|---------|
| 9 | alhambra-ii/pll | PLL 配置 | 高级时钟管理 |
| 10 | alhambra-ii/speed-test | 时序收敛、最大频率 | 时序优化 |

---

## 五、测试框架

### 5.1 宏系统

```verilog
`include "testing/apio_testing.vh"
`DEF_CLK                    // 自动生成 clk 信号
`TEST_BEGIN(main_tb)        // 测试开始
`CLKS(400)                  // 运行 400 个时钟周期
`EXPECT(leds, 'h31)         // 断言期望值
`TEST_END                   // 测试结束
```

### 5.2 测试组织模式

- 每个模块有独立 testbench
- 顶层 testbench 通过参数加速仿真（如 `DIV(3)` 替代 `DIV(12000000)`）
- apio test 自动发现并运行所有 `*_tb.v`

---

## 六、对 VeriAI 的价值

### 6.1 立即可用

| 资源 | 格式 | VeriAI 用途 |
|------|------|-----------|
| 82 个板级定义 | `data/boards/apio_boards.csv` | 目标板约束自动匹配 |
| PCF 格式 | `set_io -nowarn <name> <pin> # <dir>` | 约束文件自动生成模板 |
| apio.ini | INI 格式 | 项目配置自动生成 |
| 测试宏 | `testing/apio_testing.vh` | 验证模板 |
| 层次化结构 | bcd/util/testing 子目录 | 模块组织模板 |

### 6.2 可以建立的自动化

1. **从 SRS 板卡选择 → 自动匹配 PCF 约束**：根据 SRS 中声明的目标板，从 82 个板级定义中匹配引脚映射
2. **项目脚手架生成**：`apio create` + 模板文件 = VeriAI 的项目初始化模板
3. **验证宏模板**：`TEST_BEGIN` / `EXPECT` / `TEST_END` 可以直接作为 VeriAI testbench 生成的框架

### 6.3 建议的 VeriAI 集成点

```
SRS: 目标板 = alhambra-ii
    │
    ▼
data/boards/apio_boards.csv → ice40hx4k-tq144-8k
    │
    ▼
自动生成 apio.ini  +  pinout.pcf 模板
    │
    ▼
VeriAI RTL 生成 → main.v (端口匹配 PCF 引脚名)
```

---

## 七、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：apio 架构、82 板级约束、78 示例分类、测试框架分析 |
