#!/usr/bin/env bash
set -e

python run.py ./configs/Dynamic/Bonn/bonn_balloon.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_balloon2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_crowd2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_moving_nonobstructing_box2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn
python run.py ./configs/Dynamic/Bonn/bonn_person_tracking2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Bonn

python run.py ./configs/Dynamic/TUM_RGBD/freiburg2_desk_with_person.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_sitting_halfsphere_static.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_sitting_halfsphere.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_sitting_rpy.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_sitting_xyz.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_walking_halfsphere_static.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_walking_halfsphere.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_walking_rpy.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD
python run.py ./configs/Dynamic/TUM_RGBD/freiburg3_walking_xyz.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/TUM_RGBD

python run.py ./configs/Dynamic/Wild_SLAM_Mocap/ball.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/crowd.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/person_tracking.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/racket.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/stones.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/table_tracking1.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/table_tracking2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/umbrella.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/ANYmal1.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap
python run.py ./configs/Dynamic/Wild_SLAM_Mocap/ANYmal2.yaml --dynamic-filter on --output-root ./output/dynamic_filter_on/Wild_SLAM_Mocap

python scripts_run/summarize_pose_eval.py
