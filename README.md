# cumcm-visualization

面向 CUMCM 数学建模论文的可复现可视化 Skill。它用于规划、生成并审校模型框架图、算法流程图与结果图，默认导出论文可用 PNG；逻辑图同时保留可编辑的 Visio VSDX 和 JSON 结构规格。

## 主要能力

- 将建模假设、状态量、约束、目标函数和求解流程整理成清晰的逻辑图。
- 通过 Visio 自动化生成可编辑 VSDX，并导出高分辨率 PNG。
- 为 Python 结果图提供统一样式、工作区初始化和 PNG 自动校验。
- 维护 `figure_plan.json` 与 `figure_index.json`，保证图、来源、结论和源文件可追溯。
- 提供可迁移的论文图版式规则：透明节点、共享边防叠线、无底色标签、复杂图拆分、二维投影说明、3D 标注避让和最终插入尺寸检查。

## 目录

- `SKILL.md`：Skill 主说明与工作流入口。
- `agents/`：Codex Skill 元数据。
- `references/figure-routing.md`：图形类型与证据链路由。
- `references/visual-design-patterns.md`：通用版式、节点、标签和重叠路径模式。
- `references/python-workflow.md`：Python 论文图工作流。
- `references/visio-workflow.md`：Visio 自动化和源文件保留。
- `references/qa-checklist.md`：逻辑、版式、文件与论文整合检查。
- `scripts/`：Visio 渲染、绘图样式、目录初始化和 PNG 校验脚本。

## 环境

- Windows
- Microsoft Visio（生成 VSDX/导出 PNG 时需要）
- PowerShell 7
- Python 3 与 Pillow（PNG 校验）

## 使用

将本仓库安装为 Codex Skill 后，可提出类似请求：

> 根据当前数学模型生成模型框架图和算法流程图，PNG 用于论文，逻辑图保留 VSDX 源文件。

具体输入约束、版式规则和交付规范见 `SKILL.md`。

## 许可

MIT License。
