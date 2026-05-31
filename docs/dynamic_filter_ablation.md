# Dynamic Filter Ablation

This experiment compares the same WildGS-SLAM code and the same data with:

- `mapping.dynamic_filter.activate: True`
- `mapping.dynamic_filter.activate: False`

The original config files are not modified. `run.py` accepts command-line
overrides for this ablation:

```bash
--dynamic-filter on
--dynamic-filter off
--dynamic-filter-ablation consensus
--dynamic-filter-ablation full
--dynamic-filter-ablation uncertainty_only
--dynamic-filter-ablation residual_only
--dynamic-filter-ablation no_temporal
--output-root ./output/dynamic_filter_on/Bonn
```

Results are saved separately:

```text
output/dynamic_filter_on/
output/dynamic_filter_off/
```

## Run

Run all dynamic sequences with both settings:

```bash
bash run_dynamic_filter_ablation.sh
```

The script is intentionally just a command list. You can open it, comment out
lines, and run only the experiments you want.

Run only the `on` commands:

```bash
bash scripts_run/run_dynamic_filter_on.sh
```

Run only the `off` commands:

```bash
bash scripts_run/run_dynamic_filter_off.sh
```

Run component ablations on Bonn:

```bash
bash scripts_run/run_dynamic_filter_component_bonn.sh
```

After finishing, pose summaries are written by:

```bash
python scripts_run/summarize_pose_eval.py
```

The summary CSV files will appear under `output/`, including:

```text
output/dynamic_filter_on_eval.csv
output/dynamic_filter_off_eval.csv
output/dynamic_filter_uncertainty_only_eval.csv
output/dynamic_filter_residual_only_eval.csv
output/dynamic_filter_no_temporal_eval.csv
```
