# sync_fifo — 金标准同步 FIFO 参考实现

本目录包含 `sync_fifo` 的金标准 RTL 实现及配套 testbench，可作为：

- VeriAI 内置模块库的参考质量基准
- 后续 DUT 变体或 AI 生成代码的对标验证入口
- CI 回归测试的基础用例集

---

## 文件清单

| 文件 | 说明 |
|------|------|
| `sync_fifo.v`    | 金标准可综合 RTL（Verilog-2001） |
| `tb_sync_fifo.v` | 覆盖全部边界条件的 testbench |
| `Makefile`       | 仿真脚本（基于 Icarus Verilog） |
| `README.md`      | 本文档 |

---

## 接口说明

```verilog
module sync_fifo #(
  parameter integer DEPTH = 16,  // 队列深度，必须为 2 的幂（用户保证，RTL 不做强制检查）
  parameter integer WIDTH = 8    // 数据位宽
)(
  input  wire               clk,
  input  wire               rst_n,      // 同步低有效复位
  input  wire               wr_en,
  input  wire [WIDTH-1:0]   wr_data,
  input  wire               rd_en,
  output reg  [WIDTH-1:0]   rd_data,    // 寄存输出，rd_en 后一拍有效
  output wire               full,
  output wire               empty,
  output wire [$clog2(DEPTH):0] data_count
);
```

### 边界行为规范

| 场景 | 预期行为 |
|------|----------|
| 写入时 `full=1` | 写操作静默丢弃，指针/计数不变 |
| 读取时 `empty=1` | 读操作静默丢弃，`rd_data` 保持旧值 |
| 同周期读 + 写（非空非满） | 两者均执行，`data_count` 不变 |
| 复位后 | `wr_ptr=rd_ptr=data_count=0`，`empty=1`，`full=0` |
| 运行中复位 | 状态立即清零，与复位前数据无关 |

---

## 如何运行仿真

### 前置依赖

```bash
# Debian/Ubuntu
sudo apt install iverilog

# macOS (Homebrew)
brew install icarus-verilog
```

### 运行

```bash
cd lib/fifo
make          # 编译 + 运行，终端输出 PASS/FAIL 摘要
make wave     # 同上并用 GTKWave 查看波形（需安装 gtkwave）
make clean    # 清理编译产物
```

### 预期输出（全部通过）

```
========================================
  sync_fifo Testbench  DEPTH=8 WIDTH=8
========================================

[TC-01] Reset state
  PASS  empty_after_reset
  PASS  full_after_reset
  PASS  count_after_reset
...
========================================
  TOTAL: N PASS, 0 FAIL
========================================
  ALL TESTS PASSED
```

若出现任何 `FAIL` 行，即视为验证不通过。

---

## 验证覆盖矩阵

| 测试用例 | 编号 | 覆盖场景 |
|----------|------|----------|
| 复位状态检查 | TC-01 | 复位后 empty=1、full=0、count=0 |
| 单次写读 | TC-02 | 正常写入后读出，数据一致；标志翻转正确 |
| 填满 | TC-03 | 连续写至 DEPTH 条目，`full` 置位 |
| 满写防护 | TC-04 | `full=1` 时写操作不改变状态 |
| 空读防护 | TC-05 | `empty=1` 时读操作不改变状态 |
| 顺序突发读写 | TC-06 | 写满后按 FIFO 顺序逐一读出，数据无乱序 |
| 同周期读写 | TC-07 | `wr_en=rd_en=1`（非边界），`data_count` 不变 |
| 运行中复位 | TC-08 | 中途拉低 `rst_n`，状态立即清零 |
| 指针回绕 | TC-09 | 写满→全读→再次写满，指针回绕后行为正确 |
| 满状态排空 | TC-10 | 从满状态连续读出，数据顺序正确，最终 `empty=1` |

---

## 验收检查清单（Reviewer）

以下全部条件必须满足，PR 方可合入：

- [ ] **RTL 可综合**：`sync_fifo.v` 使用 Verilog-2001 可综合子集，无 `initial`（仅 testbench 使用）
- [ ] **边界行为文档化**：README 明确说明满写/空读/同周期读写/复位后语义
- [ ] **testbench 全通过**：`make` 输出 `FAIL` 条目数为 0
- [ ] **testbench 覆盖 10 类场景**：TC-01 至 TC-10 全部包含
- [ ] **参数化验证**：默认参数（DEPTH=8, WIDTH=8）与最小参数（DEPTH=2, WIDTH=1）均可正常编译
- [ ] **无不必要的大规模重构**：PR 只包含 `lib/fifo/` 目录变更及根 README 更新
- [ ] **Makefile 可执行**：`make` 命令文档与实际脚本一致，`clean` 目标有效

---

## 对照新 DUT / AI 生成代码

当需要验证新 FIFO 变体或 AI 生成代码时，请执行以下步骤：

1. 将待测模块命名为 `sync_fifo_dut`（或修改 `tb_sync_fifo.v` 中的 `DUT` 实例名）
2. 将 `DUT_SRC` 替换为新文件：`make DUT_SRC=<your_file.v>`
3. 确保接口与本金标准一致（相同端口名和方向）
4. 运行 `make` 并确认全部 TC 通过
5. 若任何 TC 失败，对照本 README 中的边界行为规范进行排查

---

## 参考资料

- [Clifford Cummings – "Simulation and Synthesis Techniques for FIFO Design"](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf) — 业界标准 FIFO 设计指南
- [Icarus Verilog 官网](http://iverilog.icarus.com/)
- 本仓库 [`docs/resources.md`](../../docs/resources.md)：更多可信开源资源
