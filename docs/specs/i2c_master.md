# 任务书模板（Spec Template）— i2c_master

```yaml
---
# ====== 元信息 ======
module_name: i2c_master
version: 0.1.0
author: "VeriAI Phase 9 Batch 1"
created_at: 2026-04-29
target_device: xc7vx485t-2ffg1761
toolchain:
  synth: vivado-2023.2
  sim:   iverilog

# ====== 性能指标 ======
performance:
  clock_freq_mhz: 100
  throughput: "I2C_FREQ 100kHz or 400kHz"
  latency_cycles: 1
  resource_budget:
    lut: 500
    ff:  300
    bram: 0
    dsp: 0

# ====== 约束 ======
constraints:
  synthesizable: true
  language: verilog-2001
  coding_style: lowrisc
  power_domain: single

# ====== 验收标准 ======
acceptance:
  sim_coverage_min: 0.85
  fmax_mhz_min: 100
  regression_cases: [reset, single_write, single_read, back_to_back, nack_detection, clock_stretching, all_256_bytes]
---
```

---

## 一、功能描述

参数化 I2C 主控制器，生成 SCL 时钟并控制 SDA 双向数据线，实现标准 I2C 总线协议。

- 支持标准模式 (100kHz) 和快速模式 (400kHz)，通过 `I2C_FREQ` 参数配置
- 7 位从设备寻址，自动生成 START / STOP / REPEATED START 条件
- 逐字节读写：每次 `tx_start` 发送一个字节，包含自动 ACK 检测；读操作时自动发送 ACK/NACK
- SCL 时钟拉伸检测：从设备拉低 SCL 时主设备等待
- 总线忙检测：SDA 被拉低时判定为总线忙
- 完整的 ACK/NACK 错误报告
- 遵循 Verilog-2001 可综合子集，单时钟域，同步低有效复位

## 二、接口预期（高层）

| 接口名 | 类型 | 说明 |
|--------|------|------|
| clk / rst_n | 时钟+复位 | 系统时钟，同步低有效复位 |
| scl | 双向 | I2C 时钟线，开漏输出 + 输入检测（拉伸） |
| sda | 双向 | I2C 数据线，开漏输出 + 输入采样 |
| cmd[2:0] | 输入 | 命令：START / STOP / WRITE / READ_ACK / READ_NACK |
| cmd_start | 输入 | 命令启动脉冲（busy 时忽略） |
| dev_addr[6:0] | 输入 | 7 位从设备地址 |
| tx_data[7:0] | 输入 | 待发送数据字节 |
| rx_data[7:0] | 输出 | 接收数据字节 |
| rx_valid | 输出 | 接收有效脉冲（读命令完成或写 ACK 返回） |
| ack_err | 输出 | NACK 检测标志（与 rx_valid 同时有效） |
| busy | 输出 | 操作进行中标志 |

## 三、性能与资源说明

- SCL 周期 = `(CLK_FREQ / I2C_FREQ) * clk` 周期，四等分相位驱动 SCL
- 每字节传输 = 9 个 SCL 周期（8 data + 1 ACK），加 START/STOP 开销
- 预期资源：<500 LUT，<300 FF，无需 BRAM 或 DSP

## 四、特殊约束与边界条件

- 复位策略：全同步复位（rst_n 低有效）
- 时钟域数量：单时钟域
- scl/sda 为开漏信号，在 FPGA 内部建模为 `output reg` + `input wire`，外部需上拉电阻
- 时钟拉伸：若 scl 被从设备拉低超过 (CLK_DIV * 4) 周期，继续等待（无限等待）
- 总线仲裁：本版本不支持多主设备仲裁
- 异常处理：
  - NACK 在地址阶段：自动发 STOP，置 ack_err=1
  - NACK 在数据阶段：置 ack_err=1，等待下一步命令
  - 虚假 START：SDA 下降沿采样到 SCL 为低时，判定为总线忙

## 五、参考与对标

- 参考实现：Neorv32 I2C (`rtl/core/neorv32_twi.vhd`)，LiteX I2C (`litex/soc/cores/i2c.py`)
- 对标规范：I2C-bus specification v6.0 (NXP)
- VeriAI 寄存器映射模板（Neorv32 风格）

## 六、备注

本模块不包含内部 FIFO，字节流控由上层逻辑管理。金标准模块聚焦于协议状态机的正确性和边界行为完整性。

---

## 七、修订记录

| 日期 | 版本 | 修订触发源 | 修订内容摘要 | 关联 SRS 修订建议 | 作者 |
|------|------|-----------|-------------|-------------------|------|
| 2026-04-29 | 0.1.0 | — | Phase 9 Batch 1 初稿 | — | VeriAI |
