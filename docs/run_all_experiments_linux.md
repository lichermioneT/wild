# Run All Experiments on Linux

Put the datasets and pretrained checkpoint in the default folders:

```text
datasets/
  Bonn/
  TUM_RGBD/
  Wild_SLAM_Mocap/
pretrained/
  droid.pth
```

Then activate the WildGS-SLAM conda environment and run:

```bash
bash run_all_experiments.sh --resume
```

This runs all configured dynamic experiments:

- 8 Bonn Dynamic sequences
- 9 TUM RGB-D dynamic sequences
- 10 Wild-SLAM Mocap sequences

Useful options:

```bash
bash run_all_experiments.sh --suite bonn --resume
bash run_all_experiments.sh --suite tum --resume
bash run_all_experiments.sh --suite mocap --resume
bash run_all_experiments.sh --dry-run
bash run_all_experiments.sh --fail-fast
bash run_all_experiments.sh --skip-summary
```

Logs are saved under `output/logs/`. Pose summaries are written by
`scripts_run/summarize_pose_eval.py` to CSV files under `output/`.

If Python is not named `python` in your shell, pass it explicitly:

```bash
bash run_all_experiments.sh --python /path/to/python --resume
```

## Run Another Codebase on the Same Data

The same runner can call a different method/codebase for every sequence. Use
`--method` to name the method and `--command-template` to provide the command.

Available placeholders:

```text
{python}             Python executable passed by --python
{method}             Method name passed by --method
{suite}              bonn, tum, or mocap
{scene}              Scene name
{config}             WildGS-SLAM config path for this sequence
{input_dir}          Resolved dataset folder for this sequence
{output_dir}         Original WildGS-SLAM output folder
{method_output_dir}  Suggested separate output folder: output/{method}/{suite}/{scene}
```

Example: run another repo that accepts `--input` and `--output`:

```bash
bash run_all_experiments.sh \
  --method my_baseline \
  --command-template 'cd ../my_baseline && python run.py --input "{input_dir}" --output "{method_output_dir}" --scene "{scene}"' \
  --expected-metrics '{method_output_dir}/traj/metrics_full_traj.txt' \
  --resume \
  --skip-summary
```

Example: run another entry file in this repo on the same WildGS-SLAM configs:

```bash
bash run_all_experiments.sh \
  --method ablation_v2 \
  --command-template '{python} run_ablation_v2.py "{config}"' \
  --resume
```

For comparison experiments, keep each method's output separate under
`output/{method}/{suite}/{scene}` whenever the other code supports an output
argument. If the other code writes to a fixed location, set `--expected-metrics`
to match that location so `--resume` can skip completed scenes.

You can also make the entry script executable:

```bash
chmod +x run_all_experiments.sh scripts_run/run_all_experiments.sh
./run_all_experiments.sh --resume
```
