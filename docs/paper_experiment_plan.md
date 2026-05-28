# Paper Experiment Plan

This project now has one clear method claim:

**Temporally calibrated dynamic reliability filtering** reduces the contribution
of moving foreground pixels during Gaussian mapping by combining learned
uncertainty, RGB residuals, foreground depth conflicts, spatial smoothing, and
per-keyframe temporal EMA.

## What To Run

### 1. Main Effect: Dynamic Filter On vs Off

Run:

```bash
bash run_dynamic_filter_ablation.sh
```

Outputs:

```text
output/dynamic_filter_on_eval.csv
output/dynamic_filter_off_eval.csv
```

Use this for the main quantitative table:

```text
Table: ATE RMSE on dynamic sequences, Dynamic Filter ON vs OFF
```

What it supports in the paper:

```text
The proposed dynamic reliability filter improves camera trajectory accuracy in
dynamic scenes by reducing gradients from moving foreground distractors.
```

### 2. Component Ablation: Which Cue Matters

Run:

```bash
bash scripts_run/run_dynamic_filter_component_bonn.sh
```

Outputs:

```text
output/dynamic_filter_uncertainty_only_eval.csv
output/dynamic_filter_residual_only_eval.csv
output/dynamic_filter_no_temporal_eval.csv
```

Compare these with:

```text
output/dynamic_filter_on_eval.csv
output/dynamic_filter_off_eval.csv
```

Use this for the ablation table:

```text
Table: Component ablation on Bonn Dynamic

OFF
Uncertainty only
RGB/depth residual only
Full without temporal EMA
Full method
```

What it supports in the paper:

```text
Learned uncertainty, residual evidence, and temporal calibration are
complementary. The full method is more stable than any single cue.
```

### 3. Qualitative Dynamic Removal

Use the outputs:

```text
output/dynamic_filter_on/<dataset>/<scene>/
output/dynamic_filter_off/<dataset>/<scene>/
```

Recommended scenes:

```text
Bonn/bonn_person_tracking2
Bonn/bonn_crowd
TUM_RGBD/freiburg3_walking_xyz
Wild_SLAM_Mocap/person_tracking
Wild_SLAM_Mocap/crowd
```

Use this for qualitative figures:

```text
Figure: reconstructed map / rendered view with dynamic filter OFF vs ON
```

What it supports in the paper:

```text
The ON setting suppresses moving-object floaters and preserves static
background geometry more cleanly.
```

### 4. Reliability Mask Analysis

Each dynamic-filter ON/component scene output includes:

```text
dynamic_filter_stats.csv
```

Use this for a small diagnostic plot:

```text
x-axis: mapping iteration
y-axis: dynamic_ratio or reliability_mean
curves: full, uncertainty_only, residual_only, no_temporal
```

What it supports in the paper:

```text
Temporal EMA stabilizes the dynamic mask over optimization iterations, while
single-frame residual cues fluctuate more.
```

## Minimal Paper Tables

If time is limited, run only:

```bash
bash run_dynamic_filter_ablation.sh
bash scripts_run/run_dynamic_filter_component_bonn.sh
```

Then fill:

```text
Table 1: Main ATE comparison, ON vs OFF, all dynamic datasets
Table 2: Component ablation, Bonn Dynamic
Figure 1: Qualitative map comparison, OFF vs ON
Figure 2: Reliability statistics from dynamic_filter_stats.csv
```
