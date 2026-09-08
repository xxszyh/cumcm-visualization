# cumcm-visualization

面向 CUMCM 数学建模论文的可复现可视化 Skill。它用于规划和生成模型框架图、算法流程图与结果图，默认导出论文可用 PNG；逻辑图同时保留可编辑的 Visio VSDX 和 JSON 结构规格。

## 主要能力

- 将建模假设、状态量、约束、目标函数和求解流程整理成清晰的逻辑图。
- 通过 Visio 自动化生成可编辑 VSDX，并导出高分辨率 PNG。
- 为 Python 结果图提供统一样式、工作区初始化和 PNG 自动校验。
- 维护 `figure_plan.json` 与 `figure_index.json`，保证图、来源、结论和源文件可追溯。

## 目录

- `SKILL.md`：Skill 主说明。
- `agents/`：Codex Skill 元数据。
- `references/`：图形路由、Visio 工作流、质量检查与图形分类参考。
- `scripts/`：Visio 渲染、绘图样式、目录初始化和 PNG 校验脚本。

## 环境

- Windows
- Microsoft Visio（生成 VSDX/导出 PNG 时需要）
- PowerShell 7
- Python 3 与 Pillow（PNG 校验）

## 使用

将本仓库安装为 Codex Skill 后，可提出类似请求：

> 根据当前数学模型生成模型框架图和算法流程图，PNG 用于论文，逻辑图保留 VSDX 源文件。

具体输入约束和交付规范见 `SKILL.md`。

## 许可

MIT License。
