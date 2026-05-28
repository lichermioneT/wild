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

You can also make the entry script executable:

```bash
chmod +x run_all_experiments.sh scripts_run/run_all_experiments.sh
./run_all_experiments.sh --resume
```
