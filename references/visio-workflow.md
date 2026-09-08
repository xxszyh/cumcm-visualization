# Visio 逻辑图工作流

## 适用范围

使用 Visio 绘制模型框架、算法流程、泳道、状态转移、变量依赖和几何关系。凡是使用 Visio，必须同时保存 VSDX 和 PNG。

## 推荐流程

1. 先把图写成节点-边规格，不直接在画布上堆框。
2. 使用 scripts/render_visio_flowchart.ps1 生成第一版。
3. 打开 VSDX 检查中文换行、箭头交叉、判断分支和页面边界。
4. 必要时手工微调；每次修改后重新导出同名 PNG。
5. 把 VSDX、PNG 和规格 JSON 一起登记到 figure_index.json。

## 规格 JSON

页面单位为英寸，坐标原点位于左下角。建议横版 24 × 16，以便 Visio 默认位图导出获得足够像素。

示例字段：

    {
      "title": "遗传算法求解流程",
      "page": {"width": 24, "height": 16},
      "nodes": [
        {"id": "start", "text": "输入参数与约束", "x": 12, "y": 14, "w": 5, "h": 1.1, "kind": "terminal"},
        {"id": "init", "text": "初始化种群", "x": 12, "y": 11.8, "w": 5, "h": 1.1, "kind": "process"},
        {"id": "judge", "text": "满足停止条件？", "x": 12, "y": 7.8, "w": 5, "h": 1.3, "kind": "decision"}
      ],
      "edges": [
        {"from": "start", "to": "init"},
        {"from": "judge", "to": "start", "label": "否", "dashed": true}
      ]
    }

支持的 kind：terminal、process、decision、data。脚本不替代人工判断；复杂回边、泳道和交叉最少化仍需打开 VSDX 复核。

## 排版规则

- 同级节点等宽、等高、等间距。
- 主路径用实线，反馈/迭代用虚线，异常路径使用强调色。
- 连接线尽量正交；不可避免交叉时，调整层级而不是堆叠箭头。
- 每个框 6–18 个汉字为宜；超过两行通常应拆分。
- 字号在最终插入论文后仍应不小于约 8 pt。
- 页面四周保留 5%–8% 留白，标题不嵌入流程节点。

## 导出与保留

- 源文件：paper_output/figures/source/fig_qN_*.vsdx
- 结构规格：paper_output/figures/source/fig_qN_*.json
- 论文图片：paper_output/figures/fig_qN_*.png
- 若 PNG 宽度不足，增大 Visio 页面尺寸后重新导出，不靠低质量放大补救。
- 自动化运行后必须关闭文档并释放 COM 对象；失败时保留错误信息，不删除已有 VSDX。
