# 软件需求文档模板（SRS Template）

> 由"需求分析 Agent"基于任务书（`spec.md`）自动产出 / 工程师评审。
> 每条需求都必须可被验证，并通过追溯矩阵（RTM）反向引用。
>
> 复制本文件为 `docs/srs/<module_name>.md` 后填写。

---

```yaml
---
srs_version: 0.1.0
module_name: example_module
spec_ref: docs/specs/example_module.md   # 上游任务书路径
spec_version: 0.1.0
generated_by: requirements-agent         # 生成者：human | requirements-agent
generated_at: 2026-01-01
---
```

---

## 一、范围与术语

- **范围**：本 SRS 仅覆盖 `example_module` 单一硬件模块，不含上层系统集成。
- **术语**：
  - FR：Functional Requirement，功能需求
  - NFR：Non-Functional Requirement，非功能需求
  - C：Constraint，约束
  - RTM：Requirement Traceability Matrix，需求追溯矩阵

---

## 二、功能需求 FR

> 编号 `FR-NNN`，全文档唯一；每条需求**单一、可验证、可测**。

| ID | 描述 | 优先级 | 来源（Spec 段落） | 验证方式 |
|----|------|--------|-------------------|----------|
| FR-001 |  | P0 / P1 / P2 | 一.功能描述/要点 1 | sim / formal / review |
| FR-002 |  |  |  |  |

## 三、非功能需求 NFR

| ID | 类别 | 指标 | 阈值 | 来源 | 验证方式 |
|----|------|------|------|------|----------|
| NFR-001 | 性能 | Fmax | ≥ 200 MHz | spec.performance.clock_freq_mhz | synth |
| NFR-002 | 资源 | LUT  | ≤ 2000   | spec.performance.resource_budget.lut | synth |
| NFR-003 | 覆盖率 | 行覆盖率 | ≥ 80% | spec.acceptance.sim_coverage_min | sim |

## 四、约束 C

| ID | 类别 | 内容 | 来源 |
|----|------|------|------|
| C-001 | 器件 | Xilinx 7 系列 | spec.target_device |
| C-002 | 工具链 | Vivado 2023.2 | spec.toolchain.synth |
| C-003 | 语言 | Verilog-2001 可综合子集 | spec.constraints.language |

---

## 五、需求-接口追溯矩阵（RTM）

> 用于 HID（`hid.yaml`）与 RTL/验证产物的双向追溯。

| 需求 ID | 关联 HID 元素（端口 / 协议 / 时序） | 关联测试用例 |
|---------|--------------------------------------|---------------|
| FR-001  | ports.wr_en, ports.wr_data, protocols.write | tc_basic_write |
| FR-002  | ports.rd_en, ports.rd_data, protocols.read  | tc_basic_read  |
| NFR-001 | clocks.clk                           | synth_report  |

---

## 六、变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-01-01 | 0.1.0 | 初稿 |  |
