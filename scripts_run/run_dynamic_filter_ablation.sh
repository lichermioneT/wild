#!/usr/bin/env bash
set -uo pipefail

SUITE="all"
MODE="both"
RESUME=0
FAIL_FAST=0
DRY_RUN=0
SKIP_SUMMARY=0
PYTHON_BIN="${PYTHON:-python}"

usage() {
    cat <<'EOF'
Usage: bash scripts_run/run_dynamic_filter_ablation.sh [options]

Options:
  --suite all|bonn|tum|mocap   Experiment suite to run. Default: all
  --mode both|on|off           Run dynamic filter on, off, or both. Default: both
  --resume                     Skip experiments whose metrics_full_traj.txt exists
  --fail-fast                  Stop after the first failed experiment
  --dry-run                    Print selected experiments and generated configs, then exit
  --skip-summary               Do not run scripts_run/summarize_pose_eval.py
  --python PATH                Python executable to use. Default: python
  -h, --help                   Show this help
EOF
}

log_info() {
    printf '[dynamic-filter] %s\n' "$1"
}

log_warn() {
    printf '[dynamic-filter] WARNING: %s\n' "$1" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --suite)
            SUITE="${2:-}"
            shift 2
            ;;
        --mode)
            MODE="${2:-}"
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

case "$MODE" in
    both|on|off) ;;
    *)
        log_warn "--mode must be one of: both, on, off"
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
    local dataset_name="$2"
    local config_path="$3"
    local scene root_folder input_folder input_dir

    scene="$(resolve_config_value "$config_path" "scene")"
    root_folder="$(resolve_config_value "$config_path" "root_folder")"
    input_folder="$(resolve_config_value "$config_path" "input_folder")"

    if [[ -z "$scene" ]]; then
        log_warn "Config has no scene value: $config_path"
        exit 1
    fi

    input_folder="${input_folder/ROOT_FOLDER_PLACEHOLDER/$root_folder}"
    input_dir="$(make_abs_path "$input_folder")"

    EXP_SUITES+=("$suite_name")
    EXP_DATASETS+=("$dataset_name")
    EXP_CONFIGS+=("$config_path")
    EXP_SCENES+=("$scene")
    EXP_INPUTS+=("$input_dir")
}

make_generated_config() {
    local state="$1"
    local dataset_name="$2"
    local config_path="$3"
    local generated_path="$4"
    local activate_value="$5"
    local output_root="./output/dynamic_filter_${state}/${dataset_name}"

    mkdir -p "$(dirname -- "$generated_path")"
    cat > "$generated_path" <<EOF
inherit_from: ${REPO_ROOT}/${config_path}

mapping:
  dynamic_filter:
    activate: ${activate_value}

data:
  output: ${output_root}
EOF
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
EXP_DATASETS=()
EXP_CONFIGS=()
EXP_SCENES=()
EXP_INPUTS=()

if [[ "$SUITE" == "all" || "$SUITE" == "bonn" ]]; then
    for config in "${BONN_CONFIGS[@]}"; do
        add_experiment "bonn" "Bonn" "$config"
    done
fi

if [[ "$SUITE" == "all" || "$SUITE" == "tum" ]]; then
    for config in "${TUM_CONFIGS[@]}"; do
        add_experiment "tum" "TUM_RGBD" "$config"
    done
fi

if [[ "$SUITE" == "all" || "$SUITE" == "mocap" ]]; then
    for config in "${MOCAP_CONFIGS[@]}"; do
        add_experiment "mocap" "Wild_SLAM_Mocap" "$config"
    done
fi

if [[ "$MODE" == "both" ]]; then
    STATES=("on" "off")
else
    STATES=("$MODE")
fi

log_info "Selected ${#EXP_CONFIGS[@]} sequence(s), mode: $MODE"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '%-8s %-4s %-34s %s\n' "Suite" "Mode" "Scene" "Generated config"
    for state in "${STATES[@]}"; do
        for i in "${!EXP_CONFIGS[@]}"; do
            generated_config="output/generated_configs/dynamic_filter_${state}/${EXP_SUITES[$i]}/$(basename -- "${EXP_CONFIGS[$i]}")"
            printf '%-8s %-4s %-34s %s\n' "${EXP_SUITES[$i]}" "$state" "${EXP_SCENES[$i]}" "$generated_config"
        done
    done
    exit 0
fi

if [[ ! -f "$REPO_ROOT/pretrained/droid.pth" ]]; then
    log_warn "Missing pretrained/droid.pth. Download it first and put it in pretrained/."
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
total=$(( ${#EXP_CONFIGS[@]} * ${#STATES[@]} ))
count=0

for state in "${STATES[@]}"; do
    if [[ "$state" == "on" ]]; then
        activate_value="True"
    else
        activate_value="False"
    fi

    for i in "${!EXP_CONFIGS[@]}"; do
        count=$((count + 1))
        generated_config="output/generated_configs/dynamic_filter_${state}/${EXP_SUITES[$i]}/$(basename -- "${EXP_CONFIGS[$i]}")"
        output_dir="$(make_abs_path "output/dynamic_filter_${state}/${EXP_DATASETS[$i]}/${EXP_SCENES[$i]}")"
        metrics_path="$output_dir/traj/metrics_full_traj.txt"

        make_generated_config "$state" "${EXP_DATASETS[$i]}" "${EXP_CONFIGS[$i]}" "$generated_config" "$activate_value"

        if [[ "$RESUME" -eq 1 && -f "$metrics_path" ]]; then
            log_info "[$count/$total] Skip completed: dynamic_filter_${state}/${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
            continue
        fi

        timestamp="$(date +%Y%m%d_%H%M%S)"
        log_path="$REPO_ROOT/output/logs/${timestamp}_dynamic_filter_${state}_${EXP_SUITES[$i]}_${EXP_SCENES[$i]}.log"

        log_info "[$count/$total] Run dynamic_filter_${state}/${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
        log_info "Config: $generated_config"
        log_info "Log: $log_path"

        "$PYTHON_BIN" run.py "$generated_config" 2>&1 | tee "$log_path"
        status="${PIPESTATUS[0]}"

        if [[ "$status" -ne 0 ]]; then
            failed+=("dynamic_filter_${state}/${EXP_SUITES[$i]}/${EXP_SCENES[$i]}: ${EXP_CONFIGS[$i]}")
            log_warn "Failed: dynamic_filter_${state}/${EXP_SUITES[$i]}/${EXP_SCENES[$i]}"
            if [[ "$FAIL_FAST" -eq 1 ]]; then
                break 2
            fi
        fi
    done
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

log_info "Dynamic filter ablation finished."
