# Temporally Calibrated Dynamic Reliability

This fork adds a lightweight dynamic reliability filter for WildGS-SLAM.

## Motivation

The original uncertainty-aware mapping is mainly frame-local. In highly dynamic
monocular videos, short-lived residuals from moving foreground objects can still
contribute gradients to the static Gaussian map, especially near object
boundaries and during partial occlusion.

## Method

For each keyframe, the mapper fuses three dynamic cues:

- learned semantic uncertainty from the existing DINO-based uncertainty MLP,
- photometric residual between rendered and observed RGB,
- foreground depth conflict where the observed metric depth is closer than the
  rendered static map.

The fused dynamic score is converted into a static reliability weight. Each
keyframe keeps an exponential moving average of this weight, making the mask
temporally stable across mapping iterations. The RGB and depth mapping losses
are then down-weighted in low-reliability regions.

## Configuration

The method is controlled by `mapping.dynamic_filter` in
`configs/wildgs_slam.yaml`.

Set `mapping.dynamic_filter.activate: False` for an ablation that recovers the
original uncertainty-aware mapping behavior.

## Suggested Ablations

- `dynamic_filter=False`: original WildGS-SLAM-style uncertainty mapping.
- uncertainty-only: set `rgb_gain=0`, `depth_gain=0`.
- residual-only: set `uncertainty_gain=0`.
- no temporal smoothing: set `ema=0`.

Useful metrics are ATE/RPE for tracking robustness, NVS PSNR/SSIM/LPIPS on
static regions, and qualitative dynamic-object removal in the final Gaussian
map.
