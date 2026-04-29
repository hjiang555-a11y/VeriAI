# 文档对齐 Agent 流程定义

> VeriAI 文档生成与对齐流程的完整 Agent 规范。
> 从自然语言输入开始，经需求抽取、文档对齐、闭环修订，到 SRS Baseline 输出。
> 本文件作为后续 React+TS 实现时各 Agent 模块的契约文档。

---

## 〇、Natural Language Extraction Agent（自然语言需求抽取 Agent）

### 0.1 角色

负责将非结构化的中文自然语言描述转化为结构化的 Spec 草稿与 HID 草稿。
这是 VeriAI 流水线的**入口 Agent**——用户不需要知道 Spec/HID 模板的存在。

### 0.2 输入

| 输入 | 必选 | 格式 | 说明 |
|------|:---:|------|------|
| 自然语言描述 | 是 | 自由文本（中文优先） | 工程师对硬件模块的自然语言描述 |

### 0.3 输出

| 输出 | 说明 |
|------|------|
| **Spec 草稿** | 从自然语言中抽取的功能描述、性能指标、接口需求、约束，自动填入 `spec_template.md` 格式 |
| **HID 草稿** | 从自然语言中抽取的端口、参数、时钟、复位描述，自动填入 `hid_template.md` YAML 格式 |

### 0.4 工作流程

```text
自然语言描述
    │
    ▼
需求抽取 Agent
    │
    ├─→ Spec 草稿 (v0.1)
    └─→ HID 草稿 (v0.1)
```

---

## 一、Requirements Alignment Agent（需求对齐 Agent）

### 1.1 角色

负责将上游输入材料（Spec、HID Draft、可选的 SRS 初始草稿 / 简单描述）综合为结构化的 SRS 草稿，
并主动检测输入材料之间的不一致、缺失与歧义。

### 1.2 输入

| 输入 | 必选 | 格式 | 说明 |
|------|:---:|------|------|
| 任务书 / Spec | 是 | Markdown（`docs/templates/spec_template.md` 格式） | 用户需求的结构化表达，含功能描述、性能指标、约束。可由自然语言抽取 Agent 自动生成 |
| HID 草稿 / HID Draft | 是 | YAML（`docs/templates/hid_template.md` 格式） | 硬件接口描述前置草稿，含端口、时钟域、复位、协议。可由自然语言抽取 Agent 自动生成 |
| SRS 初始草稿 / 简单描述 | 否 | Markdown / 自由文本 | 工程师提供的已有需求分析起点或补充描述 |

### 1.3 输出

| 输出 | 说明 |
|------|------|
| **SRS 草稿** | 完整 SRS（`docs/templates/srs_template.md` 格式），含 FR/NFR/C、RTM、一致性检查表 |
| **不一致问题清单** | Spec vs HID Draft vs SRS 之间的冲突、缺失、歧义列表，每条含严重级别、影响范围、处理状态 |
| **上游文档修订建议** | 针对 Spec 和 HID Draft 的具体修订建议，可逐条执行或驳回 |

### 1.4 判定逻辑

```
function assess_srs_baseline(srs):
  conditions:
    1. all(P0 requirements have traceable source)  // 所有 P0 需求有来源
    2. all(FR interfaces map to HID ports/protocols) // 接口行为有 HID 对应
    3. all(P0 issues are closed)                     // P0 冲突全部关闭
    4. all(requirements have verification method)    // 可验证性
    5. all(CHK items pass)                           // 一致性检查全部通过
    6. RTM is bidirectional                          // RTM 双向可追溯
    7. all(P0 revisions executed)                    // P0 修订建议已执行

  if all(conditions) then:
    srs_status = "baseline"
    emit: "SRS 合格，可进入架构定义阶段"
  else:
    srs_status = "review"  // 或保持 draft
    emit: "仍有未解决问题，无法进入 baseline"
```

### 1.5 工作流程

```text
自然语言描述 ──→ 需求抽取 Agent ──→ Spec + HID Draft (v0.1)
                                       │
Spec ──────────────┐                    │
                   ├─→ 需求对齐 Agent ─→ SRS Draft (v0.1)
HID Draft ────────┘                       │
                                          ├─→ Issue List
SRS 初始草稿（可选）─────────────────────┘       │
                                          ├─→ Revision Suggestions
                                          └─→ SRS Status: draft
                                                 │
                                          ┌──────┘
                                          ▼
                                   工程师审阅 / 修订
                                          │
                                          ▼
                                   需求对齐 Agent（重新运行）
                                          │
                                          ▼
                                   SRS Status: review / baseline
```

---

## 二、Document Revision Loop（文档修订循环）

### 2.1 角色

在 SRS 草稿生成后，驱动一轮或多轮文档修订，直到 SRS 达到 baseline 状态。
该循环由工程师主导决策，Agent 辅助执行。

### 2.2 支持的操作

| 操作 | 说明 | 触发方式 |
|------|------|----------|
| 修改 Spec | 根据 SRS 中的"上游文档修订建议"修改任务书字段或正文 | 工程师手动 / Agent 建议 |
| 修改 HID Draft | 根据 SRS 中的修订建议修改 HID 草稿的 YAML 字段 | 工程师手动 / Agent 建议 |
| 补充 SRS 初始草稿 | 工程师补充或澄清已有的需求描述，作为下一轮 SRS 生成的输入 | 工程师手动 |
| 重新生成 SRS | 在上游文档修订后，重新运行需求对齐 Agent，更新 SRS | Agent 自动 / 工程师触发 |
| 逐条关闭问题 | 对 Issue List 中的问题逐条确认、修订并关闭 | 工程师 + Agent |

### 2.3 循环控制

```text
┌─────────────────────────────────────────────────────────────┐
│                    Document Revision Loop                    │
│                                                             │
│  1. 需求对齐 Agent 产出 SRS Draft + Issue List + RevSuggest │
│                              │                              │
│                              ▼                              │
│  2. 工程师审阅：是否所有 P0 问题可关闭？                     │
│        │                       │                            │
│       是                      否                            │
│        │                       │                            │
│        ▼                       ▼                            │
│  3a. 关闭 P0 问题       3b. 选择修订目标文档                │
│        │                       │                            │
│        │                  ┌────┴────┬──────────┐            │
│        │                  ▼         ▼          ▼            │
│        │              修改 Spec  修改 HID  补充 SRS         │
│        │               Draft     Draft      描述            │
│        │                  │         │          │            │
│        │                  └────┬────┘──────────┘            │
│        │                       ▼                            │
│        │              4. 重新运行需求对齐 Agent              │
│        │                       │                            │
│        └───────────────────────┘                            │
│                              │                              │
│                              ▼                              │
│  5. SRS Status = baseline ? ──否──→ 回到步骤 2              │
│        │                                                   │
│       是                                                    │
│        │                                                   │
│        ▼                                                   │
│  6. 产出 SRS Baseline + HID Baseline + RTL Prompt           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.4 退出条件

| 条件 | 结果 |
|------|------|
| 所有 P0 问题已关闭 + SRS Baseline 条件全部满足 | **正常退出**：进入架构定义阶段 |
| 工程师显式确认"剩余 P1/P2 问题可接受" | **分级接受退出**：SRS 附带开放 P1/P2 问题进入 baseline |
| 工程师放弃当前模块 | **放弃退出**：SRS 归档为 `abandoned` |

---

## 三、Agent 接口契约（供实现参考）

### 3.0 Natural Language Extraction Agent

```typescript
interface ExtractionAgentInput {
  naturalLanguage: string;       // 自由文本的自然语言描述（中文优先）
  context?: {                    // 可选：补充上下文
    targetDevice?: string;       //   目标器件
    existingModules?: string[];  //   已有模块列表
  };
}

interface ExtractionAgentOutput {
  spec: SpecDocument;            // 自动生成的 Spec 草稿
  hidDraft: HIDDraftYAML;       // 自动生成的 HID 草稿
  extractionNotes: string[];    // 抽取过程中的不确定项说明
}
```

### 3.1 Requirements Alignment Agent

```typescript
// 预期 TypeScript 接口（Phase 5 React+TS 实现）
interface AlignmentAgentInput {
  spec: SpecDocument;           // 解析后的任务书
  hidDraft: HIDDraftYAML;       // 解析后的 HID 草稿
  initialDraft?: string;        // 可选：初始 SRS 草稿 / 简单描述
}

interface AlignmentAgentOutput {
  srsDraft: SRSDocument;        // 生成的 SRS 草稿（含 FR/NFR/C/RTM）
  issues: AlignmentIssue[];     // 不一致问题清单
  revisions: RevisionSuggestion[]; // 上游文档修订建议
  baselineEligible: boolean;    // 是否满足 baseline 条件
}

interface AlignmentIssue {
  id: string;                   // P#NNN
  severity: "P0" | "P1" | "P2";
  location: string;             // "Spec.一.要点2" / "HID.ports[0]" / "SRS.FR-003"
  description: string;
  affectedRequirements: string[];
  status: "open" | "in_review" | "closed";
  resolution?: string;
}

interface RevisionSuggestion {
  id: string;                   // REV-NNN
  targetDocument: "spec" | "hid_draft";
  targetLocation: string;
  suggestion: string;
  relatedIssue: string;
  executed: boolean;
}
```

### 3.2 Document Revision Loop Controller

```typescript
interface RevisionLoopState {
  iteration: number;
  srsStatus: "draft" | "review" | "baseline" | "abandoned";
  openP0Issues: number;
  openP1Issues: number;
  pendingRevisions: number;
  canExit: boolean;
  exitReason?: string;
}
```

---

## 四、与后续阶段的衔接

1. **SRS Baseline** 产出后 → 进入 **架构定义（HID Baseline）**
2. **HID Baseline** 产出后 → 进入 **RTL 生成** 与 **验证计划生成**
3. 所有阶段的产物均可通过 **RTM** 双向追溯至 SRS 需求条目

---

## 五、变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-04-28 | 0.1.0 | 初稿：定义 Requirements Alignment Agent + Document Revision Loop | |
