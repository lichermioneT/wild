import os

import numpy as np
import pandas as pd


def read_rmse(exp_folder):
    result_file = os.path.join(exp_folder, "traj/metrics_full_traj.txt")
    if not os.path.exists(result_file):
        return None

    with open(result_file, "r") as f:
        output = f.readlines()

    return float(output[8].split(",")[0].replace("{'rmse': ", ""))


def summarize_flat_output(output_name, output_path, row_name):
    scenes = [
        scene
        for scene in sorted(os.listdir(output_path))
        if os.path.isdir(os.path.join(output_path, scene))
    ]
    if not scenes:
        return

    data = {scene: [] for scene in scenes}
    row_data = []
    rmses = []

    for scene in scenes:
        rmse = read_rmse(os.path.join(output_path, scene))
        if rmse is None:
            row_data.append("N/A")
        else:
            row_data.append(f"{rmse * 1e2:.2f}")
            rmses.append(rmse)

    average = f"{np.nanmean(rmses) * 1e2:.2f}" if rmses else "N/A"
    for scene, value in zip(scenes, row_data):
        data[scene].append(value)
    data["Average"] = [average]

    df = pd.DataFrame(data, index=[row_name])
    csv_path = f"./output/{output_name}_eval.csv"
    df.to_csv(csv_path)
    print(f"Results saved to {csv_path}")


def summarize_nested_output(output_name, output_path):
    rows = {}
    all_scenes = []

    for dataset in sorted(os.listdir(output_path)):
        dataset_path = os.path.join(output_path, dataset)
        if not os.path.isdir(dataset_path):
            continue

        for scene in sorted(os.listdir(dataset_path)):
            exp_folder = os.path.join(dataset_path, scene)
            if not os.path.isdir(exp_folder):
                continue

            scene_key = f"{dataset}/{scene}"
            all_scenes.append(scene_key)
            rmse = read_rmse(exp_folder)
            rows[scene_key] = "N/A" if rmse is None else f"{rmse * 1e2:.2f}"

    if not rows:
        return

    ordered_scenes = sorted(set(all_scenes))
    valid_rmses = [float(rows[scene]) / 1e2 for scene in ordered_scenes if rows[scene] != "N/A"]
    average = f"{np.nanmean(valid_rmses) * 1e2:.2f}" if valid_rmses else "N/A"

    data = {scene: [rows.get(scene, "N/A")] for scene in ordered_scenes}
    data["Average"] = [average]

    df = pd.DataFrame(data, index=[output_name])
    csv_path = f"./output/{output_name}_eval.csv"
    df.to_csv(csv_path)
    print(f"Results saved to {csv_path}")


outputs = os.listdir("./output")
for output_name in outputs:
    output_path = os.path.join("output", output_name)
    if not os.path.isdir(output_path):
        continue

    direct_metrics = [
        os.path.exists(os.path.join(output_path, scene, "traj/metrics_full_traj.txt"))
        for scene in os.listdir(output_path)
        if os.path.isdir(os.path.join(output_path, scene))
    ]

    if any(direct_metrics):
        summarize_flat_output(output_name, output_path, "wildgs-slam")
    else:
        summarize_nested_output(output_name, output_path)
        
