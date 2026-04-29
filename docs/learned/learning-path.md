# VeriAI 推荐学习路径

> 面向 FPGA 初学者和想要用 AI 加速 FPGA 开发的工程师。
> 三步路径：apio（工具链）→ LiteX（SoC 构建）→ VeriAI（AI 加速）

---

## 学习路径总览

```
第 1 步：apio                   第 2 步：LiteX                  第 3 步：VeriAI
┌───────────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│ 快速上手 FPGA      │      │ 理解 SoC 构建方法     │      │ 用 AI 加速            │
│ 开发流程           │ ───→ │ Python 描述硬件       │ ───→ │ Spec → SRS → RTL     │
│                   │      │ 自动生成完整 SoC      │      │ 文档对齐优先         │
│ 目标：第一个 LED   │      │ 目标：生成 Murax SoC  │      │ 目标：AI 辅助完成    │
│ 闪烁项目          │      │                      │      │ 模块设计             │
└───────────────────┘      └──────────────────────┘      └──────────────────────┘
     1-2 天                       3-5 天                         持续
```

---

## 第 1 步：apio — 快速上手 FPGA 开发流程

### 学习目标

- [ ] 安装 apio + oss-cad-suite 工具链
- [ ] 理解 FPGA 开发全流程：编写 RTL → 综合 → 布局布线 → 生成比特流 → 下载
- [ ] 完成第一个 LED 闪烁项目
- [ ] 理解引脚约束（PCF）文件的作用
- [ ] 学会运行仿真（apio sim）查看波形

### 推荐学习顺序

| 顺序 | 示例 | 知识点 |
|:---:|------|--------|
| 1 | `alhambra-ii/ledon` | 端口赋值、PCF 引脚映射 |
| 2 | `alhambra-ii/blinky` | 计数器、时钟分频、时序逻辑 |
| 3 | `icebreaker/buttons` | 输入信号、条件控制 |
| 4 | `alhambra-ii/bcd-counter` | 层次化设计、多 testbench |
| 5 | `alhambra-ii/pll` | PLL 配置、时钟管理 |

### 验证方式

- `apio build` 综合成功
- `apio sim` 波形符合预期
- 理解 .v / .pcf / apio.ini 三个文件的关系

### 参考资源

- apio 官方文档：https://fpgawars.github.io/apio/docs
- oss-cad-suite：https://github.com/YosysHQ/oss-cad-suite-build

---

## 第 2 步：LiteX — 理解 SoC 构建方法

### 学习目标

- [ ] 理解 Migen FHDL 的 DSL → Verilog 生成链路
- [ ] 理解 LiteX 的三层架构：Migen → CSR → Wishbone → SoCCore
- [ ] 用 Python 描述一个简单硬件模块并生成 Verilog
- [ ] 理解 CSR 自动生成机制（CSRField / CSRStorage / CSRStatus）
- [ ] 理解 Wishbone 总线的主从通信模型

### 推荐学习顺序

| 顺序 | 内容 | 关键文件 |
|:---:|------|---------|
| 1 | 运行 Migen Counter 示例 | `examples/litex/01_migen_counter.py` |
| 2 | 运行子模块组合示例 | `examples/litex/02_migen_submodules.py` |
| 3 | 阅读 LiteX 架构分析 | `docs/learned/litex-architecture.md` |
| 4 | 阅读 CSR 系统源码 | `litex/soc/interconnect/csr.py` |
| 5 | 阅读 Wishbone 总线源码 | `litex/soc/interconnect/wishbone.py` |

### 验证方式

- 能自己写一个 Migen 模块并生成 Verilog
- 能解释 CSRField → CSRStorage → AutoCSR 的完整链路
- 能画出 Wishbone 的 Arbiter + Decoder 拓扑图

### 参考资源

- LiteX Wiki：https://github.com/enjoy-digital/litex/wiki
- Migen FHDL 文档：https://m-labs.hk/migen/manual/fhdl.html

---

## 第 3 步：VeriAI — 用 AI 加速从 Spec 到 RTL

### 学习目标

- [ ] 理解 VeriAI 的全链条工作流：Spec + HID → SRS → HID Baseline → RTL → Verify
- [ ] 理解文档对齐优先的设计哲学
- [ ] 能编写合格的任务书（Spec）和硬件接口描述（HID Draft）
- [ ] 理解 SRS Baseline 的 7 条判定标准
- [ ] 能使用 VeriAI 完成一个真实模块的设计

### 推荐学习顺序

| 顺序 | 内容 | 关键文件 |
|:---:|------|---------|
| 1 | 打开全链条 Demo | `veriai_fullchain_demo.html` |
| 2 | 阅读 Agent 流程定义 | `docs/agent-flow.md` |
| 3 | 阅读 RTM 追溯规范 | `docs/rtm-and-verification.md` |
| 4 | 学习 Spec 模板 | `docs/templates/spec_template.md` |
| 5 | 学习 SRS 模板 | `docs/templates/srs_template.md` |
| 6 | 学习 HID 模板 | `docs/templates/hid_template.md` |
| 7 | 完成 sync_fifo 示例 | `lib/fifo/` |

### 验证方式

- 能独立编写一份合格的任务书
- 能识别 Spec 与 HID Draft 之间的不一致
- 能判定一份 SRS 是否满足 Baseline 条件

### 设计模式参考

| 模式 | 来源 | 文档 |
|------|------|------|
| 插件化模块组合 | VexRiscv | `docs/learned/vexriscv-design-patterns.md` |
| 寄存器自动生成 | LiteX CSR | `docs/learned/litex-architecture.md` §三 |
| 总线解耦适配 | LiteX + VexRiscv | `docs/learned/rag-index.md` §三 |
| 外设文档模板 | Neorv32 | `docs/learned/neorv32-doc-analysis.md` |

---

## 变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：三步学习路径 + 学习目标 + 验证方式 |
