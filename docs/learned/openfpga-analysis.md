# OpenFPGA 架构分析

> 日期：2026-04-28 | 来源：OpenFPGA 文档、VPR 架构描述语言 | 对 VeriAI 用途：多目标 FPGA 架构后端可行性评估

---

## 一、OpenFPGA 是什么

OpenFPGA 是学术级的开源 FPGA IP 生成器，核心能力：

```
XML 架构描述 → OpenFPGA → 完整 FPGA 网表（Verilog）→ 硅验证
                  │
                  ├── Yosys (综合)
                  ├── VPR (布局布线)
                  └── 自研 bitstream 生成
```

**与商业工具的本质区别**：
- Vivado/Vitis：针对 Xilinx 固定架构的 EDA 工具
- OpenFPGA：**生成** FPGA 架构本身 + 配套 EDA 工具链
- 学术界用它设计新 FPGA 架构，做架构研究

---

## 二、FPGA 架构 XML 描述

### 2.1 基于 VPR 的扩展 XML

OpenFPGA 复用并扩展了 VPR（Versatile Place and Route）的架构描述语言：

```xml
<!-- 逻辑块定义 -->
<pb_type name="clb" physical_pin_share="true">
  <pb_type name="fle" num_pb="8">
    <pb_type name="ble" num_pb="1">
      <pb_type name="lut"  blif_model=".names" num_pb="1"/>
      <pb_type name="ff"   blif_model=".latch" num_pb="1"/>
    </pb_type>
  </pb_type>
</pb_type>

<!-- 路由结构 -->
<switchlist>
  <switch type="mux" name="sb_mux" R="100" Cin="1e-15" Cout="1e-15"/>
</switchlist>
```

### 2.2 描述层次

| 层次 | XML 元素 | 含义 |
|------|---------|------|
| 芯片级 | `<layout>` | 芯片尺寸、IO 分布 |
| 块级 | `<complexblock>` | CLB/DSP/BRAM 的架构 |
| 原语级 | `<pb_type>` | LUT/FF/MUX 的组合 |
| 路由级 | `<switchlist>` `<segmentlist>` | 开关盒和连线延迟模型 |
| 物理级 | OpenFPGA 扩展 | 物理 tile 标注、时钟网络 |

### 2.3 OpenFPGA 关键扩展

- **物理 Tile 标注**：将逻辑块映射到物理布局
- **开关块 (GSB)**：通用开关块模型，描述可编程互连
- **时钟网络**：专用时钟布线资源描述
- **Fabric Key**：比特流到物理资源的映射键

---

## 三、工具链集成

```
Verilog RTL
    │
    ▼
Yosys ──→ 综合网表 (.blif)
    │
    ▼
VPR ──────→ 布局布线
    │         (使用 XML 架构描述)
    ▼
OpenFPGA ─→ Fabric 网表 (Verilog)
    │         Bitstream 设置
    ▼
硅验证 / FPGA 烧写
```

---

## 四、对 VeriAI 的可行性评估

### 4.1 短期（不可行）

- OpenFPGA 的目标是**设计新 FPGA 架构**，不是**适配现有架构**
- 对 VeriAI 当前目标（Xilinx 7 系列）没有直接帮助
- 工具链复杂度远高于 VeriAI 需要的范围

### 4.2 中期（参考价值）

- VPR XML 的**逻辑块建模方法**可以作为 VeriAI 描述目标 FPGA 资源的参考
- 例如：`pb_type` 层次树 → 目标 FPGA 可用资源清单

### 4.3 长期（潜在方向）

如果 VeriAI 未来要支持"多目标 FPGA 架构"：
1. 用类似 VPR XML 的语言描述每种目标 FPGA 的可用资源
2. AI 根据目标架构选择合适的逻辑映射策略
3. 自动生成针对特定 FPGA 架构优化的 RTL

但这是 Phase 10+ 的话题，当前不必投入。

---

## 五、结论

| 维度的 | 评估 |
|--------|------|
| 当前可用性 | ❌ 对 VeriAI 当前目标无直接帮助 |
| 设计思想参考 | ⚠️ FPGA 资源建模方法有参考价值 |
| 未来集成可能 | ★★ 作为多架构后端的远期候选项 |
| 建议动作 | **不投入代码，保留概念笔记** |

**一句话总结**：OpenFPGA 解决的是"如何设计一个 FPGA"，VeriAI 解决的是"如何在已有 FPGA 上写 RTL"。两个问题的交集目前很小。

---

## 六、变更记录

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-04-28 | 0.1.0 | 初稿：OpenFPGA 架构分析、与 VeriAI 可行性评估 |
