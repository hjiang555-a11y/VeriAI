# TODU - VeriAI 文档对齐流程后续计划

## 目标

将 VeriAI 的核心流程调整为“文档对齐优先”的 Spec2SRS2RTL 流程，确保任务书、硬件描述与软件需求分析文档之间一致、可追溯、可验证。

本项目的关键工作是生成**合格的软件需求分析文档（SRS）**。SRS 可以由任务书、硬件描述、已有需求分析初始草稿，或简单需求描述共同驱动生成；其中任务书和硬件描述是主要输入，初始草稿 / 简单描述可作为补充输入或人工起点。

## Phase 1：文档模板结构化调整

- [ ] 更新 `docs/templates/srs_template.md`
  - [ ] 增加输入材料清单：任务书 / Spec、硬件描述草稿 / HID Draft、需求分析初始草稿 / 简单描述
  - [ ] 增加 SRS 草稿状态字段
  - [ ] 增加 Spec-HID-SRS 一致性检查表
  - [ ] 增加不一致问题清单
  - [ ] 增加上游文档修订建议
  - [ ] 增加 SRS baseline 判定标准

- [ ] 更新 `docs/templates/hid_template.md`
  - [ ] 明确 HID 可作为前置输入草稿
  - [ ] 区分 HID Draft 与 HID Baseline
  - [ ] 增加与 SRS RTM 的双向追溯说明

- [ ] 更新 `docs/templates/spec_template.md`
  - [ ] 增加“可由 SRS 对齐流程反向修订”的说明
  - [ ] 增加修订记录字段
  - [ ] 增加与 HID 草稿的关联字段

## Phase 2：Demo 流程调整

- [ ] 更新 `veriai_fullchain_demo.html`
  - [ ] 增加“硬件描述草稿输入”区域
  - [ ] 增加“需求分析初始草稿 / 简单描述输入”区域
  - [ ] 将“需求分析”改为“SRS 草稿生成”
  - [ ] 增加“不一致问题清单”展示区域
  - [ ] 增加“上游文档修订建议”展示区域
  - [ ] 增加“合格 SRS / Baseline”展示区域
  - [ ] 只有 SRS 合格后才展示架构、RTL 和验证阶段

## Phase 3：Agent 流程定义

- [ ] 定义 Requirements Alignment Agent
  - [ ] 输入：Spec + HID Draft + SRS Draft / 简单需求描述（可选）
  - [ ] 输出：SRS Draft + Issue List + Revision Suggestions
  - [ ] 判定：SRS 是否可进入 baseline

- [ ] 定义 Document Revision Loop
  - [ ] 支持工程师修改 Spec
  - [ ] 支持工程师修改 HID Draft
  - [ ] 支持工程师补充或修订 SRS Draft / 简单需求描述
  - [ ] 支持重新生成或更新 SRS

## Phase 4：验证与追溯

- [ ] 建立 RTM 追溯规范
  - [ ] Spec 条目 → SRS FR/NFR/C
  - [ ] HID 元素 → SRS 需求
  - [ ] SRS 需求 → RTL 模块 / 端口 / 测试用例

- [ ] 增加 SRS 合格检查清单
  - [ ] 所有 P0 需求有来源
  - [ ] 所有接口行为有 HID 对应项
  - [ ] 所有冲突问题已关闭或有明确处理结论
  - [ ] 所有需求具备验证方式
  - [ ] SRS baseline 可作为后续 HID 定稿、架构定义、RTL 生成和验证计划的唯一需求基线

## Phase 5：后续实现

- [ ] 将文档对齐流程接入 React + TypeScript 版本
- [ ] 接入真实 LLM
- [ ] 支持 PDF / Word 任务书解析
- [ ] 支持 YAML / Markdown HID 草稿解析
- [ ] 支持 SRS 初始草稿 / 简单需求描述输入
- [ ] 自动生成 SRS baseline、HID baseline、RTL prompt 和验证计划