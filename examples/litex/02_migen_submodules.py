#!/usr/bin/env python3
"""
Step 2: 子模块组合 — 用 Counter 构建分频器 + LED 闪烁控制器
演示 Migen 的 Module 组合模型：submodules += ...
"""

from migen import *
from migen.fhdl import verilog


class Prescaler(Module):
    """预分频器：将系统时钟分频为更低频率"""

    def __init__(self, width=26):
        self.enable = Signal()         # 分频使能脉冲输出
        cnt = Signal(width)
        self.sync += cnt.eq(cnt + 1)
        self.comb += self.enable.eq(cnt == (2**width - 1))


class Blinker(Module):
    """LED 闪烁器：使用预分频器的使能信号翻转 LED"""

    def __init__(self, prescaler_width=26):
        self.led = Signal()            # LED 输出

        # 子模块实例化
        self.submodules.prescaler = Prescaler(prescaler_width)

        led_reg = Signal()
        self.sync += If(self.prescaler.enable,
            led_reg.eq(~led_reg)
        )
        self.comb += self.led.eq(led_reg)


class Top(Module):
    """顶层组合"""

    def __init__(self):
        self.submodules.blinker = Blinker(prescaler_width=4)
        self.led = Signal()
        self.comb += self.led.eq(self.blinker.led)


def main():
    dut = Top()
    print("=== VeriAI 分析：Migen 子模块组合模型 ===")
    print(f"顶层模块类型: {type(dut).__name__}")
    print(f"子模块列表: {list(dut._submodules)}")
    print()
    print("=== 生成的 Verilog ===")
    print(verilog.convert(dut, ios={dut.led}))


if __name__ == "__main__":
    main()
