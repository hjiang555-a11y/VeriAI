# Phase 5 后续实现计划

> VeriAI Phase 5：将文档对齐流程接入生产级 React+TS 前端与 FastAPI 后端，
> 对接真实 LLM，支持多种文件格式解析，实现端到端自动化流水线。

---

## 一、技术栈升级：React + TypeScript + Monaco Editor

### 1.1 目标

将当前单文件 HTML Demo 升级为 React + TypeScript SPA，提供工程级交互体验。

### 1.2 前端架构

```
src/
├── components/
│   ├── PipelineView.tsx           # 全链条可视化管道
│   ├── SpecEditor.tsx             # 任务书编辑器（Monaco）
│   ├── HIDEditor.tsx              # HID YAML 编辑器（Monaco + JSON Schema 校验）
│   ├── SRSView.tsx                # SRS 文档渲染与编辑
│   ├── IssueList.tsx              # 不一致问题清单（表格 + 筛选）
│   ├── RevisionPanel.tsx          # 上游文档修订建议面板
│   ├── BaselineGate.tsx           # SRS Baseline 判定与准入控件
│   ├── RTLPreview.tsx             # RTL 代码预览（Monaco Verilog 模式）
│   └── VerificationReport.tsx     # 验证报告仪表板
├── state/
│   ├── pipelineStore.ts           # Zustand 全局流水线状态
│   └── agentClient.ts             # Agent API 调用封装
├── types/
│   ├── spec.ts                    # Spec 文档类型定义
│   ├── hid.ts                     # HID 类型定义
│   ├── srs.ts                     # SRS 类型定义（FR/NFR/C/RTM/Issue）
│   └── pipeline.ts                # 流水线阶段与状态枚举
└── App.tsx
```

### 1.3 技术选型

| 层 | 技术 |
|---|------|
| 框架 | React 18 + TypeScript 5.x |
| 编辑器 | Monaco Editor（Verilog / Markdown / YAML 语法高亮） |
| 状态管理 | Zustand |
| 样式 | Tailwind CSS |
| 构建 | Vite |

---

## 二、后端：FastAPI + Docker 部署

### 2.1 后端架构

```
backend/
├── api/
│   ├── alignment.py               # /api/alignment 需求对齐端点
│   ├── architecture.py            # /api/architecture 架构生成端点
│   ├── rtl.py                     # /api/rtl RTL 生成端点
│   └── verification.py            # /api/verify 验证端点
├── agents/
│   ├── alignment_agent.py         # 需求对齐 Agent 实现
│   ├── architecture_agent.py      # 架构 Agent 实现
│   ├── rtl_agent.py               # RTL Agent 实现
│   └── verify_agent.py            # 验证 Agent 实现
├── parsers/
│   ├── pdf_parser.py              # PDF 任务书解析
│   ├── word_parser.py             # Word 任务书解析
│   ├── yaml_parser.py             # YAML HID 解析
│   └── markdown_parser.py         # Markdown 模板解析
├── core/
│   ├── config.py                  # 配置管理
│   ├── llm_client.py              # LLM 客户端抽象
│   └── models.py                  # Pydantic 数据模型
├── Dockerfile
└── docker-compose.yml
```

### 2.2 LLM 客户端抽象

```python
class LLMClient(ABC):
    @abstractmethod
    async def generate(self, system_prompt: str, user_prompt: str,
                       response_schema: type) -> Any: ...

class QwenCoderClient(LLMClient): ...      # Qwen2.5-Coder-32B
class DeepSeekCoderClient(LLMClient): ...  # DeepSeek-Coder-V2
```

---

## 三、真实 LLM 接入

### 3.1 候选模型

| 模型 | 适用场景 | 关键能力 |
|------|---------|---------|
| Qwen2.5-Coder-32B-Instruct | 需求对齐、架构定义 | 中英文 SRS 生成，结构化输出 |
| DeepSeek-Coder-V2 | RTL 生成、代码补全 | Verilog 代码生成能力 |
| Qwen3-Max / DeepSeek-V3 | 复杂多步推理、问题检出 | 不一致检测、修订建议 |

### 3.2 Prompt 工程

```
┌─ System Prompt ───────────────────────────────────────┐
│ 角色：VeriAI 需求对齐 Agent                           │
│ 能力：解析 Spec、HID Draft、SRS 初稿，抽取 FR/NFR/C   │
│ 约束：输出必须符合 docs/templates/srs_template.md     │
│       每条需求必须单一、可验证、可追溯                 │
│       主动检测输入材料之间的不一致、缺失、歧义         │
│ 输出格式：严格按模板的 YAML Front Matter + 各节        │
└──────────────────────────────────────────────────────┘
┌─ User Prompt ────────────────────────────────────────┐
│ Spec: {{ spec_content }}                             │
│ HID Draft: {{ hid_content }}                         │
│ SRS 初稿（可选）: {{ initial_draft }}                │
│ 请生成：SRS Draft + Issue List + Revision Suggestions│
└──────────────────────────────────────────────────────┘
```

### 3.3 结构化输出

- 使用 OpenAI-compatible JSON mode 或 function calling
- 后端用 Pydantic 模型校验 Agent 返回内容，确保符合模板格式
- 校验失败时自动重试（含错误信息反馈给 LLM）

---

## 四、PDF / Word 任务书解析

### 4.1 PDF 解析

```python
# 使用 pdfplumber 或 PyMuPDF
import pdfplumber

def parse_spec_pdf(file_path: str) -> SpecDocument:
    with pdfplumber.open(file_path) as pdf:
        text = "\n".join(page.extract_text() for page in pdf.pages)
    return extract_spec_from_text(text)
```

- 支持中文 PDF（含表格、列表、YAML Front Matter）
- 解析结果映射到 `spec_template.md` 结构

### 4.2 Word 解析

```python
# 使用 python-docx
from docx import Document

def parse_spec_docx(file_path: str) -> SpecDocument:
    doc = Document(file_path)
    text = "\n".join(p.text for p in doc.paragraphs)
    return extract_spec_from_text(text)
```

---

## 五、YAML / Markdown HID 草稿解析

### 5.1 YAML 解析 + 校验

```python
import yaml
from ajv import Ajv

def parse_hid_yaml(yaml_path: str) -> HIDDraft:
    with open(yaml_path) as f:
        data = yaml.safe_load(f)
    # 使用 hid.schema.json 校验
    ajv = Ajv()
    validate = ajv.compile(schema)
    if not validate(data):
        raise ValidationError(validate.errors)
    return HIDDraft(**data)
```

### 5.2 Markdown HID 解析

- 从 HID template Markdown 中提取 YAML 代码块
- 按 YAML 路径解析

---

## 六、自动生成 Pipeline

### 6.1 端到端生成流程

```
输入：
  spec.pdf / spec.docx / spec.md  ──→ Spec 解析
  hid_draft.yaml / hid_draft.md   ──→ HID 解析
  简单描述文本                      ──→ 初稿文本

处理：
  需求对齐 Agent ──→ SRS Draft + Issues + Revisions
      │
      ▼
  工程师修订循环（web UI 交互）
      │
      ▼
  SRS Baseline 确认
      │
      ▼
  架构 Agent ──→ HID Baseline (hid_status: hid_baseline)
      │
      ▼
  RTL Agent ──→ 可综合 Verilog 代码
      │
      ▼
  验证 Agent ──→ 验证报告（语法、端口、综合估算、覆盖率）
```

### 6.2 产出物清单

| 产物 | 文件路径 | 生成方式 |
|------|---------|---------|
| SRS Baseline | `docs/srs/<module>.md` | 需求对齐 Agent 输出 |
| HID Baseline | `docs/hid/<module>.yaml` | 架构 Agent 输出 |
| RTL 代码 | `src/rtl/<module>.v` | RTL Agent 输出 |
| Testbench | `src/tb/tb_<module>.v` | 验证 Agent 输出 |
| 验证报告 | `docs/reports/<module>_verification.md` | 验证 Agent 输出 |

---

## 七、里程碑

| 里程碑 | 内容 | 预计产出 |
|--------|------|---------|
| M1 | React + Monaco 前端骨架 | 可编辑 Spec / HID / SRS 的 SPA |
| M2 | FastAPI 后端 + LLM 抽象层 | `/api/alignment` 等端点可调用 |
| M3 | 接入 Qwen2.5-Coder / DeepSeek-Coder-V2 | 真实 LLM 驱动的 SRS 生成 |
| M4 | PDF / Word 解析器 | 支持 .pdf / .docx 任务书上传 |
| M5 | YAML / Markdown HID 解析器 | 支持 .yaml / .md HID 草稿上传 |
| M6 | 端到端流水线 | Spec/HID 输入 → SRS/HID/RTL/验证报告全自动产出 |
| M7 | Docker 部署 | `docker-compose up` 一键启动 |

---

## 八、变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-04-28 | 0.1.0 | 初稿：技术栈升级、LLM 接入、文件解析、自动生成流水线 | |
