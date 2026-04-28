# 2026 年值得学习的 FPGA 开源项目

本文整理 VeriAI 在 2026 年最值得学习和吸收的 FPGA 开源项目。它们不是简单的参考链接，而是 VeriAI 实现**高度可控的工程化设计 FPGA 配置项生成**的重要知识来源。

## 总览

| 排名 | 项目 | 类型 | 推荐指数 | 核心价值 |
|------|------|------|----------|----------|
| 1 | LiteX | SoC 构建器 | ★★★★★ | Python 生成完整 SoC，最成熟的开源框架 |
| 2 | VexRiscv | RISC-V 核心 | ★★★★★ | FPGA 优化最佳 RISC-V 核，LiteX 深度集成 |
| 3 | FPGAwars / apio | 工具链 + 示例 | ★★★★★ | 80+ 开发板 + 60+ 示例，最适合入门 |
| 4 | Neorv32 | RISC-V SoC | ★★★★☆ | 文档极好，适合教学和小型项目 |
| 5 | OpenFPGA | FPGA 架构生成器 | ★★★★☆ | 学术级开源 FPGA IP 生成器 |

## 1. LiteX

- **类型**：SoC 构建器
- **推荐指数**：★★★★★
- **核心价值**：Python 生成完整 SoC，是成熟的开源 FPGA SoC 工程化框架。

### 对 VeriAI 的价值

LiteX 对 VeriAI 最重要的启发是：FPGA 设计可以被拆解为可审查、可配置、可组合的工程项，而不是一次性生成 RTL。

VeriAI 可学习 LiteX 的方向：

- SoC Builder 思路：CPU、总线、外设、存储器、时钟、复位、板级资源都可配置；
- Python/YAML 配置驱动工程生成；
- 板级平台抽象；
- 外设库与总线集成方式；
- 生成结果包括 RTL、约束、构建脚本和软件支持文件。

## 2. VexRiscv

- **类型**：RISC-V 核心
- **推荐指数**：★★★★★
- **核心价值**：FPGA 优化的 RISC-V CPU，常与 LiteX 深度集成。

### 对 VeriAI 的价值

VexRiscv 适合作为 CPU/SoC 配置模板来源。VeriAI 可以借鉴其插件化 CPU 配置思想，将 CPU 特性配置为可追溯工程项：

- 是否启用乘除法；
- 是否启用 Cache；
- 是否启用 MMU / Linux 支持；
- 中断、调试、总线接口配置；
- 小型 SoC 示例，如 Murax。

## 3. FPGAwars / apio

- **类型**：工具链 + 示例
- **推荐指数**：★★★★★
- **核心价值**：覆盖大量开发板和示例，是最适合入门和教学路径建设的项目体系。

### 对 VeriAI 的价值

apio 和 FPGAwars 适合成为 VeriAI 的教学路径和 examples/ 示例库来源：

- 多开发板工程结构；
- 简洁的工具链命令；
- 易懂的外设和基础逻辑示例；
- 适合从简单模块逐步过渡到 SoC；
- 可作为用户学习路径推荐入口。

## 4. Neorv32

- **类型**：RISC-V SoC
- **推荐指数**：★★★★☆
- **核心价值**：文档极好，适合教学、小型 SoC 和可配置 CPU 子系统。

### 对 VeriAI 的价值

Neorv32 可作为“文档驱动 SoC 设计”的优秀参考：

- 清晰的配置参数；
- 完整的文档说明；
- 适合小型项目和教学；
- 可帮助 VeriAI 建立从 SRS/HID 到 SoC 配置项的映射模板。

## 5. OpenFPGA

- **类型**：FPGA 架构生成器
- **推荐指数**：★★★★☆
- **核心价值**：学术级开源 FPGA IP / 架构生成器。

### 对 VeriAI 的价值

OpenFPGA 适合支撑 VeriAI 的长期研究方向：

- FPGA 架构描述；
- IP 生成；
- 工具链配置；
- 架构级参数化生成；
- 可作为高级 RAG 知识源。

## 其他值得关注的项目

| 项目 | 价值 |
|------|------|
| linux-on-litex-vexriscv | 完整 Linux SoC 示例，适合学习 LiteX + VexRiscv 工程级组合 |
| Arty-A7-FPGA-Projects | 实用 Xilinx 7 系列项目集合，适合 VeriAI 的 7 系列示例库 |
| Fomu + foboot | 极致小型完整开源栈，适合小型板卡和最小系统学习 |
| os-fpga/open-source-fpga-resource | 开源 FPGA 资源导航站，适合作为资料索引入口 |

## 对 VeriAI 的融合计划

### 1. RAG 知识库

将 LiteX / VexRiscv / apio / Neorv32 / OpenFPGA 的文档、示例结构和工程模式加入 RAG 知识库，用于提升需求分析、HID 生成、RTL 生成和配置项生成准确率。

重点索引内容：

- SoC 构建流程；
- 外设配置；
- 总线连接；
- 板级资源；
- 工具链命令；
- 示例工程结构；
- 常见配置参数和约束。

### 2. 示例库扩展

将以下工程作为 VeriAI examples/ 的优先索引对象：

- Murax；
- apio 示例；
- Arty-A7 项目；
- linux-on-litex-vexriscv；
- Fomu / foboot。

### 3. 库模块灵感

从成熟项目中提取高质量外设和配置模式，丰富 VeriAI 的 library/ 或 lib/：

- UART；
- SPI；
- I2C；
- GPIO；
- Timer；
- PWM；
- DMA；
- Ethernet；
- USB；
- Memory controller；
- Bus bridge。

每个模块应逐步补齐：

- SRS 模板；
- HID 模板；
- RTL 实现；
- testbench；
- 验证覆盖矩阵；
- 配置项示例。

### 4. 教学路径

VeriAI 可以向用户推荐渐进式学习路径：

1. **入门**：FPGAwars / apio，理解开发板、工具链和基础逻辑；
2. **小型 SoC**：Neorv32 / Murax，理解 CPU、总线和外设；
3. **工程级 SoC**：LiteX + VexRiscv，理解完整 SoC 构建；
4. **架构/IP 研究**：OpenFPGA，理解更底层的 FPGA 架构生成。

## 与 VeriAI 当前目标的关系

VeriAI 的目标是**高度可控的工程化设计 FPGA 配置项生成**。这些开源项目的价值在于提供可学习的工程模式：

- LiteX 提供 SoC 构建器模式；
- VexRiscv 提供可配置 CPU 核模式；
- apio 提供多开发板和工具链示例模式；
- Neorv32 提供文档优秀的小型 SoC 模式；
- OpenFPGA 提供架构生成和 IP 生成模式。

VeriAI 应将这些模式转化为自己的：

- RAG 知识；
- 示例工程；
- SRS/HID/RTL/验证模板；
- 外设库；
- 配置项生成规则；
- 工程化验收标准.
