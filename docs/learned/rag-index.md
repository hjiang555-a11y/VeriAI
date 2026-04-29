# VeriAI 设计模式索引

> 从 Phase 6 深度学习项目中提取的、可供 VeriAI Agent 引用的设计模式。
> 每条模式均注明来源项目、对 VeriAI 的适用场景，以及可引用的代码模板位置。

---

## 一、设计模式 → VeriAI 模板映射

| 设计模式 | 来源 | 核心思想 | VeriAI 应用 | 模板位置 |
|---------|------|---------|-----------|---------|
| **插件化组合** | VexRiscv | CPU = 空流水线 + 插件列表 | SRS 需求 → 模块组合选择 | `docs/learned/vexriscv-design-patterns.md` §二 |
| **CSR 自动生成** | LiteX | 反射式寄存器树扁平化 + 字段级描述 | SRS → HID 寄存器映射 | `docs/learned/litex-architecture.md` §三 |
| **总线解耦** | LiteX + VexRiscv | 内部简单总线 → 适配器 → 外部标准总线 | 模块互联抽象层 | `docs/learned/litex-architecture.md` §四 |
| **外设文档模板** | Neorv32 | 元数据头 → 特性列表 → 寄存器表 → 代码示例 | HID 模板增强 | `docs/learned/neorv32-doc-analysis.md` §二 |
| **约束模板** | apio | PCF 引脚映射 + 板级定义数据库 | 目标板约束自动生成 | `docs/learned/apio-analysis.md` §三 |
| **层次化模块组织** | Neorv32 | 每外设一文件 + 全局 package 集中定义 | RTL Agent 模块组织 | `docs/learned/neorv32-doc-analysis.md` §三 |
| **Service 依赖注入** | VexRiscv | trait 接口 + 类型查找 | 模块间接口契约 | `docs/learned/vexriscv-design-patterns.md` §三 |
| **原子写入** | LiteX | CSRStorage atomic_write: 多地址原子更新 | 寄存器生成策略 | `docs/learned/litex-architecture.md` §三 |

---

## 二、常见外设 → 参考实现索引

| 外设 | 参考项目 | 源文件 | 关键特征 |
|------|---------|--------|---------|
| UART | LiteX | `litex/soc/cores/uart.py` | 参数化波特率、FIFO 深度 |
| SPI | Neorv32 | `rtl/core/neorv32_spi.vhd` | 单文件、完整文档 |
| GPIO | Neorv32 | `rtl/core/neorv32_gpio.vhd` | 输入/输出/中断 |
| PWM | Neorv32 | `rtl/core/neorv32_pwm.vhd` | 参数化通道数 |
| Timer | LiteX (SoCCore) | `timer_uptime` 特性 | 64-bit 运行时间 |
| I2C | LiteX | `litex/soc/cores/i2c.py` | 主从模式 |
| FIFO | VeriAI (金标准) | `lib/fifo/sync_fifo.v` | 参考基线和验证 |
| DMA | Neorv32 | `rtl/core/neorv32_dma.vhd` | 流式传输 |
| Watchdog | Neorv32 | `rtl/core/neorv32_wdt.vhd` | 参数化超时 |
| TRNG | Neorv32 | `rtl/core/neorv32_trng.vhd` | 真随机数 |

---

## 三、总线适配模板

| 源总线 | 目标总线 | 参考实现 | 适配文件 |
|--------|---------|---------|---------|
| 内部 SimpleBus | Wishbone | VexRiscv IBusSimple | `plugin/IBusSimplePlugin.scala` |
| 内部 SimpleBus | AXI4 | VexRiscv | `Axi4ReadOnly` 适配 |
| 内部 SimpleBus | AHB-Lite3 | VexRiscv | `AhbLite3Master` 适配 |
| Wishbone | CSR Bus | LiteX | `Wishbone2CSR` |
| Wishbone (wide) | Wishbone (narrow) | LiteX | `DownConverter/UpConverter` |

---

## 四、项目组织模板

### 4.1 apio 风格（单板项目）

```
project/
├── apio.ini           # 板 + 顶层模块
├── top.v              # 顶层
├── pinout.pcf         # 引脚约束
├── *_tb.v             # testbench
└── lib/               # 子模块
```

### 4.2 Neorv32 风格（多外设 SoC）

```
rtl/core/
├── package.vhd         # 全局常量/地址映射
├── top.vhd             # SoC 顶层
├── cpu.vhd             # CPU
├── bus.vhd             # 总线
├── gpio.vhd            # 每个外设一个文件
└── uart.vhd
```

### 4.3 VeriAI 推荐风格

```
src/rtl/<module>/
├── <module>.v          # 顶层
├── <module>_ctrl.v     # 控制逻辑
├── <module>_dp.v       # 数据通路
├── tb_<module>.v       # testbench
└── README.md           # 接口说明 + 验证覆盖
```

---

## 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：设计模式映射 + 外设索引 + 总线模板 + 项目组织模板 |
