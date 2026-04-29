#!/usr/bin/env python3
"""
Step 1: Minimal Migen module — 参数化计数器
演示 Migen DSL 的核心概念：Signal, Module, sync, comb, If
"""

from migen import *
from migen.fhdl import verilog


class Counter(Module):
    """参数化计数器：从 0 计数到 width 位最大值，产生周期脉冲"""

    def __init__(self, width=8):
        self.count = Signal(width)    # 内部计数器 (reg)
        self.tick = Signal()          # 溢出脉冲 (wire)

        # 同步逻辑：每个时钟沿 count + 1
        self.sync += self.count.eq(self.count + 1)

        # 组合逻辑：count 为全 1 时 tick = 1
        self.comb += self.tick.eq(self.count == (2**width - 1))


def main():
    c = Counter(width=4)
    print("=== Migen FHDL 内部表示 ===")
    print(repr(c))
    print("\n=== 生成的 Verilog ===")
    print(verilog.convert(c, ios={c.count, c.tick}))


if __name__ == "__main__":
    main()
