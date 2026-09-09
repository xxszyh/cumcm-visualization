# Visio 逻辑图工作流

## 适用范围

使用 Visio 绘制模型框架、算法流程、泳道、状态转移、变量依赖和几何关系。凡是使用 Visio，必须同时保存 VSDX 和 PNG。

## 推荐流程

1. 先把图写成节点-边规格，不直接在画布上堆框。
2. 在规格中先写明论文最终插入宽度和最终字号，再使用 scripts/render_visio_flowchart.ps1 生成第一版。
3. 查看同名 `.typography.json`，确认最终字号门禁为 `PASS`；再打开 VSDX 检查中文换行、箭头交叉、判断分支和页面边界。
4. 必要时手工微调；每次修改后重新导出同名 PNG。
5. 把 VSDX、PNG、规格 JSON 和字号报告一起登记到 figure_index.json。

## 规格 JSON

页面单位为英寸，坐标原点位于左下角。`page.width` 和 `page.height` 是 Visio 源画布尺寸；`page.final_width` 是图片插入论文后的物理宽度，默认 6.5 英寸。源画布可以放大以获得足够像素，但不能因此缩小最终可见字号。

示例字段：

    {
      "title": "遗传算法求解流程",
      "page": {"width": 24, "height": 16, "final_width": 6.5},
      "typography": {
        "title_final_pt": 13,
        "node_final_pt": 9.5,
        "edge_final_pt": 8
      },
      "nodes": [
        {"id": "start", "text": "输入参数与约束", "x": 12, "y": 14, "w": 5, "h": 1.1, "kind": "terminal"},
        {"id": "init", "text": "初始化种群", "x": 12, "y": 11.8, "w": 5, "h": 1.1, "kind": "process", "font_final_pt": 10},
        {"id": "judge", "text": "满足停止条件？", "x": 12, "y": 7.8, "w": 5, "h": 1.3, "kind": "decision"}
      ],
      "edges": [
        {"from": "start", "to": "init"},
        {"from": "judge", "to": "start", "label": "否", "dashed": true, "font_final_pt": 8}
      ]
    }

支持的 kind：terminal、process、decision、data。脚本不替代人工判断；复杂回边、泳道和交叉最少化仍需打开 VSDX 复核。

### 最终字号换算与门禁

渲染器按 `源字号 = 最终字号 × page.width / page.final_width` 将论文中的最终字号换算为 Visio 源文件字号。

默认最终字号为标题 13 pt、节点 9.5 pt、边标签 8 pt。节点或边可用 `font_final_pt` 局部覆盖。硬门禁为标题不小于 10 pt、节点不小于 8 pt、边标签不小于 7.5 pt；低于门禁时脚本在启动 Visio 前报错，不生成文件。旧规格缺少 `final_width` 或 `typography` 时自动使用上述默认值。

每次成功生成会产生同名 `.typography.json`，记录缩放系数、默认字号以及每个节点和带标签边的最终/源字号。PNG 像素检查不能替代该报告：300 dpi 只决定清晰度，不决定字体在论文中是否够大。

## 排版规则

- 同级节点等宽、等高、等间距。
- 主路径用实线，反馈/迭代用虚线，异常路径使用强调色。
- 连接线尽量正交；不可避免交叉时，调整层级而不是堆叠箭头。
- 每个框 6–18 个汉字为宜；超过两行通常应拆分。
- 正文节点在最终插入论文后不得小于 8 pt；普通边标签不得小于 7.5 pt。图中存在大量边标签时优先简化或拆图，不靠压小字号容纳。
- 页面四周保留 5%–8% 留白，标题不嵌入流程节点。

## 导出与保留

- 源文件：paper_output/figures/source/fig_qN_*.vsdx
- 结构规格：paper_output/figures/source/fig_qN_*.json
- 字号报告：paper_output/figures/source/fig_qN_*.typography.json
- 论文图片：paper_output/figures/fig_qN_*.png
- PNG 固定按 300 dpi 导出。若像素不足，可增大源画布或提高导出质量，但必须保持 `page.final_width` 不变并重新通过字号门禁。
- 自动化运行后必须关闭文档并释放 COM 对象；失败时保留错误信息，不删除已有 VSDX。
