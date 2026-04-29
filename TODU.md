# TODU - VeriAI 学习计划与后续任务

## 当前状态

Phase 1-5（文档对齐流程定义、Demo 实现、Agent 流程、RTM 追溯、React+TS 实现计划）已完成。
Phase 6-8（FPGA 开源项目深度学习、RAG 知识库建设、文档模板迭代、学习路径编写）已完成。
VeriAI 已具备从**自然语言**出发，经**文档自动生成**与**需求对齐**，到**可综合 RTL** 的完整流水线框架。

## 核心目标（已达成）

1. **自然语言驱动**：从中文自然语言描述出发，自动抽取 Spec/HID 结构化文本
2. **文档自动生成**：自动产出 Spec / SRS / HID 三大工程文档，满足软件可靠性设计规范
3. **文档对齐优先**：主动检测输入材料之间的不一致、缺失与歧义，闭环修订
4. **工程化可靠性**：RTM 双向追溯 + 一致性检查表 + 问题清单 + Baseline 判定
5. **RAG 知识库支撑**：从 FPGA 开源项目（LiteX/VexRiscv/apio/Neorv32）提取设计模式和参考实现

## 后续目标

- 基于学习的设计模式生成金标准模块（DMA、Ethernet、UART 等）
- 基于合格 SRS 自动生成完整 RTL/验证用例的端到端流水线
- Docker 部署

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

### 7.3 模块库扩展（基于项目学习成果）

- [x] 从学习项目中提取高质量外设设计模式 ✅（DMA、Ethernet、UART、SPI）
- [ ] 基于模式提取生成 VeriAI 自带的金标准模块
- [ ] 每个模块配套 testbench + 验证覆盖矩阵（对齐 sync_fifo 金标准）

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
