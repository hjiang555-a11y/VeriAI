# VeriAI - AI辅助FPGA全链条开发平台

**VeriAI** 是一个开源的 AI 辅助 FPGA 全链条开发平台，目标是让工程师通过自然语言 + 任务书，快速完成从需求到可综合 RTL 的全流程。

## 核心特性
- **全链条自动化**：任务书 → 软件需求分析 → 硬件架构定义 → RTL 代码生成 → 验证
- **高质量 Verilog 库**：内置专业级参数化模块，完全兼容 Virtex-7 / 7 系列
- **多代理协作**：基于 Spec2RTL-Agent 架构，自动规划、编码、反思、修复
- **中文优先**：完美支持中文任务书和提示

**当前版本**：v0.2 FullChain

## 快速开始
直接双击打开 `veriai_fullchain_demo.html` 即可体验。

## 技术路线图
### Phase 1（优先）
- 扩展 Verilog 库到 12+ 模块
- 升级为 React + TypeScript + Monaco Editor
- 接入真实 LLM（Qwen2.5-Coder / DeepSeek-Coder-V2）
- 实现 PDF 任务书解析

### Phase 2
- 多代理 Spec2RTL 系统
- FastAPI 后端 + Docker 部署

## 仓库初始结构

```
VeriAI/
├── veriai_fullchain_demo.html   # 单文件全链条演示（无需安装）
├── src/                         # 源代码目录
│   ├── agents/                  # 多代理模块
│   └── pipeline/                # 全链条流水线
├── lib/                         # 参数化 Verilog 模块库
│   ├── fifo/
│   ├── uart/
│   └── axi/
├── docs/                        # 文档
│   └── spec_template.md         # 任务书模板
└── README.md
```

## Topics
`fpga` `verilog` `ai` `llm` `spec2rtl` `xilinx` `open-source` `chinese`
