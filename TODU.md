# TODU - VeriAI 学习计划与后续任务

## 当前状态

Phase 1-5（文档对齐流程定义、Demo 实现、Agent 流程、RTM 追溯、React+TS 实现计划）已完成 ✅
Phase 6-8（FPGA 开源项目深度学习、RAG 知识库建设、文档模板迭代、学习路径编写）已完成 ✅
Phase 9（LLM 辅助金标准库扩展）进行中——已完成 spi_master 和 uart 的**手工基线**，Batch 1 (i2c_master, gpio) 已完成 RTL 与验证，仅余文档收尾。

VeriAI 已具备从**自然语言**出发，经**文档自动生成**与**需求对齐**，到**可综合 RTL** 的完整流水线框架。
**当前焦点**：用 VeriAI 自己的流水线加速金标准模块库建设（dogfooding）。

## 核心目标（已达成）

1. **自然语言驱动**：从中文自然语言描述出发，自动抽取 Spec/HID 结构化文本
2. **文档自动生成**：自动产出 Spec / SRS / HID 三大工程文档，满足软件可靠性设计规范
3. **文档对齐优先**：主动检测输入材料之间的不一致、缺失与歧义，闭环修订
4. **工程化可靠性**：RTM 双向追溯 + 一致性检查表 + 问题清单 + Baseline 判定
5. **RAG 知识库支撑**：从 FPGA 开源项目（LiteX/VexRiscv/apio/Neorv32）提取设计模式和参考实现

## 后续目标

- **LLM 辅助金标准库扩展**：用 VeriAI 自己的 Spec→RTL→验证 流水线来加速模块库建设，而非手工工程
- 基于合格 SRS 自动生成完整 RTL/验证用例的端到端流水线
- Docker 部署

---

## 金标准库扩展效率复盘

**已完成模块**：sync_fifo（基线）、spi_master、uart

**问题根因**：扩展过程是传统手工硬件工程，而非 LLM 辅助生成。具体表现：

| 瓶颈 | 表现 |
|------|------|
| RTL 手写 | 每个模块从零手写 150-250 行 Verilog，没有从 Spec 模板→LLM 生成的链路 |
| Testbench 调试 | 每个模块独立写 200+ 行 testbench + slave model，时序 debug 占大部分时间 |
| 文档手写 | README/验证矩阵/验收清单全部手工编辑，没有从 RTL 接口自动派生 |
| 模式浪费 | Phase 6 提取的设计模式（rag-index.md）只作为注释引用，未驱动生成 |
| 无流水线复用 | 三个模块各做各的，没有形成可复用的生成脚本或 prompt 模板 |

**核心矛盾**：VeriAI 的目标是用 AI 加速 FPGA 开发，但建设金标准库的过程完全没有用 AI。

**修正方向**：金标准库扩展本身必须 dogfood VeriAI 的 Spec→RTL→验证 流水线。

---

## Phase 6：FPGA 开源项目深度学习（按优先级执行）

### 6.1 LiteX — SoC 构建器 ★★★★★

- [x] 搭建 LiteX 开发环境，跑通最小 SoC ✅（Murax / VexRiscv + LiteX）
- [x] 学习其 Python DSL 到 Verilog 的生成链路 ✅：Migen → Verilog → 综合
- [x] 提取 Wishbone/AXI-Lite 总线桥接模式 ✅，整理为 VeriAI 可引用的设计模板
- [x] 将 LiteX 项目结构、模块组织方式录入 RAG 知识库 ✅
- [x] 分析其 CSR 自动生成机制，评估是否可作为 VeriAI ✅ "配置寄存器自动生成"功能的参考

**产出**：
- `docs/learned/litex-architecture.md` — LiteX 架构分析与设计模式总结
- `examples/litex/` — 可独立运行的最小 SoC 示例

### 6.2 VexRiscv — FPGA 优化级 RISC-V 核 ★★★★★

- [x] 理解 SpinalHDL 参数化生成 RISC-V 流水线的方法 ✅
- [x] 提取 5 级流水线的参数化设计模式 ✅（如何用参数控制面积/性能权衡）
- [x] 分析其与 LiteX 的集成方式，总结"CPU 核 + 总线 + 外设"的松耦合设计模式 ✅
- [x] 将其参数化模块设计方法整理为 VeriAI 可学习的生成策略 ✅

**产出**：
- `docs/learned/vexriscv-design-patterns.md` — 参数化 CPU 设计模式
- `lib/cpu/` 目录下参考设计笔记

### 6.3 FPGAwars/apio — 工具链 + 示例集合 ★★★★★

- [x] 搭建 apio 工具链，跑通 3 个以上示例项目 ✅
- [x] 提取 80+ 开发板的约束模板 ✅（时钟、复位、引脚），建立 VeriAI 目标板数据库
- [x] 将其 60+ 示例按难度分级，选出适合作为 VeriAI 入门示例的 10 个 ✅
- [x] 分析 apio 的工程管理结构，作为 VeriAI 项目模板的参考 ✅

**产出**：
- `data/boards/` — 目标板约束数据库（从 apio 提取）
- `examples/apio/` — 精选入门示例 + VeriAI 分析注释

### 6.4 Neorv32 — 文档标杆级 RISC-V SoC ★★★★

- [x] 通读 Neorv32 数据手册 ✅（Data Sheet），学习其文档组织方式
- [x] 提取其"每个外设 → 独立章节 + 寄存器表 + 时序图 + 代码示例"的文档模板 ✅
- [x] 对照其文档，评估 VeriAI SRS 模板与 HID 模板的完善度 ✅
- [x] 将其 SoC 级模块拆分方式整理为"中规模模块拆解"参考模式 ✅

**产出**：
- `docs/learned/neorv32-doc-analysis.md` — Neorv32 文档质量分析
- 对 VeriAI 文档模板的修订建议

### 6.5 OpenFPGA — 学术级 FPGA 架构生成器 ★★★★

- [x] 了解 OpenFPGA 的 FPGA 架构描述方法 ✅（XML-based architecture description）
- [x] 评估其作为 VeriAI "多目标 FPGA 架构"后端的可行性 ✅
- [x] 提取其可编程互连建模方法，作为 VeriAI 综合约束生成的参考 ✅

**产出**：
- `docs/learned/openfpga-analysis.md` — 可行性评估与架构参考

---

## Phase 7：知识库与示例库建设

### 7.1 RAG 知识库建设

- [x] 将 Phase 6 所有学习笔记的结构化摘要录入 RAG 知识库 ✅
- [x] 建立"设计模式 → VeriAI 可引用模板"的映射表 ✅
- [x] 建立"常见外设 → 参考实现来源"的索引表 ✅

### 7.2 示例库扩展

- [x] 将 apio 精选示例适配到 VeriAI 项目结构 ✅
- [x] 为每个示例添加 VeriAI 分析注释 ✅（模块树、数据流、关键信号）
- [x] 建立示例难度分级体系 ✅（入门 / 进阶 / 高级）

### 7.3 模块库扩展 — 设计模式提取

- [x] 从学习项目中提取高质量外设设计模式 ✅（DMA、Ethernet、UART、SPI）
- [x] spi_master 金标准模块 ✅（手工方式，已作为对照基线）
- [x] uart 金标准模块 ✅（手工方式，已作为对照基线）

> **注意**：后续金标准模块扩展已迁移到 Phase 9 的 LLM 辅助流水线。Phase 7.3 保留 spi_master 和 uart 作为手工基线的对照样本。

---

## Phase 8：教学路径与文档

### 8.1 VeriAI 推荐学习路径

- [x] 编写"VeriAI + apio + LiteX"三步入门路径 ✅
  1. apio → 快速上手 FPGA 开发流程
  2. LiteX → 理解 SoC 构建方法
  3. VeriAI → 用 AI 加速从 Spec 到 RTL 的过程
- [x] 编写路径中每步的学习目标与验证方式 ✅

### 8.2 文档模板迭代

- [x] 基于 Neorv32 文档风格，优化 SRS 模板和 HID 模板 ✅
- [x] 增加"寄存器映射"标准化子模板 ✅
- [x] 增加"时序图"标准化描述规范 ✅

---

## Phase 9：LLM 辅助金标准库扩展（优化后流水线）

### 9.0 核心原则

**用 VeriAI 自己的流水线建设金标准库**。每个模块走完整链路：

```
Spec 模板 ──→ HID 模板 ──→ LLM 生成 RTL ──→ LLM 生成 testbench
                                              │
                                              v
                                         仿真验证 ←── 失败: LLM 自修复（附错误日志）
                                              │
                                              v 通过
                                         README 自动生成
```

与手工方式的关键差异：

| 维度 | 旧方式（❌） | 新方式（✅） |
|------|------------|------------|
| RTL 来源 | 手写 Verilog | LLM 从 Spec+HID+设计模式生成 |
| Testbench 来源 | 手写边界用例 | LLM 从 HID 接口 + 边界行为规范生成 |
| 调试方式 | 人工看波形修 RTL | 仿真错误日志回传 LLM，自动迭代修复 |
| 文档来源 | 手工编辑 README | 从 RTL 接口 + 验证结果自动生成 |
| 模式利用 | 仅作为注释引用 | 注入 prompt 上下文，驱动生成 |
| 单模块周期 | 天级 | 目标：小时级 |

### 9.1 单模块标准化流水线

每一步均可独立验证，失败时回到上一步。

```
步骤 1: 编写 Spec + HID
  输入: 外设协议标准 (UART/SPI/I2C spec) + Neorv32 文档模式
  产出: docs/templates/<module>_spec.md + <module>_hid.yaml
  验证: 人工审查 Spec/HID 完整性和正确性

步骤 2: LLM 生成 RTL
  输入: Spec + HID + rag-index.md 设计模式 + sync_fifo.v 风格参考
  产出: lib/<module>/<module>.v
  验证: iverilog -g2012 -Wall 编译通过，无 latch/warning

步骤 3: LLM 生成 testbench
  输入: HID 接口定义 + Spec 边界行为表 + tb_sync_fifo.v 结构参考
  产出: lib/<module>/tb_<module>.v
  验证: 编译通过，仿真无无限循环

步骤 4: 仿真 + 自动修复循环
  运行: make
  若 FAIL:
    将失败日志 + RTL 源码 + testbench 源码回传 LLM
    LLM 输出修复后的 RTL 或 testbench
    重新 make，最多 5 轮
  验证: make 输出 ALL TESTS PASSED

步骤 5: README 自动生成
  输入: RTL 接口（module 声明 + 注释头）+ 验证结果摘要
  产出: lib/<module>/README.md
  验证: 人工确认验收检查清单完整
```

### 9.2 Batch 生成策略

**每个 prompt 一次性生成 RTL + testbench + Makefile + README 四个文件的初稿**，而非分步请求。理由：
- 减少 LLM 往返次数
- LLM 在同一个上下文中理解模块契约 → 更一致的输出
- testbench 和 RTL 的接口一致性在同期保证

Prompt 结构：
```
System: VeriAI 金标准 FPGA 模块生成 Agent
  角色: 参数化 Verilog RTL 设计专家
  约束: Verilog-2001 可综合子集, 风格对齐 sync_fifo.v, 必须带设计模式注释头
  输入材料:
    - Spec: {{ spec_content }}
    - HID: {{ hid_yaml }}
    - 参考设计模式: {{ rag_index_excerpt }}
    - 参考代码风格: {{ sync_fifo_rtl }}
    - 参考 testbench 结构: {{ tb_sync_fifo }}

  输出要求: 一次性产出 4 个文件
    1. <module>.v      — 可综合 RTL + 完整的参数/端口/边界行为注释头
    2. tb_<module>.v   — testbench, 10+ 边界场景, slave/loopback 模型, PASS/FAIL 计数
    3. Makefile         — iverilog 仿真脚本
    4. README.md        — 接口说明 + 验证覆盖矩阵 + 验收检查清单
```

### 9.3 模块优先级与批次

按复杂度和依赖关系排定批次：

| 批次 | 模块 | 复杂度 | 状态 | 预计 prompt 数 |
|------|------|:---:|------|:---:|
| Batch 0 | sync_fifo | ★★ | ✅ 手工基线 | —（对照组） |
| Batch 0.5 | spi_master | ★★★ | ✅ 手工基线 | —（对照组） |
| Batch 0.5 | uart | ★★★ | ✅ 手工基线 | —（对照组） |
| Batch 1 | i2c_master | ★★★ | ✅ | 1 次生成 + ≤5 轮修复 |
| Batch 1 | gpio | ★★ | ✅ | 1 次生成 + ≤3 轮修复 |
| Batch 2 | pwm | ★★ | ⬜ | 1 次生成 + ≤3 轮修复 |
| Batch 2 | timer | ★★★ | ⬜ | 1 次生成 + ≤5 轮修复 |
| Batch 3 | simple_dma | ★★★★ | ⬜ | 2 次生成 + ≤5 轮修复 |
| Batch 3 | wb_arbiter | ★★★ | ⬜ | 1 次生成 + ≤5 轮修复 |
| Batch 4 | ethernet_mac | ★★★★★ | ⬜ | 分步生成，先 MAC 后 FIFO 集成 |

> **为什么 i2c_master 和 gpio 先做？**
> - i2c 是 SPI/UART 之后最常用的串行总线，对比三个手工模块可以验证 LLM 生成质量
> - gpio 是最简单的 I/O 模块，适合验证流水线在低复杂度场景的效率
> - 这两个模块成功后，可以对比"手工 vs LLM 辅助"的实际效率差异

### 9.4 效率度量

每个模块记录以下数据，用于迭代改进 prompt：

| 指标 | 手工基线 (sync_fifo) | 新方式目标 | 实际 |
|------|:---:|:---:|:---:|
| 首次生成可编译率 | — | >70% | |
| 仿真首次通过率 | — | >30% | |
| 自动修复轮数 | — | ≤3 | |
| 人工介入时间 | ~N 小时 | <1 小时 | |
| 总周期 | ~N 天 | ~2 小时 | |

> 手工基线数据从 sync_fifo/spi_master/uart 的实际耗时回填，用于量化对比。

### 9.5 迭代改进循环

每完成一个批次后做一次复盘：

1. **分析 FAIL 模式**：哪些类型的 bug LLM 反复修不好？
2. **改进 prompt**：是否需要增加约束、风格示例、或边界行为规范？
3. **更新模板**：Spec/HID 模板是否有遗漏的关键字段？
4. **决定下一批策略**：是否需要为特定模块类型设计专门的 prompt？

---

## 辅助项目（按需探索）

| 项目 | 探索重点 | 时机 |
|------|---------|------|
| linux-on-litex-vexriscv | 完整 Linux SoC 集成的复杂度参考 | Phase 6.1 完成后 |
| Arty-A7-FPGA-Projects | 实用 7 系列项目模式提取 | Phase 6.3 完成后 |
| Fomu + foboot | 极致小型化开源栈参考 | 按需 |
| os-fpga/open-source-fpga-resource | 开源 FPGA 资源导航，补充 resources.md | 持续 |

---

## 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.2.0 | 归档 Phase 1-5（已完成），新增 Phase 6-8 FPGA 开源项目学习计划 |
| 2026-04-29 | 0.3.0 | 金标准库扩展效率复盘；Phase 7.3 模块库扩展迁移到 Phase 9 LLM 辅助流水线；新增 Phase 9 单模块标准化流水线 + batch 策略 + 效率度量 |
