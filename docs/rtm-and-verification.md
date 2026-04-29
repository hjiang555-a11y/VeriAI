# RTM 追溯规范与 SRS 合格检查清单

> VeriAI Phase 4：定义从 Spec → SRS → HID → RTL → 验证的端到端需求追溯矩阵规范，
> 以及 SRS Baseline 的合格判定标准。
>
> SRS 合格检查清单已内嵌至 [`srs_template.md`](templates/srs_template.md#十一srs-baseline-判定标准)；
> 本文档聚焦跨文档的 RTM 追溯层定义。

---

## 一、RTM 追溯模型

```text
  Spec（任务书）          HID Draft（前置草稿）      初稿 / 简单描述
       │                       │                       │
       └───────────┬───────────┘───────────┬───────────┘
                   │                       │
                   ▼                       ▼
            ┌─────────────────────────────────────┐
            │         SRS（需求文档）              │
            │  FR / NFR / C / RTM / 问题清单       │
            └─────────────────────────────────────┘
                   │
                   ├──→ HID Baseline（定稿接口契约）
                   ├──→ RTL（可综合代码）
                   └──→ 验证计划 / 测试用例
```

---

## 二、追溯层级定义

### 2.1 上游 → SRS（正向追溯）

| 来源 | 目标 SRS 字段 | 追溯方式 |
|------|-------------|----------|
| Spec 章节/要点 | FR / NFR / C 的"来源"列 | 引用格式：`Spec.一.要点1`、`Spec.performance.clock_freq_mhz` |
| HID Draft 元素 | FR / NFR / C 的"来源"列 | 引用格式：`HID.ports.wr_en`、`HID.protocols.write` |
| 初稿 / 简单描述 | FR 的"来源"列 | 引用格式：`InitialDraft.段落2` 或 `SimpleDesc.L3` |

### 2.2 SRS → 下游（反向追溯）

| SRS 元素 | 下游目标 | 追溯方式 |
|----------|---------|----------|
| FR / NFR | HID `trace[]` 数组 | HID YAML 中 `trace.req` 字段指向需求 ID |
| FR / NFR | RTL 模块 / 端口 | RTL 文件头注释中声明对应需求 ID |
| FR / NFR | 测试用例 | testbench 中 `// Coverage: FR-001` 注释 |
| C | 综合约束 | XDC 文件注释中声明约束来源 |

### 2.3 HID ↔ SRS（双向追溯）

已在 [`hid_template.md`](templates/hid_template.md#与-srs-rtm-的双向追溯) 中详细定义：

- **SRS → HID**：SRS RTM 中"关联 HID 元素"列
- **HID → SRS**：HID `trace[]` 数组中的 `req` 字段
- 两边引用必须一致，SRS Baseline 判定包含此项检查

---

## 三、RTM 条目格式规范

### 3.1 SRS 中的 RTM（需求-接口/测试追溯）

```markdown
| 需求 ID | 关联 HID 元素（端口 / 协议 / 时序） | 关联测试用例 |
|---------|--------------------------------------|---------------|
| FR-001  | ports.wr_en, ports.wr_data, protocols.write | tc_basic_write |
| FR-002  | ports.rd_en, ports.rd_data, protocols.read  | tc_basic_read  |
| NFR-001 | clocks.clk                           | synth_report  |
```

### 3.2 HID 中的 RTM（接口-需求追溯）

```yaml
trace:
  - {req: FR-001, ports: [wr_en, wr_data, full],  protocol: write}
  - {req: FR-002, ports: [rd_en, rd_data, empty], protocol: read}
  - {req: NFR-001, clock: clk}
```

### 3.3 RTL 中的 RTM（代码-需求追溯）

```verilog
// RTM: FR-001, FR-003 — 写接口实现
// RTM: FR-005 — full 标志生成
module sync_fifo #( ... ) ( ... );
```

### 3.4 Testbench 中的 RTM（测试-需求追溯）

```verilog
// Coverage: FR-001 (写使能), FR-002 (读使能)
// Coverage: FR-005 (满标志), FR-006 (空标志)
task tc_basic_write_read(); ...
```

---

## 四、SRS 合格检查清单

> 以下检查清单已内嵌至 [`srs_template.md` 第十一节`](templates/srs_template.md#十一srs-baseline-判定标准)。
> 此处列出完整项，供 Reviewer 打印或核对。

### 必须全部通过（7/7）

- [ ] **所有 P0 需求有明确来源**：每条 P0 需求的来源字段指向 Spec 段落、HID 草稿条目或初稿描述
- [ ] **所有接口行为有 HID 对应项**：FR 中涉及的外部接口均在 HID `ports` / `protocols` 中有对应定义
- [ ] **所有 P0 冲突问题已关闭或有明确处理结论**：问题清单中所有 P0 问题的处理状态为 `closed`
- [ ] **所有需求具备可验证方式**：每条 FR/NFR/C 的"验证方式"字段已填写
- [ ] **一致性检查表全部通过**：CHK 条目中无 `❌` 结果，所有 `❓` 已转为 `✅` 或 `❌`（已关闭）
- [ ] **RTM 双向可追溯**：每条需求可追溯到上游（Spec/HID/初稿）和下游（HID 元素 / 测试用例）
- [ ] **上游文档修订建议全部执行**：所有 P0 级别的修订建议目标状态为 `✅ 已执行`

---

## 五、跨文档验证流程

### 5.1 文档对齐阶段（由需求对齐 Agent 执行）

1. 解析 Spec 和 HID Draft，抽取所有可验证的声明
2. 逐项核对 SRS 中每条 FR/NFR/C 的来源是否可追溯
3. 逐项核对 Spec 中的每个接口声明是否在 HID Draft 中有对应定义
4. 检出不一致后，自动生成 Issue List 与 Revision Suggestions

### 5.2 架构/RTL 阶段（由架构 Agent / RTL Agent 执行）

1. 基于 SRS Baseline 生成 HID Baseline，每条 trace 条目必须对应 SRS 需求
2. RTL 中的端口名、参数名必须与 HID Baseline 一致
3. RTL 文件头注释声明对应需求 ID

### 5.3 验证阶段（由验证 Agent 执行）

1. 遍历 SRS 中每条需求，检查是否有对应测试用例
2. 遍历 testbench 注释，检查每个覆盖声明是否对应 SRS 需求
3. 综合报告中的时序/资源数据与 NFR 对比，判定是否达标

---

## 六、变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-04-28 | 0.1.0 | 初稿：定义三层 RTM 规范 + SRS 合格检查清单 | |
