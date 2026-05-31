import argparse
import ast
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional

import numpy as np
import pandas as pd


METRIC_FILES = {
    "full": "metrics_full_traj.txt",
    "kf": "metrics_kf_traj.txt",
}

STAT_KEYS = ("rmse", "mean", "median", "std", "min", "max")
FLOAT_PATTERN = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"


@dataclass
class MetricRecord:
    output_name: str
    scene: str
    metric_type: str
    metrics_path: Path
    stats: Dict[str, float]

    @property
    def rmse_m(self) -> float:
        return self.stats["rmse"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Summarize WildGS-SLAM pose metrics and generate explicit dynamic "
            "filter ON/OFF comparisons."
        )
    )
    parser.add_argument(
        "--root",
        default="./output",
        help="Output root that contains method folders. Default: ./output",
    )
    parser.add_argument(
        "--metric",
        choices=["auto", "full", "kf"],
        default="auto",
        help=(
            "Metric file to summarize. auto prefers full trajectory and falls "
            "back to keyframe trajectory when full metrics are missing."
        ),
    )
    parser.add_argument(
        "--comparison-output",
        default="dynamic_filter_comparison_eval.csv",
        help="CSV filename for dynamic-filter comparison rows.",
    )
    return parser.parse_args()


def metric_order(metric: str) -> List[str]:
    if metric == "full":
        return ["full"]
    if metric == "kf":
        return ["kf"]
    return ["full", "kf"]


def try_float(value) -> Optional[float]:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def parse_metrics_file(path: Path) -> Dict[str, float]:
    text = path.read_text(encoding="utf-8", errors="replace")
    stats: Dict[str, float] = {}

    match = re.search(r"statistics:\s*(\{.*?\})\s*$", text, re.S)
    if match:
        payload = match.group(1).strip()
        try:
            parsed = ast.literal_eval(payload)
            if isinstance(parsed, dict):
                for key in STAT_KEYS:
                    value = try_float(parsed.get(key))
                    if value is not None:
                        stats[key] = value
        except (SyntaxError, ValueError):
            pass

    if "rmse" not in stats:
        for key in STAT_KEYS:
            value_match = re.search(
                rf"['\"]{key}['\"]\s*:\s*(?:np\.float64\()?({FLOAT_PATTERN})",
                text,
            )
            if value_match:
                stats[key] = float(value_match.group(1))

    if "rmse" not in stats:
        raise ValueError(f"Could not parse rmse from {path}")

    return stats


def find_experiment_dirs(output_path: Path) -> Iterable[Path]:
    for traj_dir in output_path.rglob("traj"):
        if not traj_dir.is_dir():
            continue
        if any((traj_dir / filename).exists() for filename in METRIC_FILES.values()):
            yield traj_dir.parent


def read_record(
    output_name: str,
    output_path: Path,
    experiment_dir: Path,
    metric: str,
) -> Optional[MetricRecord]:
    for metric_type in metric_order(metric):
        metrics_path = experiment_dir / "traj" / METRIC_FILES[metric_type]
        if not metrics_path.exists():
            continue

        scene = "/".join(experiment_dir.relative_to(output_path).parts)
        return MetricRecord(
            output_name=output_name,
            scene=scene,
            metric_type=metric_type,
            metrics_path=metrics_path,
            stats=parse_metrics_file(metrics_path),
        )

    return None


def collect_records(root: Path, metric: str) -> Dict[str, List[MetricRecord]]:
    records_by_output: Dict[str, List[MetricRecord]] = {}
    for output_path in sorted(path for path in root.iterdir() if path.is_dir()):
        if output_path.name == "logs":
            continue

        records: List[MetricRecord] = []
        seen = set()
        for experiment_dir in sorted(find_experiment_dirs(output_path)):
            if experiment_dir in seen:
                continue
            seen.add(experiment_dir)
            record = read_record(output_path.name, output_path, experiment_dir, metric)
            if record is not None:
                records.append(record)

        if records:
            records_by_output[output_path.name] = records

    return records_by_output


def cm(value_m: float) -> float:
    return value_m * 100.0


def format_cm(value_m: float) -> str:
    return f"{cm(value_m):.2f}"


def write_method_summaries(
    root: Path,
    records_by_output: Dict[str, List[MetricRecord]],
) -> List[Path]:
    written_paths: List[Path] = []
    long_rows = []

    for output_name, records in sorted(records_by_output.items()):
        records_by_scene = {record.scene: record for record in records}
        scenes = sorted(records_by_scene)
        rmses = [record.rmse_m for record in records]

        data = {
            scene: [format_cm(records_by_scene[scene].rmse_m)]
            for scene in scenes
        }
        data["Average"] = [format_cm(float(np.mean(rmses)))]

        df = pd.DataFrame(data, index=[output_name])
        csv_path = root / f"{output_name}_eval.csv"
        df.to_csv(csv_path)
        written_paths.append(csv_path)

        for record in records:
            row = {
                "output": record.output_name,
                "scene": record.scene,
                "metric_type": record.metric_type,
                "rmse_m": record.rmse_m,
                "rmse_cm": cm(record.rmse_m),
                "metrics_path": str(record.metrics_path),
            }
            for key in STAT_KEYS:
                if key in record.stats:
                    row[f"{key}_cm"] = cm(record.stats[key])
            long_rows.append(row)

    if long_rows:
        long_path = root / "pose_eval_long.csv"
        pd.DataFrame(long_rows).sort_values(["output", "scene"]).to_csv(
            long_path, index=False
        )
        written_paths.append(long_path)

    return written_paths


def winner_label(method: str, baseline: str, method_rmse: float, baseline_rmse: float) -> str:
    if abs(method_rmse - baseline_rmse) <= 1e-9:
        return "tie"
    return method if method_rmse < baseline_rmse else baseline


def build_comparison_rows(
    records_by_output: Dict[str, List[MetricRecord]],
) -> List[dict]:
    baseline_name = "dynamic_filter_off"
    if baseline_name not in records_by_output:
        return []

    baseline_records = {
        record.scene: record for record in records_by_output[baseline_name]
    }
    method_names = [
        name
        for name in records_by_output
        if name.startswith("dynamic_filter_") and name != baseline_name
    ]
    method_names.sort(key=lambda name: (name != "dynamic_filter_on", name))

    rows = []
    for method_name in method_names:
        method_records = {
            record.scene: record for record in records_by_output[method_name]
        }
        shared_scenes = sorted(set(baseline_records) & set(method_records))
        if not shared_scenes:
            continue

        method_values = []
        baseline_values = []
        metric_types = []
        for scene in shared_scenes:
            baseline_record = baseline_records[scene]
            method_record = method_records[scene]
            baseline_rmse = baseline_record.rmse_m
            method_rmse = method_record.rmse_m
            improvement_percent = (
                (baseline_rmse - method_rmse) / baseline_rmse * 100.0
                if baseline_rmse > 0
                else np.nan
            )
            metric_type = (
                method_record.metric_type
                if method_record.metric_type == baseline_record.metric_type
                else f"{method_record.metric_type}/{baseline_record.metric_type}"
            )

            rows.append(
                {
                    "comparison": f"{method_name} vs {baseline_name}",
                    "method": method_name,
                    "baseline": baseline_name,
                    "scene": scene,
                    "metric_type": metric_type,
                    "baseline_rmse_cm": cm(baseline_rmse),
                    "method_rmse_cm": cm(method_rmse),
                    "delta_method_minus_baseline_cm": cm(method_rmse - baseline_rmse),
                    "improvement_percent": improvement_percent,
                    "winner": winner_label(
                        method_name, baseline_name, method_rmse, baseline_rmse
                    ),
                    "baseline_metrics_path": str(baseline_record.metrics_path),
                    "method_metrics_path": str(method_record.metrics_path),
                }
            )
            baseline_values.append(baseline_rmse)
            method_values.append(method_rmse)
            metric_types.append(metric_type)

        baseline_avg = float(np.mean(baseline_values))
        method_avg = float(np.mean(method_values))
        avg_metric_type = metric_types[0] if len(set(metric_types)) == 1 else "mixed"
        rows.append(
            {
                "comparison": f"{method_name} vs {baseline_name}",
                "method": method_name,
                "baseline": baseline_name,
                "scene": "Average",
                "metric_type": avg_metric_type,
                "baseline_rmse_cm": cm(baseline_avg),
                "method_rmse_cm": cm(method_avg),
                "delta_method_minus_baseline_cm": cm(method_avg - baseline_avg),
                "improvement_percent": (
                    (baseline_avg - method_avg) / baseline_avg * 100.0
                    if baseline_avg > 0
                    else np.nan
                ),
                "winner": winner_label(
                    method_name, baseline_name, method_avg, baseline_avg
                ),
                "baseline_metrics_path": "",
                "method_metrics_path": "",
            }
        )

    return rows


def write_comparison(
    root: Path,
    records_by_output: Dict[str, List[MetricRecord]],
    filename: str,
) -> Optional[Path]:
    rows = build_comparison_rows(records_by_output)
    if not rows:
        return None

    df = pd.DataFrame(rows)
    csv_path = root / filename
    df.to_csv(csv_path, index=False)
    return csv_path


def summarize_dynamic_filter_stats(root: Path) -> Optional[Path]:
    rows = []
    for stats_path in sorted(root.rglob("dynamic_filter_stats.csv")):
        try:
            df = pd.read_csv(stats_path)
        except pd.errors.EmptyDataError:
            continue

        if df.empty:
            continue

        try:
            output_name = stats_path.relative_to(root).parts[0]
            scene = "/".join(stats_path.parent.relative_to(root / output_name).parts)
        except ValueError:
            output_name = stats_path.parts[-4] if len(stats_path.parts) >= 4 else ""
            scene = stats_path.parent.name

        row = {
            "output": output_name,
            "scene": scene,
            "rows": len(df),
        }
        if "mode" in df:
            row["mode"] = ",".join(sorted(str(v) for v in df["mode"].dropna().unique()))
        for column in (
            "reliability_mean",
            "dynamic_ratio",
            "dynamic_score_mean",
            "uncertainty_score_mean",
            "rgb_score_mean",
            "depth_score_mean",
        ):
            if column in df:
                row[f"{column}_mean"] = float(df[column].mean())
        rows.append(row)

    if not rows:
        return None

    csv_path = root / "dynamic_filter_stats_summary.csv"
    pd.DataFrame(rows).sort_values(["output", "scene"]).to_csv(csv_path, index=False)
    return csv_path


def print_written(paths: List[Path]) -> None:
    for path in paths:
        print(f"Results saved to {path}")


def print_comparison_table(comparison_path: Optional[Path]) -> None:
    if comparison_path is None or not comparison_path.exists():
        print(
            "No dynamic_filter_off baseline comparison was generated. "
            "Run both --dynamic-filter off and --dynamic-filter on first."
        )
        return

    df = pd.read_csv(comparison_path)
    if df.empty:
        return

    on_off = df[df["comparison"] == "dynamic_filter_on vs dynamic_filter_off"]
    view = on_off if not on_off.empty else df
    columns = [
        "comparison",
        "scene",
        "metric_type",
        "baseline_rmse_cm",
        "method_rmse_cm",
        "delta_method_minus_baseline_cm",
        "improvement_percent",
        "winner",
    ]
    view = view[columns].copy()
    for column in (
        "baseline_rmse_cm",
        "method_rmse_cm",
        "delta_method_minus_baseline_cm",
        "improvement_percent",
    ):
        view[column] = view[column].map(lambda value: f"{value:.4f}")

    print("\nDynamic filter comparison (lower ATE RMSE is better):")
    print(view.to_string(index=False))


def main() -> int:
    args = parse_args()
    root = Path(args.root)
    if not root.exists():
        print(f"No output root found: {root}")
        return 0

    records_by_output = collect_records(root, args.metric)
    if not records_by_output:
        print(f"No pose metrics found under {root}")
        return 0

    written_paths = write_method_summaries(root, records_by_output)
    comparison_path = write_comparison(
        root, records_by_output, args.comparison_output
    )
    if comparison_path is not None:
        written_paths.append(comparison_path)

    stats_summary_path = summarize_dynamic_filter_stats(root)
    if stats_summary_path is not None:
        written_paths.append(stats_summary_path)

    print_written(written_paths)
    print_comparison_table(comparison_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
