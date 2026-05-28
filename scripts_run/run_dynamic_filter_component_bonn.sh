#!/usr/bin/env bash
set -e

# Uncertainty cue only
python run.py ./configs/Dynamic/Bonn/bonn_balloon.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_balloon2.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd2.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box2.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking2.yaml --dynamic-filter-ablation uncertainty_only --output-root ./output/dynamic_filter_uncertainty_only/Bonn

# Photometric/depth residual cues only
python run.py ./configs/Dynamic/Bonn/bonn_balloon.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_balloon2.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd2.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box2.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking2.yaml --dynamic-filter-ablation residual_only --output-root ./output/dynamic_filter_residual_only/Bonn

# Full cues without temporal EMA
python run.py ./configs/Dynamic/Bonn/bonn_balloon.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_balloon2.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd2.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box2.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking2.yaml --dynamic-filter-ablation no_temporal --output-root ./output/dynamic_filter_no_temporal/Bonn

python scripts_run/summarize_pose_eval.py
