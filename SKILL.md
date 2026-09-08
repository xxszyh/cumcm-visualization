---
name: cumcm-visualization
description: 为 CUMCM 数学建模论文规划和生成模型框架图、算法流程图与结果可视化；默认输出 PNG，逻辑图可用 Visio 并保留 VSDX，数据图保留可复现代码。适用于国赛论文配图、模型解释、算法展示、结果对比和稳健性验证；不用于脱离真实模型与数据的装饰性配图。
---

# CUMCM 建模可视化

把一张图当作一段可核验的论证：它必须让评委快速看懂“问题如何进入模型、算法如何求解、结果如何支持结论”。

## 开始前先建立图形契约

对每张图先写清：

1. **核心结论**：评委看完后应记住的一句话。
2. **证据来源**：对应哪一问、哪份真实数据、哪个模型或算法输出。
3. **图形角色**：原理解释、模型框架、算法流程、结果比较、误差诊断、敏感性/稳健性或方案落地。
4. **阅读顺序**：箭头、编号和层级如何形成单一路径。
5. **交付形式**：PNG 必需；Visio 图同时保留 VSDX；代码图同时保留脚本和输入数据路径。

信息不足时，先从现有赛题、模型说明、代码和结果文件中提取，不凭空补造步骤或数值。若缺少影响图义的关键输入，明确列出缺口再询问用户。

## 选择绘图轨道

- **Visio**：优先用于模型总框架、算法流程、变量传递、模块依赖、决策分支、泳道和时序逻辑。使用 [references/visio-workflow.md](references/visio-workflow.md)。交付 .vsdx + .png。
- **Python**：优先用于所有由数据或模型结果驱动的图，如预测对比、残差、敏感性、热力图、空间路径、Pareto 前沿和消融对比。使用 [references/python-workflow.md](references/python-workflow.md)。交付 .py + .png，必要时附 CSV。
- **混合**：一组论文图可以同时采用两轨，但单张图不要把无法追溯的截图拼贴在一起。需要组合时保留每个面板的独立源文件。

默认逻辑图选择 Visio，默认结果图选择 Python。只有 Visio 不可用、用户要求纯代码，或图需要从结构化数据频繁重生成时，才用 Graphviz/NetworkX 绘制逻辑图。

## 工作流

1. 读取当前题目、分问、模型路线、算法伪代码和真实结果。
2. 按 [references/figure-routing.md](references/figure-routing.md) 制定最小图组，避免每问重复一张“万能流程图”。
3. 在项目中建立 paper_output/plan/figure_plan.json、paper_output/figures/、paper_output/figures/source/、paper_output/code/visualization/ 和 paper_output/figure_index.json。
4. 逻辑图先写节点与边的结构化规格，再生成 Visio/PNG；数据图必须直接读取真实结果文件。
5. 图题采用“图 N + 结论性标题”，正文必须解释读图结论，不只写“如下图所示”。
6. 运行视觉和文件检查：PNG 可打开、中文无乱码、文字不截断、颜色在灰度下仍可区分、数值与源数据一致。
7. 在 figure_index.json 记录图号、用途、PNG、源文件、输入数据、生成脚本和对应结论。

可用 scripts/init_figure_workspace.py 初始化目录与索引；Visio 逻辑图可用 scripts/render_visio_flowchart.ps1；PNG 用 scripts/validate_png.py 做基础门禁。

## 论文图的硬约束

- 最终必须有 PNG，优先 300 dpi；通常宽度不少于 1800 px，单栏图也不得小于 1200 px。
- 白底、少色、强层级。通常使用中性灰 + 一个主色 + 一个强调色；红绿不得成为唯一编码。
- 流程图每个节点只表达一个动作或判断，正文级公式不要塞进节点。
- 结果图必须有单位、样本范围、误差定义或统计口径；比较图保持同一坐标尺度。
- 不使用 3D 柱状图、饼图堆叠、彩虹色图、厚阴影、渐变背景、装饰性图标墙。
- 不生成虚假数据，不把 AI 生成插画当作模型证据，不伪造软件界面或实验场景。
- 不能保证任何“AI 检测率”下降。降低模板感的可靠方式是使用团队真实模型、真实数据、可编辑源文件、清楚的图文对应关系，并由参赛者最终复核和改写。

## 交付前检查

按 [references/qa-checklist.md](references/qa-checklist.md) 完成检查。发现数值、单位或因果方向不确定时停止交付该图并回到证据来源核对；只改美观不能掩盖逻辑错误。

## 参考资料路由

- 图形类型与 CUMCM 常用证据链：[references/figure-routing.md](references/figure-routing.md)
- Visio 自动化、源文件保留与导出：[references/visio-workflow.md](references/visio-workflow.md)
- Python 静态图规范、中文字体与导出：[references/python-workflow.md](references/python-workflow.md)
- 最终质量门禁：[references/qa-checklist.md](references/qa-checklist.md)
- 本地优秀论文抽样与开源项目调研记录：[references/source-notes.md](references/source-notes.md)
