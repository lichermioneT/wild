# CPCC 论文填数说明

论文草稿：

```text
docs/CPCC_dynamic_filter_paper_draft.docx
```

## 需要先跑的实验

主效果 ON/OFF：

```bash
bash run_dynamic_filter_ablation.sh
```

组件消融：

```bash
bash scripts_run/run_dynamic_filter_component_bonn.sh
```

## 表格对应关系

### 表1：动态过滤 ON/OFF 主实验

填入：

```text
output/dynamic_filter_on_eval.csv
output/dynamic_filter_off_eval.csv
```

需要填：

```text
Bonn Dynamic 平均 ATE
TUM RGB-D Dynamic 平均 ATE
Wild-SLAM Mocap 平均 ATE或其它可用指标
全部平均
相对提升 = (OFF - ON) / OFF
```

### 表2：Bonn Dynamic 组件消融

填入：

```text
output/dynamic_filter_off_eval.csv
output/dynamic_filter_uncertainty_only_eval.csv
output/dynamic_filter_residual_only_eval.csv
output/dynamic_filter_no_temporal_eval.csv
output/dynamic_filter_on_eval.csv
```

对应论文行：

```text
OFF
Uncertainty only
Residual only
No temporal
Full
```

### 表3：运行开销与统计信息

显存和运行时间需要从实验日志或 `nvidia-smi` 记录中填。

`dynamic_ratio` 从各场景的：

```text
output/dynamic_filter_on/<dataset>/<scene>/dynamic_filter_stats.csv
```

取平均。

## 图对应关系

### 图1：可靠性统计曲线

使用：

```text
dynamic_filter_stats.csv
```

建议画：

```text
x轴：iteration
y轴：dynamic_ratio 或 reliability_mean
曲线：full / uncertainty_only / residual_only / no_temporal
```

### 图2：定性重建比较

推荐场景：

```text
Bonn/bonn_person_tracking2
Bonn/bonn_crowd
TUM_RGBD/freiburg3_walking_xyz
Wild_SLAM_Mocap/person_tracking
Wild_SLAM_Mocap/crowd
```

比较：

```text
output/dynamic_filter_off/<dataset>/<scene>/
output/dynamic_filter_on/<dataset>/<scene>/
```

重点展示动态物体附近的漂浮高斯、背景污染和边缘清晰度差异。

## 还需要人工替换

```text
作者、单位、邮箱
英文作者和单位
参考文献中标了【待核对】的条目
所有【待填】数据
图1、图2图片
```
