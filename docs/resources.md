# VeriAI 公开可信资源清单

本清单用于支撑 VeriAI 的"Verilog 模块库 + LLM 提示库 + 参考语料"，
所有资源均来自公开渠道，引用前请逐项核对 License。

> **License 红线**：主仓采用宽松许可（建议 Apache-2.0）。GPL/LGPL 类
> 资源不直接合并到主仓，只作为"对照实现"放入 `third_party/` 并保留
> 原 LICENSE 文件，或在 `lib/<module>/REFERENCE.md` 中以链接形式引用。

---

## A. 开源 Verilog / SystemVerilog 模块库

可作为 `lib/` 内置模块的参考与对标实现。

| 名称 | 链接 | License | 用途 / 备注 |
|------|------|---------|-------------|
| OpenCores | https://opencores.org | 多为 LGPL / BSD（逐项核对） | FIFO、UART、SPI、I2C、AXI 等基础 IP，历史最悠久的开源 IP 库 |
| PULP Platform | https://github.com/pulp-platform | Apache-2.0 / SHL-0.51 | ETH 出品；工业级 RISC-V、AXI、外设生态 |
| LowRISC / OpenTitan | https://github.com/lowRISC/opentitan | Apache-2.0 | 高质量 SystemVerilog；其编码风格指南可直接借鉴 |
| Xilinx UNISIM Library | https://github.com/Xilinx/XilinxUnisimLibrary | 见上游 | Virtex-7 / 7 系列原语参考 |
| PicoRV32 | https://github.com/YosysHQ/picorv32 | ISC | 极简 RISC-V，单文件可读性极高 |
| VexRiscv | https://github.com/SpinalHDL/VexRiscv | MIT | 生成式 RISC-V，参数化优秀 |
| fpga4fun | https://www.fpga4fun.com | 教学站点 | 教学级简洁示例，适合作为提示工程的种子样本 |

**使用约定**
- 在 `lib/<module>/REFERENCE.md` 写明：参考实现来源、原 License、与本仓实现的差异。
- 二次开发以"重写而非复制"为原则，避免许可证传染。

---

## B. LLM 训练 / 提示参考语料

供需求分析 Agent、RTL Agent、评测 Agent 使用。

| 名称 | 链接 | License | 用途 |
|------|------|---------|------|
| MG-Verilog | https://huggingface.co/datasets/GaTech-EIC/MG-Verilog | 数据集自带 | 多粒度自然语言 ↔ Verilog 配对 |
| VerilogEval | https://github.com/NVlabs/verilog-eval | NVIDIA 开源（Apache-2.0） | 标准评测集，建议作为版本回归基线 |
| RTLLM | https://github.com/hkust-zhiyao/RTLLM | 见仓库 | 自然语言 → RTL 基准 |
| Spec2RTL-Agent | 论文 + 仓库（搜索"Spec2RTL Agent"） | 论文公开 | VeriAI 多代理架构的原型对照 |

**使用约定**
- 使用前确认数据集 License 是否允许商用、是否要求引用。
- 评测脚本统一放在 `evals/` 目录，每次发布跑一次基线。

---

## C. 规范与权威文档

| 名称 | 适用范围 | 备注 |
|------|----------|------|
| IEEE 1364-2005（Verilog） | 语法权威 | 模块库默认目标语言版本之一 |
| IEEE 1800-2017（SystemVerilog） | 语法权威 | testbench / 接口推荐使用 |
| AMBA AXI / AXI-Lite / AXI-Stream Spec（ARM） | 互联规范 | `lib/axi/` 严格对齐该规范 |
| Xilinx UG901 | 综合方法学 | 可综合性约束 |
| Xilinx UG949 | 设计方法学 | 时序收敛、约束策略 |
| Xilinx UG953 | Virtex-7 数据手册 | 原语、IO、BRAM、DSP 资源参考 |

**使用约定**
- 引用规范条款时标注章节号，便于交叉核对。
- 不在仓库内分发受版权保护的 PDF，仅做链接与摘录。

---

## D. 工具链（开源 EDA）

| 工具 | 用途 | License |
|------|------|---------|
| Verilator | Lint / 高速仿真 | LGPL-3 / Artistic |
| Icarus Verilog | 仿真 | LGPL-2.1 |
| Yosys | 综合估算 | ISC |
| cocotb | Python 测试平台 | BSD-3-Clause |
| GTKWave | 波形查看 | GPL-2 |

工具仅作为命令行依赖调用，不会污染本仓代码许可。

---

## E. 推荐学习项目（2026）

以下项目按推荐优先级排列，作为 VeriAI RAG 知识库、示例库和模块库的核心参考来源。

| 排名 | 项目 | 链接 | License | 推荐指数 | 核心价值 | 对 VeriAI 用途 |
|:---:|------|------|---------|:---:|------|------|
| 1 | LiteX | https://github.com/enjoy-digital/litex | BSD-2-Clause | ★★★★★ | Python 生成完整 SoC，最成熟的开源 FPGA 框架 | Migen DSL → Verilog 生成链路参考；Wishbone/AXI-Lite 桥接模板；CSR 自动生成机制 |
| 2 | VexRiscv | https://github.com/SpinalHDL/VexRiscv | MIT | ★★★★★ | FPGA 优化最佳 RISC-V 核，LiteX 深度集成 | 参数化流水线设计模式；CPU+总线+外设松耦合架构 |
| 3 | FPGAwars/apio | https://github.com/FPGAwars/apio | GPL-2.0 | ★★★★★ | 80+ 开发板 + 60+ 示例，最适合入门 | 目标板约束数据库；入门示例难度分级；工程管理结构参考 |
| 4 | Neorv32 | https://github.com/stnolting/neorv32 | BSD-3-Clause | ★★★★ | 文档极好，适合教学和小型项目 | 文档组织模板标杆；SRS/HID 模板对照优化；中规模模块拆解参考 |
| 5 | OpenFPGA | https://github.com/lnis-uofu/OpenFPGA | MIT | ★★★★ | 学术级开源 FPGA IP 生成器 | 多目标 FPGA 架构后端候选；可编程互连建模方法 |
| — | linux-on-litex-vexriscv | https://github.com/litex-hub/linux-on-litex-vexriscv | 见子仓库 | — | 完整 Linux SoC 示例 | Linux-capable SoC 集成复杂度参考 |
| — | Arty-A7-FPGA-Projects | 搜索 "Arty-A7 FPGA Projects" | 逐项核对 | — | 实用 7 系列项目集合 | 面向开发板的实战模式提取 |
| — | Fomu + foboot | https://github.com/im-tomu/foboot | Apache-2.0 | — | 极致小型完整开源栈 | 微型 FPGA 设计方案参考 |
| — | os-fpga/open-source-fpga-resource | https://github.com/os-fpga/open-source-fpga-resource | 见仓库 | — | 开源 FPGA 资源导航站 | 持续补充可信资源清单 |

**使用约定**
- GPL/LGPL 项目不直接合并到主仓，作为对照实现放入 `third_party/` 或仅链接引用。
- 学习笔记统一放在 `docs/learned/` 目录，命名格式：`<项目名>-<主题>.md`。
- 从项目中提取的代码模式经重写后并入 `lib/`，原则是"学习模式，重写实现，保留来源声明"。

---

## 引用与贡献

新增资源请提交 PR 修改本文件，并补充：
1. 链接、License、用途；
2. 是否会被合并进主仓 / `third_party/` / 仅作链接引用；
3. 风险提示（许可证、商用限制、数据隐私等）。
