# cumcm-visualization

[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek_Harness-DSH_Skill-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)
[![CUMCM](https://img.shields.io/badge/CUMCM-论文可视化-d97706)](https://www.mcm.edu.cn/)

兼容 DeepSeek Harness（DSH）、Codex 及其他 `SKILL.md` Agent 的可复现建模可视化技能。它以 CUMCM 论文为核心，也适用于其他数学建模竞赛和项目，用于规划、生成并审校模型框架图、算法流程图与结果图；默认导出论文可用 PNG，逻辑图同时保留可编辑的 Visio VSDX 和 JSON 结构规格。

## 主要能力

- 将建模假设、状态量、约束、目标函数和求解流程整理成清晰的逻辑图。
- 通过 Visio 自动化生成可编辑 VSDX，并按论文最终插入宽度自动缩放字体、导出 300 dpi PNG 和字号审计报告。
- 为 Python 结果图提供统一样式、工作区初始化和 PNG 自动校验。
- 维护 `figure_plan.json` 与 `figure_index.json`，保证图、来源、结论和源文件可追溯。
- 核查模型比较的实际时间、空间坐标和误差口径；通过输入哈希及运行状态检查发现过期或未完成的结果引用。
- 提供可迁移的论文图版式规则：透明节点、共享边防叠线、无底色标签、复杂图拆分、二维投影说明、3D 标注避让和最终插入尺寸检查。
- 对最终字号设置硬门禁：标题不小于 10 pt、节点不小于 8 pt、边标签不小于 7.5 pt，避免“大画布高清导出、插入论文后文字过小”。

## 目录

- `SKILL.md`：Skill 主说明与工作流入口。
- `agents/`：Codex Skill 元数据。
- `references/figure-routing.md`：图形类型与证据链路由。
- `references/visual-design-patterns.md`：通用版式、节点、标签和重叠路径模式。
- `references/python-workflow.md`：Python 论文图工作流。
- `references/visio-workflow.md`：Visio 自动化和源文件保留。
- `references/qa-checklist.md`：逻辑、版式、文件与论文整合检查。
- `references/model-comparison.md`：数值模型对照及兼容 version 1 的索引追溯字段。
- `scripts/`：Visio 渲染、绘图样式、目录初始化和 PNG 校验脚本。
- `tests/`：PNG、数据追溯和工作区初始化的行为测试。

## 环境

- Windows
- Microsoft Visio（生成 VSDX/导出 PNG 时需要）
- PowerShell 7
- Python 3 与 Pillow（PNG 校验）

仅规划图组、审校已有图片或使用纯 Python 绘图时不要求安装 Visio；VSDX 生成和 Visio 自动导出仅在 Windows + Microsoft Visio 环境可用。

## 安装

### DeepSeek Harness（DSH）

DSH 原生识别目录型 Agent Skill。项目级安装适合只在当前建模仓库启用：

```sh
git clone https://github.com/xxszyh/cumcm-visualization.git .dsh/skills/cumcm-visualization
```

用户级安装可在任意项目中使用：

```sh
git clone https://github.com/xxszyh/cumcm-visualization.git ~/.dsh/skills/cumcm-visualization
```

Windows PowerShell 中可使用：

```powershell
git clone https://github.com/xxszyh/cumcm-visualization.git "$HOME/.dsh/skills/cumcm-visualization"
```

安装后启动或重启 DSH 会话；直接描述论文配图任务，或明确点名 `cumcm-visualization` 即可。DSH 也识别项目级 `.agents/skills/` 和用户级 `~/.agents/skills/`，便于与其他 Agent 共享同一份技能。发现顺序和格式说明见 [DSH Skills 官方文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/subsystems/skills.md)。

### Codex / 其他 Agent Skills 客户端

将仓库复制到对应客户端的 skills 目录；例如 Codex：

```text
~/.codex/skills/cumcm-visualization/
```

## 使用

将本仓库安装为 Codex Skill 后，可提出类似请求：

> 根据当前数学模型生成模型框架图和算法流程图，PNG 用于论文，逻辑图保留 VSDX 源文件。

具体输入约束、版式规则和交付规范见 `SKILL.md`。

## 关键词

`DSH` · `DeepSeek Harness` · `CUMCM` · `数学建模` · `mathematical modeling` · `data visualization` · `scientific visualization` · `论文配图` · `Visio` · `Matplotlib`

### 文件与追溯检查

在本仓库目录执行，下列示例路径需换成实际项目路径：

```sh
python scripts/validate_png.py path/to/figure.png
python scripts/validate_figure_index.py path/to/paper_output/figure_index.json
python scripts/validate_figure_index.py path/to/paper_output/figure_index.json --strict-provenance
python -m unittest discover -s tests -v
```

索引中的相对路径以索引文件所在目录为基准。普通模式兼容旧索引；严格模式要求定量图的输入哈希，计算图还需运行标识和完成状态。PNG 检查识别真实编码及白底上的可见内容。这些检查不验证物理结论，也不能替代人工审图；Python 检查工具和测试不需要 Visio。

## 许可

MIT License。
