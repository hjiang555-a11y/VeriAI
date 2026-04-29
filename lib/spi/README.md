# spi_master — 金标准参数化 SPI 主控制器

本目录包含 `spi_master` 的金标准 RTL 实现及配套 testbench，可作为：

- VeriAI 内置模块库的串行外设接口参考基准
- 后续 SPI 变体或 AI 生成代码的对标验证入口
- 验证全套 CPOL/CPHA 模式兼容性

---

## 文件清单

| 文件 | 说明 |
|------|------|
| `spi_master.v`    | 金标准可综合 RTL（Verilog-2001） |
| `tb_spi_master.v` | 覆盖全部 CPOL/CPHA 模式和边界条件的 testbench |
| `Makefile`        | 仿真脚本（基于 Icarus Verilog） |
| `README.md`       | 本文档 |

---

## 接口说明

```verilog
module spi_master #(
  parameter integer DATA_WIDTH = 8,   // 每帧数据位宽 (1-32)
  parameter integer CLK_DIV    = 4,   // SCLK 半周期 = CLK_DIV 个 clk 周期
  parameter integer CPOL       = 0,   // 0=空闲低, 1=空闲高
  parameter integer CPHA       = 0    // 0=前沿采样, 1=后沿采样
)(
  input  wire                      clk,
  input  wire                      rst_n,
  input  wire [DATA_WIDTH-1:0]     tx_data,
  input  wire                      tx_start,   // 单周期脉冲，busy 期间忽略
  output reg  [DATA_WIDTH-1:0]     rx_data,
  output reg                       rx_valid,   // 单周期脉冲
  output reg                       busy,
  output wire                      sclk,
  output reg                       mosi,
  input  wire                      miso,
  output reg                       cs_n        // 传输期间低有效
);
```

### 传输时序

```
CPHA=0:  cs_n ──┐                          ┌──
        sclk  ──┘_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\──
        mosi  ──X──D7─X─D6─X─D5─X─D4─X─D3─X─D2─X─D1─X─D0──X──
                   ↑ sample                 ↑ sample (last)
        miso  ···X··Q7··X··Q6··X··Q5··X··Q4··X··Q3··X··Q2··X··Q1··X··Q0··X···

CPHA=1:  cs_n ──┐                          ┌──
        sclk  ──┘\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\──
        mosi  ──X─D7─X─D6─X─D5─X─D4─X─D3─X─D2─X─D1─X─D0─X──
                    ↑ sample                 ↑ sample (last)
        miso  ···─X─Q7··X─Q6··X─Q5··X─Q4··X─Q3··X─Q2··X─Q1··X─Q0··X─
```

### 边界行为规范

| 场景 | 预期行为 |
|------|----------|
| `tx_start` 时 `busy=1` | 静默忽略，不打断当前传输 |
| 复位后 | `sclk=CPOL`, `cs_n=1`, `mosi=0`, `busy=0`, `rx_valid=0` |
| 传输中复位 | 立即中止，`cs_n` 释放，状态清零 |
| CPHA=0 传输开始 | MOSI 预驱动 MSB，CS 拉低，等待首个 SCLK 边沿 |
| CPHA=1 传输开始 | CS 拉低，首个 SCLK 边沿驱动 MSB |

---

## 如何运行仿真

```bash
cd lib/spi
make          # 编译 + 运行，终端输出 PASS/FAIL 摘要
make wave     # 运行并用 GTKWave 查看波形
make clean    # 清理编译产物
```

### 预期输出

```
========================================
  SPI Master Testbench  DATA=8 CLK_DIV=4
========================================

[TC-01] Reset state
  PASS  cs_n high after reset
  PASS  busy low after reset
...
========================================
  TOTAL: N PASS, 0 FAIL
========================================
  ALL TESTS PASSED
```

---

## 验证覆盖矩阵

| 测试用例 | 编号 | 覆盖场景 |
|----------|------|----------|
| 复位状态检查 | TC-01 | 复位后 cs_n=1, busy=0, sclk=CPOL, rx_valid=0 |
| 单字节 CPOL=0/CPHA=0 | TC-02 | 默认模式收发 0xA5→0x5A，数据正确 |
| 交替位模式 | TC-03 | 0x55/0xAA 交替位传输 |
| 全零数据 | TC-04 | 0x00 正常收发 |
| 全一数据 | TC-05 | 0xFF 正常收发 |
| 背靠背传输 | TC-06 | 连续 3 字节无间隔，各字节独立正确 |
| 忙时启动保护 | TC-07 | `busy=1` 期间 `tx_start` 被忽略 |
| 运行中复位 | TC-08 | 传输中途复位，状态立即清零 |
| 连续流压力 | TC-09 | 50 字节连续收发，逐一校验 |
| 从端接收验证 | TC-10 | 通过从端模型读取其移位寄存器，验证 MOSI 正确 |

---

## 验收检查清单

- [ ] **RTL 可综合**：`spi_master.v` 使用 Verilog-2001 可综合子集，无 `initial`
- [ ] **边界行为文档化**：README 明确说明忙时忽略/复位/CPHA 预驱动等语义
- [ ] **testbench 全通过**：`make` 输出 `FAIL` 条目数为 0
- [ ] **testbench 覆盖 10 类场景**：TC-01 至 TC-10 全部包含
- [ ] **参数化验证**：默认参数 (DATA=8, CLK_DIV=4) 可正常编译
- [ ] **CPOL/CPHA 组合可编译**：所有 4 种模式实例化可正常编译
- [ ] **Makefile 可执行**：`make`/`make clean` 目标有效

---

## 设计模式参考

| 模式 | 来源 | 应用方式 |
|------|------|---------|
| 参数化配置 | VexRiscv | DATA_WIDTH/CLK_DIV/CPOL/CPHA 通过 parameter 控制 |
| 单文件外设 | Neorv32 | 完整的自包含 SPI 主控制器 |
| 边界行为文档化 | LiteX | 逐条列出忙时忽略/复位/模式差异 |

---

## 参考资料

- [Neorv32 SPI 实现](https://github.com/stnolting/neorv32) — VHDL 单文件 SPI 参考
- [SPI 协议规范](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) — CPOL/CPHA 定义
- 本仓库 [`docs/learned/rag-index.md`](../../docs/learned/rag-index.md)
