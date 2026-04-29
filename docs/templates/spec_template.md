# 任务书模板（Spec Template）

> 本模板是 VeriAI 全链条的**第一站**：用户需求的结构化表达。
> 采用 **Markdown 主体 + YAML Front Matter** 的混合格式，
> 上半部分供 Agent 解析，下半部分供工程师阅读与评审。
>
> **重要**：任务书不是只写一次就冻结的文档。在 SRS 对齐流程中，
> 需求对齐 Agent 可能发现任务书中的缺失、歧义或与 HID 草稿的冲突，
> 此时会生成"上游文档修订建议"，工程师可据此**反向修订**任务书。
> 每次修订需记录在"修订记录"中。
>
> 复制本文件为 `docs/specs/<module_name>.md` 后填写。

---

```yaml
---
# ====== 元信息 ======
module_name: example_module          # 模块名（snake_case，对应顶层 module 名）
version: 0.1.0                       # 任务书版本，遵循 SemVer
author: ""                           # 作者 / 团队
created_at: 2026-01-01               # ISO-8601 日期
target_device: xc7vx485t-2ffg1761    # Xilinx 7 系列零件号
toolchain:
  synth: vivado-2023.2               # 综合工具及版本
  sim:   verilator-5.x               # 仿真工具及版本

# ====== 关联 HID 草稿 ======
hid_draft_ref: docs/hid/example_module.yaml   # 关联的 HID 前置草稿路径（可选）
hid_draft_version: ""                          # 关联的 HID 草稿版本

# ====== 性能指标 ======
performance:
  clock_freq_mhz: 200                # 目标主时钟（MHz）
  throughput: ""                     # 自由文本，如 "1 sample/cycle"
  latency_cycles: 1                  # 端到端延迟（周期）
  resource_budget:                   # 资源上限（可省略）
    lut: 2000
    ff:  2000
    bram: 4
    dsp: 0

# ====== 约束 ======
constraints:
  synthesizable: true                # 必须可综合
  language: verilog-2001             # verilog-2001 | systemverilog-2017
  coding_style: lowrisc              # 编码风格参考
  power_domain: single

# ====== 验收标准 ======
acceptance:
  sim_coverage_min: 0.80             # 行/分支覆盖率门限
  fmax_mhz_min: 200                  # 综合 Fmax 下限
  regression_cases: []               # 回归用例列表（与 SRS RTM 对齐）
---
```

---

## 一、功能描述

> 用中文清晰描述模块的功能、应用场景、典型工作流。鼓励列举要点，
> 而非长段散文，便于需求对齐 Agent 自动抽取 FR 条目。

- 功能要点 1：
- 功能要点 2：
- 功能要点 3：

## 二、接口预期（高层）

> 仅写"对外可见的协议级接口"，详细信号 / 时序留给 HID 文档（`hid.yaml`）。

| 接口名 | 类型 | 说明 |
|--------|------|------|
|        |      |      |

## 三、性能与资源说明

> 对 Front Matter 中 `performance` 字段的补充说明（取舍权衡、特殊场景）。

## 四、特殊约束与边界条件

- 复位策略：异步置位、同步释放 / 全同步 / ……
- 时钟域数量：
- 异常处理：

## 五、参考与对标

> 列出参考的开源实现 / 标准条款 / 论文，与 `docs/resources.md` 联动。

- 参考实现：
- 对标规范：

## 六、备注

任何不便结构化表达的补充信息。

---

## 七、修订记录

> 由 SRS 对齐流程驱动的任务书反向修订记录。每次根据需求对齐 Agent 的
> "上游文档修订建议"修改任务书后，必须在此追加一条记录。

| 日期 | 版本 | 修订触发源 | 修订内容摘要 | 关联 SRS 修订建议 | 作者 |
|------|------|-----------|-------------|-------------------|------|
| 2026-01-01 | 0.1.0 | — | 初稿 | — | |
|  |  | SRS 对齐 / 问题清单 |  | REV-xxx | |
