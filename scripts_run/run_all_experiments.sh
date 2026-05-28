#!/usr/bin/env bash
set -uo pipefail

SUITE="all"
RESUME=0
FAIL_FAST=0
DRY_RUN=0
SKIP_SUMMARY=0
PYTHON_BIN="${PYTHON:-python}"

usage() {
    cat <<'EOF'
Usage: bash scripts_run/run_all_experiments.sh [options]

Options:
  --suite all|bonn|tum|mocap   Experiment suite to run. Default: all
  --resume                     Skip experiments whose metrics_full_traj.txt exists
  --fail-fast                  Stop after the first failed experiment
  --dry-run                    Print selected experiments and exit
  --skip-summary               Do not run scripts_run/summarize_pose_eval.py
  --python PATH                Python executable to use. Default: python
  -h, --help                   Show this help
EOF
}

log_info() {
    printf '[wildgs] %s\n' "$1"
}

log_warn() {
    printf '[wildgs] WARNING: %s\n' "$1" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --suite)
            SUITE="${2:-}"
            shift 2
            ;;
        --resume)
            RESUME=1
            shift
            ;;
        --fail-fast)
            FAIL_FAST=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --skip-summary)
            SKIP_SUMMARY=1
            shift
            ;;
        --python)
            PYTHON_BIN="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_warn "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

case "$SUITE" in
    all|bonn|tum|mocap) ;;
    *)
        log_warn "--suite must be one of: all, bonn, tum, mocap"
        exit 2
        ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    log_warn "Cannot find Python executable: $PYTHON_BIN"
    exit 1
fi

resolve_config_value() {
    local config_path="$1"
    local key="$2"
    local full_path="$REPO_ROOT/$config_path"

    if [[ ! -f "$full_path" ]]; then
        log_warn "Missing config: $config_path"
        return 1
    fi

    local value
    value="$(awk -F ':' -v key="$key" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            sub(/^[[:space:]]+/, "", $2)
            sub(/[[:space:]]+$/, "", $2)
            gsub(/^["'\'']|["'\'']$/, "", $2)
            print $2
            exit
        }
    ' "$full_path")"

    if [[ -n "$value" ]]; then
        printf '%s\n' "$value"
        return 0
    fi

    local parent
    parent="$(awk -F ':' '
        $1 ~ /^[[:space:]]*inherit_from[[:space:]]*$/ {
            sub(/^[[:space:]]+/, "", $2)
            sub(/[[:space:]]+$/, "", $2)
            gsub(/^["'\'']|["'\'']$/, "", $2)
            print $2
            exit
        }
    ' "$full_path")"

    if [[ -n "$parent" ]]; then
        resolve_config_value "$parent" "$key"
    fi
}

make_abs_path() {
    local path="$1"
    "$PYTHON_BIN" - "$REPO_ROOT" "$path" <<'PY'
import os
import sys
print(os.path.abspath(os.path.join(sys.argv[1], sys.argv[2])))
PY
}

add_experiment() {
    local suite_name="$1"
    local config_path="$2"
    local scene output_root root_folder input_folder output_dir input_dir

    scene="$(resolve_config_value "$config_path" "scene")"
    output_root="$(resolve_config_value "$config_path" "output")"
    root_folder="$(resolve_config_value "$config_path" "root_folder")"
    input_folder="$(resolve_config_value "$config_path" "input_folder")"

    if [[ -z "$scene" ]]; then
        log_warn "Config has no scene value: $config_path"
        exit 1
    fi

    input_folder="${input_folder/ROOT_FOLDER_PLACEHOLDER/$root_folder}"
    output_dir="$(make_abs_path "$output_root/$scene")"
    input_dir="$(make_abs_path "$input_folder")"

    EXP_SUITES+=("$suite_name")
    EXP_CONFIGS+=("$config_path")
    EXP_SCENES+=("$scene")
    EXP_OUTPUTS+=("$output_dir")
    EXP_INPUTS+=("$input_dir")
}

BONN_CONFIGS=(
    "configs/Dynamic/Bonn/bonn_balloon.yaml"
    "configs/Dynamic/Bonn/bonn_balloon2.yaml"
    "configs/Dynamic/Bonn/bonn_crowd.yaml"
    "configs/Dynamic/Bonn/bonn_crowd2.yaml"
    "configs/Dynamic/Bonn/bonn_moving_nonobstructing_box.yaml"
    "configs/Dynamic/Bonn/bonn_moving_nonobstructing_box2.yaml"
    "configs/Dynamic/Bonn/bonn_person_tracking.yaml"
    "configs/Dynamic/Bonn/bonn_person_tracking2.yaml"
)

TUM_CONFIGS=(
    "configs/Dynamic/TUM_RGBD/freiburg2_desk_with_person.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_sitting_halfsphere_static.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_sitting_halfsphere.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_sitting_rpy.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_sitting_xyz.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_walking_halfsphere_static.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_walking_halfsphere.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_walking_rpy.yaml"
    "configs/Dynamic/TUM_RGBD/freiburg3_walking_xyz.yaml"
)

MOCAP_CONFIGS=(
    "configs/Dynamic/Wild_SLAM_Mocap/ball.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/crowd.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/person_tracking.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/racket.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/stones.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/table_tracking1.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/table_tracking2.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/umbrella.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/ANYmal1.yaml"
    "configs/Dynamic/Wild_SLAM_Mocap/ANYmal2.yaml"
)

EXP_SUITES=()
EXP_CONFIGS=()
EXP_SCENES=()
EXP_OUTPUTS=()
EXP_INPUTS=()

if [[ "$SUITE" == "all" || "$SUITE" == "bonn" ]]; then
    for config in "${BONN_CONFIGS[@]}"; do
        add_experiment "bonn" "$config"
    done
fi

if [[ "$SUITE" == "all" || "$SUITE" == "tum" ]]; then
    for config in "${TUM_CONFIGS[@]}"; do
        add_experiment "tum" "$config"
    done
fi

if [[ "$SUITE" == "all" || "$SUITE" == "mocap" ]]; then
    for config in "${MOCAP_CONFIGS[@]}"; do
        add_experiment "mocap" "$config"
    done
fi

log_info "Selected ${#EXP_CONFIGS[@]} experiment(s), suite: $SUITE"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '%-8s %-34s %s\n' "Suite" "Scene" "Config"
    for i in "${!EXP_CONFIGS[@]}"; do
        printf '%-8s %-34s %s\n' "${EXP_SUITES[$i]}" "${EXP_SCENES[$i]}" "${EXP_CONFIGS[$i]}"
    done
    exit 0
fi

if [[ ! -f "$REPO_ROOT/pretrained/droid.pth" ]]; then
    log_warn "Missing pretrained/droid.pth. Download it first and put it in pretrained/."
    exit 1
fi

if [[ -e "$REPO_ROOT/datasets" && ! -d "$REPO_ROOT/datasets" ]]; then
    log_warn "'datasets' exists but is not a directory. Replace it with a datasets directory."
    exit 1
fi

missing_inputs=()
for i in "${!EXP_INPUTS[@]}"; do
    if [[ ! -d "${EXP_INPUTS[$i]}" ]]; then
        missing_inputs+=("${EXP_SUITES[$i]}: ${EXP_SCENES[$i]} -> ${EXP_INPUTS[$i]}")
    fi
done

if [[ "${#missing_inputs[@]}" -gt 0 ]]; then
    log_warn "Some dataset folders are missing:"
    printf '  %s\n' "${missing_inputs[@]}" >&2
    log_warn "Put datasets under ./datasets or edit root_folder values in configs."
    exit 1
fi

mkdir -p "$REPO_ROOT/output/logs"

failed=()
total="${#EXP_CONFIGS[@]}"
for i in "${!EXP_CONFIGS[@]}"; do
    index=$((i + 1))
    metrics_path="${EXP_OUTPUTS[$i]}/traj/metrics_full_traj.txt"

    if [[ "$RESUME" -eq 1 && -f "$metrics_path" ]]; then
        log_info "[$index/$total] Skip completed: ${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
        continue
    fi

    timestamp="$(date +%Y%m%d_%H%M%S)"
    log_path="$REPO_ROOT/output/logs/${timestamp}_${EXP_SUITES[$i]}_${EXP_SCENES[$i]}.log"
    log_info "[$index/$total] Run ${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
    log_info "Log: $log_path"

    "$PYTHON_BIN" run.py "${EXP_CONFIGS[$i]}" 2>&1 | tee "$log_path"
    status="${PIPESTATUS[0]}"

    if [[ "$status" -ne 0 ]]; then
        failed+=("${EXP_SUITES[$i]}/${EXP_SCENES[$i]}: ${EXP_CONFIGS[$i]}")
        log_warn "Failed: ${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
        if [[ "$FAIL_FAST" -eq 1 ]]; then
            break
        fi
    fi
done

if [[ "$SKIP_SUMMARY" -eq 0 ]]; then
    log_info "Summarizing pose evaluation"
    "$PYTHON_BIN" scripts_run/summarize_pose_eval.py
fi

if [[ "${#failed[@]}" -gt 0 ]]; then
    log_warn "${#failed[@]} experiment(s) failed:"
    printf '  %s\n' "${failed[@]}" >&2
    exit 1
fi

log_info "All selected experiments finished."
