# 硬件接口描述模板（HID Template）

> 由"架构 Agent"基于合格 SRS（Baseline）自动产出，作为 RTL Agent / 验证 Agent 的输入契约。
> **HID 的生命周期**：HID Draft（前置草稿）→ 参与 SRS 对齐流程 → HID Baseline（定稿），
> 详见本模板"版本状态"节。
>
> **正文**为 YAML 结构化描述，可被 `docs/schemas/hid.schema.json` 自动校验，
> 也可被脚本一键生成 SystemVerilog 接口、端口列表、UVM agent 骨架。
>
> 复制本文件为 `docs/hid/<module_name>.yaml` 后填写。
>
> 字段语义、取值范围与必填项以 `docs/schemas/hid.schema.json` 为准。

---

## HID 版本状态

| 状态 | 含义 | 可作为 |
|------|------|--------|
| `hid_draft` | **HID 前置草稿**：在 SRS 生成前提供，与 Spec 一起作为需求对齐 Agent 的输入材料 | SRS 输入 |
| `hid_baseline` | **HID 定稿**：基于合格 SRS Baseline 重新生成或修订后的最终版本，作为 RTL/验证的契约输入 | RTL/验证输入 |

> **关键区别**：`hid_draft` 是需求阶段的**前置输入草稿**，内容可能不完整，会被 SRS 对齐流程检出问题；
> `hid_baseline` 是所有 P0 问题关闭、SRS 合格后**重新审定或生成**的定稿，代表正式接口契约。

---

## 与 SRS RTM 的双向追溯

HID 与 SRS 之间通过 `trace[]` 字段和 SRS 中的 RTM（需求-接口追溯矩阵）实现**双向追溯**：

```
   SRS RTM（需求侧）                HID trace[]（接口侧）
┌─────────────────────┐       ┌─────────────────────┐
│ FR-001 → ports.wr   │ ←──→  │ trace.req=FR-001 →  │
│            _en, …   │       │   ports=[wr_en, …]  │
└─────────────────────┘       └─────────────────────┘
```

- **从 SRS 追溯 HID**：查找 SRS RTM 中"关联 HID 元素"列
- **从 HID 追溯 SRS**：查找 HID `trace[]` 数组中每条需求的 `req` 字段
- 两边的引用必须一致，SRS Baseline 判定中包含此项检查

---

## 示例 / 起始点

```yaml
# yaml-language-server: $schema=../schemas/hid.schema.json

hid_version: 0.1.0
hid_status: hid_draft                   # hid_draft | hid_baseline
module: sync_fifo
description: 同步 FIFO，单时钟域，参数化深度与位宽。
srs_ref: docs/srs/sync_fifo.md
srs_version: 0.1.0

parameters:
  - name: DEPTH
    type: int
    default: 512
    range: [16, 8192]
    description: FIFO 深度，建议为 2 的幂
  - name: WIDTH
    type: int
    default: 32
    range: [1, 1024]
    description: 数据位宽

clocks:
  - name: clk
    freq_mhz: 200
    domain: main

resets:
  - name: rst_n
    polarity: active_low
    sync: async_assert_sync_release
    domain: main

ports:
  - {name: wr_en,   dir: in,  width: 1,        description: 写使能}
  - {name: wr_data, dir: in,  width: WIDTH,    description: 写入数据}
  - {name: full,    dir: out, width: 1,        description: FIFO 满}
  - {name: rd_en,   dir: in,  width: 1,        description: 读使能}
  - {name: rd_data, dir: out, width: WIDTH,    description: 读出数据}
  - {name: empty,   dir: out, width: 1,        description: FIFO 空}

protocols:
  - type: handshake
    scope: write
    valid: wr_en
    ready: "!full"
  - type: handshake
    scope: read
    valid: "!empty"
    ready: rd_en

registers:
  # 寄存器映射（基于 Neorv32 文档模板增强）
  # 每个寄存器由 address + name + fields 组成
  - address: 0x00
    name: CTRL
    description: 控制寄存器
    fields:
      - {bits: "0",      name: "enable",     access: rw, reset: 0, description: 模块使能}
      - {bits: "1",      name: "mode",       access: rw, reset: 0, description: 工作模式 (0=直通, 1=存储)}
      - {bits: "7:2",    name: "prescaler",  access: rw, reset: 0, description: 时钟预分频比}
  - address: 0x04
    name: STATUS
    description: 状态寄存器（只读）
    fields:
      - {bits: "0",      name: "busy",       access: ro, reset: 0, description: 模块忙标志}
      - {bits: "4:1",    name: "fifo_level", access: ro, reset: 0, description: 当前 FIFO 占用深度}
  - address: 0x08
    name: DATA
    description: 数据寄存器
    fields:
      - {bits: "31:0",   name: "data",       access: rw, reset: 0, description: 读写数据}

interrupts:
  # 中断映射
  - {name: "done_irq",   channel: 0, type: fast,   description: 操作完成中断}
  - {name: "error_irq",  channel: 1, type: normal, description: 错误中断}

timing:
  - {from: wr_en, to: rd_data, latency: 1, type: cycle, description: 直通模式延迟}

trace:
  # 与 SRS RTM 双向追溯
  - {req: FR-001, ports: [wr_en, wr_data, full],  protocol: write}
  - {req: FR-002, ports: [rd_en, rd_data, empty], protocol: read}
  - {req: NFR-001, clock: clk}
```

---

## 字段说明（摘要）

| 字段 | 必填 | 说明 |
|------|------|------|
| `hid_version` | 是 | HID 文档版本（SemVer） |
| `hid_status` | 是 | `hid_draft`（前置草稿）或 `hid_baseline`（定稿） |
| `module` | 是 | 顶层模块名，与 RTL 一致 |
| `srs_ref` / `srs_version` | 是（baseline 阶段） | 上游 SRS 路径与版本；`hid_baseline` 必须填写，且 SRS 必须为 `baseline` 状态 |
| `parameters[]` | 否 | Verilog `parameter` 列表 |
| `clocks[]` | 是 | 时钟域定义 |
| `resets[]` | 是 | 复位定义 |
| `ports[]` | 是 | 顶层端口（`width` 支持表达式引用 parameter） |
| `registers[]` | 推荐 | 内存映射寄存器（address/name/fields[]），每个 field 含 bits/name/access/reset/description |
| `interrupts[]` | 否 | 中断映射（name/channel/type/description） |
| `protocols[]` | 否 | 高层协议描述（handshake / axi-lite / axi-stream / valid-ready / 自定义） |
| `timing[]` | 否 | 关键时序约束（延迟、节拍） |
| `trace[]` | 推荐 | 反向追溯到 SRS 需求，与 SRS RTM 形成双向对应 |

> 完整字段约束、枚举值、必填项请以 `docs/schemas/hid.schema.json` 为准。

---

## 从 HID Draft 到 HID Baseline 的典型流程

1. 工程师（或 Agent）基于 Spec 创建初始 `hid_draft`
2. `hid_draft` 与 Spec 一起作为需求对齐 Agent 的输入，参与 SRS 草稿生成
3. SRS 对齐流程中可能检出 HID Draft 中的缺失/冲突，记录在 SRS 问题清单和修订建议中
4. 工程师根据修订建议修改 HID Draft
5. SRS 达到 Baseline 后，HID Draft 重新审定或由架构 Agent 重新生成
6. 更新 `hid_status` 为 `hid_baseline`，锁定为 RTL/验证的接口契约

---

## 工具约定

- 校验：`ajv validate -s docs/schemas/hid.schema.json -d docs/hid/<x>.yaml`
- 生成端口：未来在 `tools/hid2sv.py` 中实现，依据本 schema 输出 `.sv` 接口。
