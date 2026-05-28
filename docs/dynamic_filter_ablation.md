# Dynamic Filter Ablation

This experiment compares the same WildGS-SLAM code and the same data with:

- `mapping.dynamic_filter.activate: True`
- `mapping.dynamic_filter.activate: False`

The original config files are not modified. The runner generates temporary
configs under:

```text
output/generated_configs/dynamic_filter_on/
output/generated_configs/dynamic_filter_off/
```

Results are saved separately:

```text
output/dynamic_filter_on/
output/dynamic_filter_off/
```

## Run

Run all dynamic sequences with both settings:

```bash
bash run_dynamic_filter_ablation.sh --resume
```

Run only Bonn:

```bash
bash run_dynamic_filter_ablation.sh --suite bonn --resume
```

Run only one side of the comparison:

```bash
bash run_dynamic_filter_ablation.sh --mode on --resume
bash run_dynamic_filter_ablation.sh --mode off --resume
```

Preview without running:

```bash
bash run_dynamic_filter_ablation.sh --dry-run
```

After finishing, pose summaries are written by:

```bash
python scripts_run/summarize_pose_eval.py
```

The summary CSV files will appear under `output/`, including:

```text
output/dynamic_filter_on_eval.csv
output/dynamic_filter_off_eval.csv
```
