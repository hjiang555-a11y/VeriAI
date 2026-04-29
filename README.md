# VeriAI - AI辅助FPGA全链条开发平台

**VeriAI** 是一个开源的 AI 辅助 FPGA 全链条开发平台，从**自然语言**出发，经历文档生成、需求对齐、架构定义，最终产出可综合 RTL 与验证用例，满足**工程化软件可靠性设计**的完整需求。

## 核心定位

VeriAI 以**自然语言驱动的文档对齐**为中心：

1. **输入起点是自然语言**：工程师可以用中文自由描述硬件需求，VeriAI 从非结构化文本中抽取 Spec 与 HID；
2. **自动生成工程文档**：系统自动产出 任务书（Spec）→ 软件需求分析（SRS）→ 硬件接口描述（HID），形成完整的文档链；
3. **主动发现不一致**：需求对齐 Agent 逐项检查 Spec、HID 与 SRS 之间的冲突、缺失与歧义，产出问题清单和修订建议；
4. **闭环修订机制**：工程师根据问题清单反向修正输入，直到 SRS 满足工程可靠性标准；
5. **可靠性基线**：只有 SRS 达到 Baseline 状态后才进入 RTL 生成与验证，确保"先对齐，再编码"。

## 核心特性

- **自然语言驱动**：从中文自然语言描述出发，无需事先掌握结构化模板，VeriAI 自动完成从非结构文本到结构化文档的转化。
- **文档自动生成**：自动产出 Spec / SRS / HID 三大工程文档，每条需求可追溯、可验证，满足软件可靠性设计规范。
- **文档对齐优先**：围绕 Spec、HID 草稿与 SRS 建立一致性检查和闭环修订，杜绝"文档与代码两张皮"。
- **全链条自动化**：自然语言 → Spec + HID 草稿 → SRS 草稿 → 文档对齐与修订 → 合格 SRS Baseline → HID/架构定义 → RTL 代码生成 → 验证。
- **工程化可靠性**：需求追溯矩阵（RTM）+ 一致性检查表 + 问题清单 + 上游修订建议，形成可审计的设计链路。
- **高质量 Verilog 库**：内置专业级参数化模块，兼容 Xilinx 7 系列 / iCE40 / ECP5，含金标准 testbench 和验证覆盖矩阵。
- **多代理协作**：基于 Spec2RTL-Agent 架构，需求对齐、架构定义、RTL 生成、验证各阶段由独立 Agent 协作完成。
- **中文优先**：完美支持中文自然语言输入、任务书和提示。

**当前版本**：v0.4

## 快速开始

直接双击打开 `veriai_fullchain_demo.html` 即可体验全链条流程。

## 结构化工作流

```text
自然语言描述 ──┐
               ├─> 需求抽取 Agent ─> Spec 草稿 + HID 草稿
               │
任务书 / Spec  ─┐
               ├─> 需求对齐 Agent ─> SRS 草稿 + 一致性问题清单 + 修订建议
硬件描述草稿 ──┘                      │
                                      v
                            工程师修订循环（修改 Spec / HID / SRS 初稿）
                                      │
                                      v
                              合格 SRS / Baseline
                                      │
                                      v
                          HID Baseline / 架构定义
                                      │
                                      v
                             RTL 生成与验证
```

### 输入形式

VeriAI 支持多层次的输入方式：

| 输入形式 | 结构化程度 | 示例 |
|---------|:---:|------|
| 自然语言描述 | 无结构 | "我需要一个 FIFO，深度 512，位宽 32，带满空标志" |
| Spec + 简单描述 | 半结构 | Markdown 任务书 + 补充自然语言说明 |
| Spec + HID Draft | 结构化 | 完整任务书 + YAML 硬件接口草稿 |

> VeriAI 从最自由的自然语言到最严格的结构化模板，都能处理。
> 自然语言输入时，系统先自动抽取为 Spec/HID 结构化文本，再进入文档对齐流程。

### SRS 合格标准

SRS 是 VeriAI 全链条的关键中间产物，必须满足工程可靠性设计规范：

- 所有需求可追溯到自然语言来源或 Spec 段落；
- 明确列出功能需求（FR）、非功能需求（NFR）、参数化需求、约束（C）与验收标准；
- 对 Spec 与 HID 草稿中的冲突、缺失、歧义给出问题编号和处理状态；
- 已完成必要的上游文档修订建议或修订记录；
- 具备可供后续 HID、RTL、验证使用的 RTM 追溯矩阵。

## 技术路线图

### Phase 1-5（已完成 ✅）

- React + TypeScript + Monaco Editor SPA 前端
- FastAPI 后端 + LLM 抽象层（Qwen2.5-Coder / DeepSeek-Coder-V2）
- PDF / Word 任务书解析
- YAML / Markdown HID 草稿解析
- Spec + HID → SRS → 文档对齐 → Baseline → RTL → 验证的闭环流程

### Phase 6-8（已完成 ✅）

- FPGA 开源项目深度学习：LiteX / VexRiscv / apio / Neorv32 / OpenFPGA
- 82 板级约束数据库 + 78 示例难度分级
- RAG 知识库设计模式索引 + 外设参考实现索引
- SRS / HID 模板增强（寄存器映射、中断映射、参数化需求）
- VeriAI 推荐学习路径（apio → LiteX → VeriAI）

### Phase 9（后续）

- 多代理 Spec2RTL 系统
- 基于合格 SRS 自动生成完整 RTL/验证用金的端到端流水线
- Docker 部署

## Verilog 模块库（lib/）

| 模块 | 路径 | 状态 | 说明 |
|------|------|------|------|
| `sync_fifo` | [`lib/fifo/`](lib/fifo/) | ✅ 金标准 | 参数化同步 FIFO，含 testbench 和仿真脚本 |

> **金标准模块**：经过完整 testbench 验证，可作为后续 AI 生成代码或 DUT 变体的对照基准。
> 详见各模块目录下的 `README.md`，其中包含接口说明、验证覆盖矩阵和验收检查清单。

## 文档与规划

| 文件 | 说明 |
|------|------|
| [`TODU.md`](TODU.md) | 学习计划与后续任务（Phase 1-8 已完成 ✅） |
| [`docs/agent-flow.md`](docs/agent-flow.md) | Agent 流程定义：需求抽取 → 需求对齐 → 文档修订循环 |
| [`docs/rtm-and-verification.md`](docs/rtm-and-verification.md) | RTM 追溯规范 + SRS 合格检查清单 |
| [`docs/implementation-plan.md`](docs/implementation-plan.md) | React+TS 前端、FastAPI 后端、LLM 接入实现计划 |
| [`docs/resources.md`](docs/resources.md) | 公开可信资源清单（开源 IP 库 / LLM 语料 / 规范文档） |
| [`docs/templates/spec_template.md`](docs/templates/spec_template.md) | 任务书模板（含修订记录与 HID 关联字段） |
| [`docs/templates/srs_template.md`](docs/templates/srs_template.md) | 软件需求文档模板（FR/NFR/参数化需求/C + RTM + 问题清单 + Baseline） |
| [`docs/templates/hid_template.md`](docs/templates/hid_template.md) | 硬件接口描述模板（HID Draft/Baseline 双态 + 寄存器映射 + 中断映射） |
| [`docs/schemas/hid.schema.json`](docs/schemas/hid.schema.json) | HID JSON Schema 校验 |
| `docs/learned/` | FPGA 开源项目学习笔记（LiteX / VexRiscv / apio / Neorv32 / OpenFPGA） |
| `docs/learned/rag-index.md` | 设计模式映射 + 外设参考索引 |
| `docs/learned/learning-path.md` | VeriAI 推荐学习路径 |

文档链路：`自然语言 → spec + hid_draft → srs_draft → alignment_issues → spec/hid_updates → srs_baseline → hid_baseline → rtl → verify`，每一步都可被下游 Agent 反向追溯。

## 仓库结构

```
VeriAI/
├── veriai_fullchain_demo.html   # 单文件全链条演示（v0.4，自然语言驱动）
├── TODU.md                      # 学习计划与任务拆解
├── src/                         # 源代码目录
│   ├── agents/                  # 多代理模块
│   └── pipeline/                # 全链条流水线
├── lib/                         # 参数化 Verilog 模块库
│   ├── fifo/
│   │   ├── sync_fifo.v          # ✅ 金标准同步 FIFO RTL
│   │   ├── tb_sync_fifo.v       # 配套 testbench（10 类边界场景）
│   │   ├── Makefile             # iverilog 仿真脚本
│   │   └── README.md            # 接口说明 + 验证覆盖矩阵 + 验收清单
│   ├── uart/
│   └── axi/
├── data/boards/                 # 目标板约束数据库
│   └── apio_boards.csv          # 82 开发板（iCE40/ECP5/Gowin）
├── examples/litex/              # LiteX/Migen DSL 教学示例
├── docs/                        # 文档
│   ├── learned/                 # FPGA 项目学习笔记
│   │   ├── litex-architecture.md
│   │   ├── vexriscv-design-patterns.md
│   │   ├── apio-analysis.md
│   │   ├── neorv32-doc-analysis.md
│   │   ├── openfpga-analysis.md
│   │   ├── rag-index.md
│   │   └── learning-path.md
│   ├── templates/               # 文档模板
│   │   ├── spec_template.md     # 任务书模板
│   │   ├── srs_template.md      # 软件需求文档模板
│   │   └── hid_template.md      # 硬件接口描述模板
│   ├── schemas/
│   │   └── hid.schema.json      # HID JSON Schema 校验
│   ├── resources.md             # 公开可信资源清单
│   ├── agent-flow.md            # Agent 流程定义
│   ├── rtm-and-verification.md  # RTM 追溯规范 + SRS 合格检查
│   └── implementation-plan.md   # 后续实现计划
└── README.md
```

## Topics

`fpga` `verilog` `ai` `llm` `spec2rtl` `xilinx` `open-source` `chinese` `natural-language` `reliability`
