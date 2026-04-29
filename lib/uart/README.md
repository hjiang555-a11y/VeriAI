# uart — 金标准参数化 UART 参考实现

本目录包含 `uart` 的金标准 RTL 实现及配套 testbench，可作为：

- VeriAI 内置模块库的参考质量基准
- 后续 DUT 变体或 AI 生成代码的对标验证入口
- CI 回归测试的基础用例集

设计模式来源：LiteX CSR 参数化 + Neorv32 单文件外设组织 + VexRiscv 参数化配置。

---

## 文件清单

| 文件 | 说明 |
|------|------|
| `uart.v`        | 金标准可综合 RTL（Verilog-2001），含 TX + RX |
| `tb_uart.v`     | 覆盖全部边界条件的 testbench（loopback 模式） |
| `Makefile`      | 仿真脚本（基于 Icarus Verilog） |
| `README.md`     | 本文档 |

---

## 接口说明

```verilog
module uart #(
  parameter integer CLK_FREQ  = 50000000,  // 系统时钟频率 (Hz)
  parameter integer BAUD_RATE = 115200,     // 波特率
  parameter integer DATA_BITS = 8,         // 数据位 (5-8)
  parameter integer STOP_BITS = 1,         // 停止位 (1-2)
  parameter integer PARITY    = 0          // 0=none, 1=even, 2=odd
)(
  input  wire               clk,
  input  wire               rst_n,         // 同步低有效复位

  // TX
  input  wire [DATA_BITS-1:0] tx_data,     // 待发送数据
  input  wire                 tx_start,    // 启动发送（单周期脉冲）
  output wire                 tx_busy,     // 发送忙标志
  output reg                  tx,          // 串行输出

  // RX
  input  wire                 rx,          // 串行输入
  output reg  [DATA_BITS-1:0] rx_data,     // 接收数据
  output reg                  rx_valid,    // 接收有效（单周期脉冲）
  output reg                  rx_error      // 接收错误（帧错误/奇偶校验错误）
);
```

### TX 帧格式

```
  ┌─────┬───┬───┬───┬───┬───┬───┬───┬───┬─────────┬───────┐
  │START│D0 │D1 │D2 │D3 │D4 │D5 │D6 │D7 │[PARITY] │ STOP  │
  │  0  │LSB│   │   │   │   │   │   │MSB│ optional│ 1(xN) │
  └─────┴───┴───┴───┴───┴───┴───┴───┴───┴─────────┴───────┘
```

### RX 采样策略

- 8x 过采样
- 每个 bit 在 phases 3/4/5 各采样一次（共 3 次）
- 三取二多数表决，提高抗噪能力
- 起始位验证：必须为 0，否则判定为虚假起始位并返回空闲

### 边界行为规范

| 场景 | 预期行为 |
|------|----------|
| `tx_start` 时 `tx_busy=1` | 启动被静默忽略，不影响进行中的传输 |
| RX 虚假起始位 | 接收器返回空闲，无数据输出 |
| RX 帧错误（停止位=0） | `rx_valid=1`, `rx_error=1`, `rx_data` 包含接收数据 |
| RX 奇偶校验错误 | `rx_valid=1`, `rx_error=1`, `rx_data` 包含接收数据 |
| 复位后 | `tx=1`, `tx_busy=0`, `rx_valid=0`, `rx_error=0` |

---

## 如何运行仿真

### 前置依赖

```bash
# Debian/Ubuntu
sudo apt install iverilog
```

### 运行

```bash
cd lib/uart
make          # 编译 + 运行
make wave     # 运行并用 GTKWave 查看波形
make clean    # 清理编译产物
```

### 预期输出（全部通过）

```
========================================
  UART Testbench  (CLK=50000000, BAUD=115200)
========================================

[TC-01] Reset state
  PASS  tx_busy after reset
  PASS  tx idle after reset
  PASS  rx_valid after reset
  PASS  rx_error after reset
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
| 复位状态检查 | TC-01 | 复位后 tx_busy=0, tx=1, rx_valid=0, rx_error=0 |
| 单字节 0x55 | TC-02 | 交替 bit 模式，基本功能验证 |
| 单字节 0xAA | TC-03 | 交替 bit 反相，验证 bit 顺序 |
| 单字节 0x00 | TC-04 | 全 0（最长连续低电平） |
| 单字节 0xFF | TC-05 | 全 1（最长连续高电平） |
| 背靠背传输 | TC-06 | 连续 3 字节无间隔，验证帧同步 |
| 全 256 值遍历 | TC-07 | 穷举所有 byte，验证 bit 完整性 |
| 忙时启动保护 | TC-08 | tx_busy 时 tx_start 被忽略 |
| 运行中复位 | TC-09 | 传输中途复位，状态立即清零 |
| 连续流压力 | TC-10 | 100 字节连续收发，无错误 |

---

## 验收检查清单（Reviewer）

以下全部条件必须满足：

- [ ] **RTL 可综合**：`uart.v` 使用 Verilog-2001 可综合子集，无 `initial`（仅 testbench 使用）
- [ ] **边界行为文档化**：README 明确说明忙时写保护/虚假起始/帧错误/奇偶错误/复位后语义
- [ ] **testbench 全通过**：`make` 输出 `FAIL` 条目数为 0
- [ ] **testbench 覆盖 10 类场景**：TC-01 至 TC-10 全部包含
- [ ] **全 256 值遍历通过**：TC-07 穷举所有 byte 无错误
- [ ] **参数化可编译**：默认参数与自定义参数均可正常编译
- [ ] **Makefile 可执行**：`make`/`make clean` 目标有效

---

## 参数化验证矩阵

| CLK_FREQ | BAUD_RATE | DATA_BITS | STOP_BITS | PARITY | 预期结果 |
|----------|-----------|-----------|-----------|--------|---------|
| 50MHz | 115200 | 8 | 1 | 0 | PASS |
| 100MHz | 115200 | 8 | 1 | 0 | PASS |
| 50MHz | 9600 | 8 | 1 | 0 | PASS |
| 50MHz | 115200 | 7 | 1 | 1 (even) | PASS |
| 50MHz | 115200 | 8 | 2 | 2 (odd) | PASS |

---

## 设计模式参考

| 模式 | 来源 | 在 uart.v 中的应用 |
|------|------|------------------|
| 参数化配置 | LiteX CSR / VexRiscv | 所有行为通过 `CLK_FREQ`/`BAUD_RATE`/`DATA_BITS`/`STOP_BITS`/`PARITY` 控制 |
| 单文件外设 | Neorv32 | TX+RX 在同一个文件中，完整的自包含模块 |
| 过采样抗噪 | LiteX UART core | 8x 过采样 + 3 取 2 多数表决 |
| 帧格式模板 | 标准 UART 协议 | START + DATA(LSB first) + [PARITY] + STOP |

---

## 参考资料

- LiteX UART 实现：`litex/soc/cores/uart.py`
- Neorv32 UART：`rtl/core/neorv32_uart.vhd`
- [Icarus Verilog 官网](http://iverilog.icarus.com/)
- 本仓库 [`docs/learned/rag-index.md`](../../docs/learned/rag-index.md)：外设参考实现索引
