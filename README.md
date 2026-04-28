# VeriAI - AI辅助FPGA全链条开发平台

**VeriAI** 是一个开源的 AI 辅助 FPGA 全链条开发平台，目标是让工程师通过自然语言、任务书与硬件描述，快速完成从文档对齐到可综合 RTL 的全流程。

## 核心定位

VeriAI 的核心不是简单地“从任务书直接生成 RTL”，而是以**文档对齐**为中心：

1. 输入材料首先是**任务书 / Spec** 与**已有硬件描述 / HID 草稿或基本描述**；
2. 第一阶段产出是**软件需求分析 / SRS 草稿**，用于承上启下；
3. 需求分析过程中必须主动提出任务书与硬件描述之间的不一致、缺失与歧义；
4. 允许工程师根据问题清单反向修改、补充任务书和硬件描述；
5. 只有当 SRS 达到合格状态后，才进入架构定义、RTL 生成与验证。

## 核心特性

- **文档对齐优先**：围绕 Spec、HID 草稿与 SRS 建立一致性检查和闭环修订。
- **全链条自动化**：任务书 + 硬件描述 → SRS 草稿 → 文档对齐与修订 → 合格 SRS → HID/架构定义 → RTL 代码生成 → 验证。
- **高质量 Verilog 库**：内置专业级参数化模块，完全兼容 Virtex-7 / 7 系列。
- **多代理协作**：基于 Spec2RTL-Agent 架构，自动规划、编码、反思、修复。
- **中文优先**：完美支持中文任务书、硬件描述和提示。

**当前版本**：v0.2 FullChain

## 快速开始

直接双击打开 `veriai_fullchain_demo.html` 即可体验。

## 结构化工作流

```text
任务书 / Spec  ─┐
                ├─> 需求分析 Agent ─> SRS 草稿 / 基本需求描述
硬件描述草稿 ───┘                      │
                                       v
                          一致性问题清单 / 缺失项 / 歧义点
                                       │
                         允许补充或修订 Spec 与 HID 草稿
                                       │
                                       v
                               合格 SRS / Baseline
                                       │
                                       v
                           HID 定稿 / 架构定义
                                       │
                                       v
                              RTL 生成与验证
```

### SRS 合格标准

SRS 是 VeriAI 全链条的关键中间产物，必须满足：

- 所有需求可追溯到任务书或硬件描述来源；
- 明确列出功能需求、非功能需求、约束与验收标准；
- 对 Spec 与 HID 草稿中的冲突、缺失、歧义给出问题编号和处理状态；
- 已完成必要的上游文档修订建议或修订记录；
- 具备可供后续 HID、RTL、验证使用的 RTM 追溯矩阵。

## 技术路线图

### Phase 1（优先）

- 扩展 Verilog 库到 12+ 模块
- 升级为 React + TypeScript + Monaco Editor
- 接入真实 LLM（Qwen2.5-Coder / DeepSeek-Coder-V2）
- 实现 PDF 任务书解析
- 建立 Spec + HID 草稿 → SRS 草稿 → 文档对齐问题清单 → 合格 SRS 的闭环流程

### Phase 2

- 多代理 Spec2RTL 系统
- FastAPI 后端 + Docker 部署
- 基于合格 SRS 自动生成 HID/RTL/验证用例的端到端流水线

## Verilog 模块库（lib/）

| 模块 | 路径 | 状态 | 说明 |
|------|------|------|------|
| `sync_fifo` | [`lib/fifo/`](lib/fifo/) | ✅ 金标准 | 参数化同步 FIFO，含 testbench 和仿真脚本 |

> **金标准模块**：经过完整 testbench 验证，可作为后续 AI 生成代码或 DUT 变体的对照基准。
> 详见各模块目录下的 `README.md`���其中包含接口说明、验证覆盖矩阵和验收检查清单。

## 文档与规划

- [`TODU.md`](TODU.md)：文档对齐流程的后续计划与任务拆解
- [`docs/resources.md`](docs/resources.md)：公开可信资源（开源 IP 库 / LLM 语料 / 规范文档）
- [`docs/templates/spec_template.md`](docs/templates/spec_template.md)：任务书模板
- [`docs/templates/srs_template.md`](docs/templates/srs_template.md)：软件需求文档模板（含 RTM、问题清单与对齐状态）
- [`docs/templates/hid_template.md`](docs/templates/hid_template.md)：硬件接口描述模板 / HID 草稿模板
- [`docs/schemas/hid.schema.json`](docs/schemas/hid.schema.json)：HID JSON Schema 校验

文档链路：`spec + hid_draft → srs_draft → alignment_issues → spec/hid_updates → srs_baseline → hid → rtl → verify`，每一步都可被下游 Agent 反向追溯。

## 仓库初始结构

```
VeriAI/
├── veriai_fullchain_demo.html   # 单文件全链条演示（无需安装）
├── TODU.md                      # 后续计划与任务拆解
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
├── docs/                        # 文档
│   ├── resources.md             # 公开可信资源清单
│   ├── templates/               # 文档模板
│   │   ├── spec_template.md     # 任务书模板（含 YAML Front Matter）
│   │   ├── srs_template.md      # 软件需求文档模板（FR/NFR/C + RTM + 对齐问题）
│   │   └── hid_template.md      # 硬件接口描述模板 / HID 草稿模板（YAML）
│   └── schemas/
│       └── hid.schema.json      # HID YAML 的 JSON Schema 校验
└── README.md
```

## Topics

`fpga` `verilog` `ai` `llm` `spec2rtl` `xilinx` `open-source` `chinese`