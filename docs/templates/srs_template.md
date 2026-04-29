# 软件需求文档模板（SRS Template）

> 由"需求对齐 Agent（Requirements Alignment Agent）"基于任务书（Spec）、硬件描述草稿（HID Draft）、
> 需求分析初始草稿 / 简单描述共同驱动生成。每条需求都必须可被验证，并通过追溯矩阵（RTM）反向引用。
>
> 复制本文件为 `docs/srs/<module_name>.md` 后填写。

---

```yaml
---
srs_version: 0.1.0
srs_status: draft               # draft | review | baseline（合格 SRS）
module_name: example_module
spec_ref: docs/specs/example_module.md           # 上游任务书路径
spec_version: 0.1.0
hid_draft_ref: docs/hid/example_module.yaml       # 上游 HID 草稿路径
hid_draft_version: 0.1.0
initial_draft_ref: ""                             # 可选：需求分析初始草稿 / 简单描述路径
generated_by: requirements-alignment-agent        # human | requirements-alignment-agent
generated_at: 2026-01-01
---
```

---

## 一、输入材料清单

> 明确本 SRS 草稿的所有上游输入来源，确保可追溯。

| 材料编号 | 类型 | 路径 / 来源 | 版本 | 状态 |
|----------|------|-------------|------|------|
| IN-001 | 任务书 / Spec | `docs/specs/example_module.md` | 0.1.0 | 已纳入 |
| IN-002 | HID 草稿 / HID Draft | `docs/hid/example_module.yaml` | 0.1.0 | 已纳入 |
| IN-003 | 需求分析初始草稿 / 简单描述 | （可选） | — | 待提供 / 不适用 |

---

## 二、SRS 草稿状态说明

| 状态 | 含义 | 可进入下一阶段 |
|------|------|:---:|
| `draft` | 初稿，已基于输入材料生成，存在未解决的一致性/歧义问题 | 否 |
| `review` | 工程师已审阅，问题清单中的 P0 项全部关闭或已有明确处理结论 | 否 |
| `baseline` | 合格 SRS：所有 P0 需求有来源，所有冲突已解决，RTM 可追溯至上下游 | **是** |

---

## 三、范围与术语

- **范围**：本 SRS 仅覆盖 `example_module` 单一硬件模块，不含上层系统集成。
- **术语**：
  - FR：Functional Requirement，功能需求
  - NFR：Non-Functional Requirement，非功能需求
  - C：Constraint，约束
  - RTM：Requirement Traceability Matrix，需求追溯矩阵
  - HID：Hardware Interface Description，硬件接口描述
  - Spec：任务书

---

## 四、功能需求 FR

> 编号 `FR-NNN`，全文档唯一；每条需求**单一、可验证、可测**。

| ID | 描述 | 优先级 | 来源（Spec/HID/初稿段） | 验证方式 |
|----|------|--------|-------------------------|----------|
| FR-001 |  | P0 / P1 / P2 | Spec.一.要点1 / HID Draft.ports | sim / formal / review |
| FR-002 |  |  |  |  |

## 五、非功能需求 NFR

| ID | 类别 | 指标 | 阈值 | 来源 | 验证方式 |
|----|------|------|------|------|----------|
| NFR-001 | 性能 | Fmax | ≥ 200 MHz | spec.performance.clock_freq_mhz | synth |
| NFR-002 | 资源 | LUT  | ≤ 2000   | spec.performance.resource_budget.lut | synth |
| NFR-003 | 覆盖率 | 行覆盖率 | ≥ 80% | spec.acceptance.sim_coverage_min | sim |

## 六、约束 C

| ID | 类别 | 内容 | 来源 |
|----|------|------|------|
| C-001 | 器件 | Xilinx 7 系列 | spec.target_device |
| C-002 | 工具链 | Vivado 2023.2 | spec.toolchain.synth |
| C-003 | 语言 | Verilog-2001 可综合子集 | spec.constraints.language |

---

## 六点五、参数化需求（Parameterized Requirements）

> 基于 Neorv32/VexRiscv 的 Configuration Generics 模式增强。
> 定义模块的编译期配置参数及其默认值、合法范围。

| 参数 | 类型 | 默认值 | 范围/约束 | 对应需求 | 说明 |
|------|------|--------|----------|---------|------|
| DEPTH | integer | 512 | 16-8192, 2 的幂 | NFR-002 | FIFO 深度 |
| WIDTH | integer | 32 | 1-1024 | FR-001 | 数据位宽 |
| FIFO_EN | boolean | true | — | FR-003 | FIFO 使能 |

---

## 七、Spec-HID-SRS 一致性检查表

> 逐项核对任务书、HID 草稿与本 SRS 之间的一致关系。`✅` = 一致，`❌` = 冲突，`❓` = 待确认。

| 编号 | 检查项 | Spec | HID Draft | SRS | 结果 | 关联问题 |
|------|--------|------|-----------|-----|------|----------|
| CHK-001 | 模块名称一致性 | `example_module` | `example_module` | `example_module` | ✅ | — |
| CHK-002 | 端口列表对齐 | 描述：xx 接口 | 定义：xx 端口 | 需求：xx 功能 | ❓ | P#003 |
| CHK-003 | 时钟频率一致 | 200 MHz | 200 MHz | ≥ 200 MHz | ✅ | — |
| CHK-004 | 复位策略一致 | 异步置位同步释放 | async_assert_sync_release | async_assert_sync_release | ✅ | — |

---

## 八、不一致问题清单

> 由需求对齐 Agent 在分析过程中自动生成，记录 Spec / HID Draft 与 SRS 之间的所有冲突、缺失与歧义。

| 问题编号 | 严重级别 | 发现位置 | 问题描述 | 影响的需求 | 处理状态 | 处理结论 / 修订记录 |
|----------|----------|----------|----------|-----------|----------|---------------------|
| P#001 | P0 / P1 / P2 | Spec.二.接口1 vs HID.ports | 端口 `almost_full` 在任务书中要求，但 HID 草稿中未定义 | FR-003 | open / in_review / closed | 已补充 HID 草稿 v0.1.1，增加 `almost_full` 端口 |
| P#002 | P1 | Spec.一.要点2 | "支持背压"描述模糊，未明确 handshake 协议类型 | FR-004 | open | 待工程师补充 handshake 协议的 valid/ready 语义 |

---

## 九、上游文档修订建议

> 针对 Spec 和 HID Draft 中需要反向修订的内容，逐条列出，供工程师执行或确认。

| 建议编号 | 目标文档 | 修订位置 | 修订建议 | 关联问题 | 是否已执行 |
|----------|----------|----------|----------|----------|:---:|
| REV-001 | `spec.md` | 二.接口 | 补充 `almost_empty` 阈值配置说明 | P#003 | ⬜ |
| REV-002 | `hid_draft.yaml` | ports | 增加 `almost_full`、`almost_empty` 端口定义 | P#001 | ✅ 已执行 v0.1.1 |
| REV-003 | `spec.md` | 一.要点2 | 将"支持背压"细化为具体握手协议（valid/ready/stop） | P#002 | ⬜ |

---

## 十、需求-接口追溯矩阵（RTM）

> 用于 HID（`hid.yaml`）与 RTL/验证产物的双向追溯。

| 需求 ID | 关联 HID 元素（端口 / 协议 / 时序） | 关联测试用例 |
|---------|--------------------------------------|---------------|
| FR-001  | ports.wr_en, ports.wr_data, protocols.write | tc_basic_write |
| FR-002  | ports.rd_en, ports.rd_data, protocols.read  | tc_basic_read  |
| NFR-001 | clocks.clk                           | synth_report  |

---

## 十一、SRS Baseline 判定标准

> 以下全部条件必须满足，方可将 SRS 状态从 `review` 升级为 `baseline`：

- [ ] **所有 P0 需求有明确来源**：每条 P0 需求的来源字段指向 Spec 段落、HID 草稿条目或初稿描述
- [ ] **所有接口行为有 HID 对应项**：FR 中涉及的外部接口均在 HID `ports` / `protocols` 中有对应定义
- [ ] **所有 P0 冲突问题已关闭或有明确处理结论**：问题清单中所有 P0 问题的处理状态为 `closed`
- [ ] **所有需求具备可验证方式**：每条 FR/NFR/C 的"验证方式"字段已填写
- [ ] **一致性检查表全部通过**：CHK 条目中无 `❌` 结果，所有 `❓` 已转为 `✅` 或 `❌`（已关闭）
- [ ] **RTM 双向可追溯**：每条需求可追溯到上游（Spec/HID/初稿）和下游（HID 元素 / 测试用例）
- [ ] **上游文档修订建议全部执行**：所有 P0 级别的修订建议目标状态为 `✅ 已执行`

> SRS baseline 一旦确定，即可作为后续 HID 定稿、架构定义、RTL 生成和验证计划的**唯一需求基线**。

---

## 十二、变更记录

| 日期 | 版本 | srs_status | 变更内容 | 作者 |
|------|------|-----------|----------|------|
| 2026-01-01 | 0.1.0 | draft | 初稿 | requirements-alignment-agent |
