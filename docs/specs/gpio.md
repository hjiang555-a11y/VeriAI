# 任务书模板（Spec Template）— gpio

```yaml
---
# ====== 元信息 ======
module_name: gpio
version: 0.1.0
author: "VeriAI Phase 9 Batch 1"
created_at: 2026-04-29
target_device: xc7vx485t-2ffg1761
toolchain:
  synth: vivado-2023.2
  sim:   iverilog

# ====== 性能指标 ======
performance:
  clock_freq_mhz: 200
  throughput: "1 read/write per cycle per pin"
  latency_cycles: 1
  resource_budget:
    lut: 100
    ff:  200
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
  sim_coverage_min: 0.90
  fmax_mhz_min: 200
  regression_cases: [reset, output_set, output_clear, input_read, direction_control, per_pin_independence, all_256_patterns]
---
```

---

## 一、功能描述

参数化通用输入输出（GPIO）模块，每个引脚可独立配置为输入或输出模式。

- `WIDTH` 参数控制引脚数量（默认 32）
- 输出寄存器：写 `out_data` 立即驱动对应引脚（仅当该引脚方向为 output 时驱动）
- 输入寄存器：读 `in_data` 返回当前引脚电平
- 方向控制：`dir` 寄存器，1=output，0=input
- 复位后所有引脚默认为输入（安全状态，避免总线冲突）
- 单时钟域，同步低有效复位

## 二、接口预期（高层）

| 接口名 | 类型 | 说明 |
|--------|------|------|
| clk / rst_n | 时钟+复位 | 系统时钟，同步低有效复位 |
| dir[WIDTH-1:0] | 输入 | 方向控制，1=output，0=input |
| out_data[WIDTH-1:0] | 输入 | 输出数据，dir=1 时驱动引脚 |
| in_data[WIDTH-1:0] | 输出 | 输入数据，反映当前引脚电平 |
| gpio_pins[WIDTH-1:0] | 双向 | 物理引脚，FPGA 上通过 IOBUF 连接 |

## 三、性能与资源说明

- 单周期读写延迟
- WIDTH=32 时预期资源：<100 LUT（IOBUF），<100 FF（输出+方向寄存器）
- 可级联多个 gpio 实例实现更宽位宽

## 四、特殊约束与边界条件

- 复位后所有引脚为输入（dir=0, out_data=0），gpio_pins 为高阻
- 方向切换瞬间：从 output→input 时，out_data 的最后值立即释放
- 不支持开漏或上拉/下拉配置（金标准范围外，后续变体扩展）
- 不支持中断生成（后续变体扩展）

## 五、参考与对标

- 参考实现：Neorv32 GPIO (`rtl/core/neorv32_gpio.vhd`)
- 对标规范：无特定协议标准

## 六、备注

gpio 是 Batch 1 中最简单的模块，用于验证 Phase 9 LLM 辅助流水线在低复杂度场景的效率和生成质量。作为"对照组"低复杂度样本，与 i2c_master 的中等复杂度形成对比。

---

## 七、修订记录

| 日期 | 版本 | 修订触发源 | 修订内容摘要 | 关联 SRS 修订建议 | 作者 |
|------|------|-----------|-------------|-------------------|------|
| 2026-04-29 | 0.1.0 | — | Phase 9 Batch 1 初稿 | — | VeriAI |
