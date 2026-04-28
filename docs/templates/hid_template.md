# 硬件接口描述模板（HID Template）

> 由"架构 Agent"基于 SRS 自动产出，作为 RTL Agent / 验证 Agent 的输入契约。
> **正文**为 YAML 结构化描述，可被 `docs/schemas/hid.schema.json` 自动校验，
> 也可被脚本一键生成 SystemVerilog 接口、端口列表、UVM agent 骨架。
>
> 复制本文件为 `docs/hid/<module_name>.yaml` 后填写。
>
> 字段语义、取值范围与必填项以 `docs/schemas/hid.schema.json` 为准。

---

## 示例 / 起始点

```yaml
# yaml-language-server: $schema=../schemas/hid.schema.json

hid_version: 0.1.0
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

timing:
  - {from: wr_en, to: rd_data, latency: 1, type: cycle, description: 直通模式延迟}

trace:
  # 与 SRS RTM 对齐
  - {req: FR-001, ports: [wr_en, wr_data, full],  protocol: write}
  - {req: FR-002, ports: [rd_en, rd_data, empty], protocol: read}
  - {req: NFR-001, clock: clk}
```

---

## 字段说明（摘要）

| 字段 | 必填 | 说明 |
|------|------|------|
| `hid_version` | 是 | HID 文档版本（SemVer） |
| `module` | 是 | 顶层模块名，与 RTL 一致 |
| `srs_ref` / `srs_version` | 是 | 上游 SRS 路径与版本 |
| `parameters[]` | 否 | Verilog `parameter` 列表 |
| `clocks[]` | 是 | 时钟域定义 |
| `resets[]` | 是 | 复位定义 |
| `ports[]` | 是 | 顶层端口（`width` 支持表达式引用 parameter） |
| `protocols[]` | 否 | 高层协议描述（handshake / axi-lite / axi-stream / valid-ready / 自定义） |
| `timing[]` | 否 | 关键时序约束（延迟、节拍） |
| `trace[]` | 推荐 | 反向追溯到 SRS 需求 |

> 完整字段约束、枚举值、必填项请以 `docs/schemas/hid.schema.json` 为准。

---

## 工具约定

- 校验：`ajv validate -s docs/schemas/hid.schema.json -d docs/hid/<x>.yaml`
- 生成端口：未来在 `tools/hid2sv.py` 中实现，依据本 schema 输出 `.sv` 接口。
