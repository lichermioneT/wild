# Bonn Balloon Dynamic Filter Result Analysis

Analyzed outputs:

```text
output/dynamic_filter_on/Bonn/bonn_balloon/
output/dynamic_filter_off/Bonn/bonn_balloon/
```

## Completion Status

This run produced keyframe trajectory metrics for both settings:

```text
output/dynamic_filter_on/Bonn/bonn_balloon/traj/metrics_kf_traj.txt
output/dynamic_filter_off/Bonn/bonn_balloon/traj/metrics_kf_traj.txt
```

However, the run did not produce:

```text
metrics_full_traj.txt
est_poses_full.txt
final_gs.ply
```

So the current result should be treated as a **keyframe trajectory comparison**,
not a complete full-trajectory/final-map result.

## Keyframe ATE Result

| Setting | KF ATE RMSE (m) | KF ATE RMSE (cm) | Mean (cm) | Median (cm) | Max (cm) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Dynamic filter OFF | 0.028792 | 2.879 | 2.665 | 2.362 | 4.952 |
| Dynamic filter ON | 0.029079 | 2.908 | 2.690 | 2.387 | 4.939 |

Difference:

```text
ON - OFF = +0.000287 m = +0.0287 cm
relative change = +0.996%
```

Interpretation:

```text
On bonn_balloon, dynamic filtering did not improve keyframe ATE.
The ON result is about 1.0% worse than OFF, but the absolute difference is only
0.29 mm, so this is a very small effect on this sequence.
```

## Dynamic Reliability Statistics

Available only for the ON run:

```text
output/dynamic_filter_on/Bonn/bonn_balloon/dynamic_filter_stats.csv
```

Summary over 197 logged iterations:

| Metric | Mean | Median | Min | Max |
| --- | ---: | ---: | ---: | ---: |
| reliability_mean | 0.594 | 0.593 | 0.329 | 0.746 |
| dynamic_ratio | 0.340 | 0.320 | 0.194 | 0.805 |
| dynamic_score_mean | 0.514 | 0.521 | 0.358 | 0.700 |
| uncertainty_score_mean | 0.709 | 0.706 | 0.509 | 0.876 |
| rgb_score_mean | 0.388 | 0.406 | 0.232 | 0.558 |
| depth_score_mean | 0.296 | 0.280 | 0.017 | 0.709 |

By optimization stage:

| Stage | reliability_mean | dynamic_ratio | dynamic_score_mean |
| --- | ---: | ---: | ---: |
| Early | 0.595 | 0.312 | 0.518 |
| Middle | 0.590 | 0.362 | 0.515 |
| Late | 0.599 | 0.345 | 0.509 |

Interpretation:

```text
The filter is actively down-weighting a substantial region of the image:
the estimated dynamic ratio is about 34% on average.

The reliability mean remains around 0.59 across early/middle/late stages, which
means the temporal EMA is stable rather than collapsing to all-static or
all-dynamic weights.

The largest evidence source is learned uncertainty, followed by RGB residual,
then depth conflict. This supports keeping the component ablation:
uncertainty_only / residual_only / no_temporal.
```

## Paper-Level Conclusion For This Single Sequence

This one sequence alone does **not** support the claim that the dynamic filter
improves trajectory accuracy. The fair wording is:

```text
On bonn_balloon, the proposed dynamic reliability filter produces a stable
dynamic reliability mask and identifies about one third of pixels as low
reliability, but the keyframe ATE is almost unchanged compared with the
non-filtered baseline.
```

For the paper, this result is still useful as:

```text
1. A diagnostic example for reliability-mask behavior.
2. A neutral/edge case showing that the filter does not always reduce ATE.
3. A reason to report averages over all Bonn/TUM/Mocap dynamic sequences instead
   of drawing a conclusion from one sequence.
```

## Next Check

Because full trajectory metrics and final Gaussian map files are missing, the
next run should verify that each command reaches the end of `SLAM.terminate()`
and creates:

```text
traj/metrics_full_traj.txt
traj/est_poses_full.txt
final_gs.ply
uncertainty_mlp_weight.pth
```
