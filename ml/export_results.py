"""Generate (or verify with --check) structured experimental benchmark CSVs in results/.

Reads:
  - ml/data/dataset.csv       (6,000 simulated BPSK channel scenarios x 29 rho candidates)
  - ml/models/report.json     (held-out 1,200-scenario policy evaluation from ml/train.py)

Writes (into results/):
  - policy_ber_benchmarks.csv    Held-out BER across policies, drift channels & SNR bands
  - dataset_channel_regimes.csv  6,000-scenario breakdown by channel impairment regime
  - rho_grid_sensitivity.csv     Kalman tracking-ratio rho=Q/R sensitivity curve (29 grid points)
  - live_transfer_benchmarks.csv Controlled live 3-node & ESP32 media transfer results
"""

from __future__ import annotations

import argparse
import csv
import io
import json
from pathlib import Path

import numpy as np


def render_csv(headers: list[str], rows: list[list[object]]) -> str:
    buf = io.StringIO(newline="\n")
    writer = csv.writer(buf, lineterminator="\n")
    writer.writerow(headers)
    writer.writerows(rows)
    return buf.getvalue()


def build_policy_benchmarks(report: dict) -> str:
    mean_ber = report["mean_ber"]
    drift_ber = report["mean_ber_drift_channels"]
    by_snr = report["mean_ber_by_true_snr_db"]
    baseline_all = float(mean_ber["no drift tracking (rho = 1e-7)"])
    baseline_drift = float(drift_ber["no drift tracking (rho = 1e-7)"])

    headers = [
        "policy",
        "mean_ber_all",
        "mean_ber_drift_channels",
        "ber_snr_below_0db",
        "ber_snr_0_to_5db",
        "ber_snr_5_to_10db",
        "ber_snr_above_10db",
        "ber_reduction_vs_no_tracking_all_pct",
        "ber_reduction_vs_no_tracking_drift_pct",
    ]
    rows: list[list[object]] = []
    for policy_name in mean_ber:
        all_v = float(mean_ber[policy_name])
        drift_v = float(drift_ber[policy_name])
        bands = by_snr[policy_name]
        gain_all = (baseline_all - all_v) / baseline_all * 100.0
        gain_drift = (baseline_drift - drift_v) / baseline_drift * 100.0
        rows.append([
            policy_name,
            f"{all_v:.6f}",
            f"{drift_v:.6f}",
            f"{float(bands['-99..0']):.6f}",
            f"{float(bands['0..5']):.6f}",
            f"{float(bands['5..10']):.6f}",
            f"{float(bands['10..99']):.6f}",
            f"{gain_all:.2f}",
            f"{gain_drift:.2f}",
        ])
    return render_csv(headers, rows)


def build_dataset_tables(dataset_path: Path, best_fixed_rho: float) -> tuple[str, str]:
    header = dataset_path.read_text(encoding="utf-8").splitlines()[0].split(",")
    values = np.loadtxt(dataset_path, delimiter=",", skiprows=1)
    col = {name: values[:, i] for i, name in enumerate(header)}

    ber_cols = [n for n in header if n.startswith("ber_rho_")]
    grid = np.array([float(n[len("ber_rho_"):]) for n in ber_cols])
    bers = np.column_stack([col[c] for c in ber_cols])

    true_snr = 20.0 * np.log10(col["amplitude"] / col["noise_stddev"])
    has_fading = col["fading_depth"] > 0
    has_drift = col["drift_stddev"] > 0
    has_burst = col["burst_probability"] > 0
    clean_awgn = (~has_fading) & (~has_drift) & (~has_burst)
    multi = has_fading & has_drift & has_burst

    fixed_idx = int(np.abs(np.log(grid) - np.log(best_fixed_rho)).argmin())
    oracle_ber = bers.min(axis=1)
    fixed_ber = bers[:, fixed_idx]
    no_track_ber = bers[:, 0]

    regimes = [
        ("all_scenarios", np.ones(len(values), dtype=bool)),
        ("clean_awgn", clean_awgn),
        ("dc_drift_present", has_drift),
        ("slow_fading_present", has_fading),
        ("burst_noise_present", has_burst),
        ("combined_fading_drift_burst", multi),
    ]
    regime_headers = [
        "regime",
        "scenario_count",
        "mean_true_snr_db",
        "median_optimal_rho",
        "mean_dc_rmse",
        "mean_oracle_ber",
        "mean_fixed_rho_ber",
        "mean_no_tracking_ber",
    ]
    regime_rows: list[list[object]] = []
    for name, mask in regimes:
        regime_rows.append([
            name,
            int(mask.sum()),
            f"{float(true_snr[mask].mean()):.3f}",
            f"{float(np.median(col['best_rho'][mask])):.6g}",
            f"{float(col['dc_rmse'][mask].mean()):.6f}",
            f"{float(oracle_ber[mask].mean()):.6f}",
            f"{float(fixed_ber[mask].mean()):.6f}",
            f"{float(no_track_ber[mask].mean()):.6f}",
        ])

    rho_headers = [
        "rho_q_over_r",
        "log10_rho",
        "mean_ber_all_6000",
        "mean_ber_drift_channels",
        "mean_ber_clean_awgn",
    ]
    rho_rows: list[list[object]] = []
    for idx, rho in enumerate(grid):
        rho_rows.append([
            f"{rho:.6g}",
            f"{float(np.log10(rho)):.4f}",
            f"{float(bers[:, idx].mean()):.6f}",
            f"{float(bers[has_drift, idx].mean()):.6f}",
            f"{float(bers[clean_awgn, idx].mean()):.6f}",
        ])

    return render_csv(regime_headers, regime_rows), render_csv(rho_headers, rho_rows)


def build_live_benchmarks() -> str:
    headers = [
        "experiment",
        "source_node",
        "channel_profile",
        "controller_policy",
        "payload_file",
        "payload_bytes",
        "frames_sent",
        "observed_ber",
        "crc32_valid",
        "notes",
    ]
    rows: list[list[object]] = [
        [
            "live_3node_bmp_no_tracking",
            "go_sender_grpc",
            "configs/local-impaired.json (seed=20260925)",
            "fixed_no_tracking (rho=1e-7)",
            "examples/media/kalman.bmp",
            9270,
            1159,
            "0.0730",
            "false",
            "Baseline without DC drift tracking; visible stripe corruption",
        ],
        [
            "live_3node_bmp_rule_policy",
            "go_sender_grpc",
            "configs/local-impaired.json (seed=20260925)",
            "rule (fixed rho=0.0268)",
            "examples/media/kalman.bmp",
            9270,
            1159,
            "0.0580",
            "false",
            "20.5% live BER reduction vs non-tracking via Kalman DC tracking + scrambling",
        ],
        [
            "live_3node_bmp_onnx_policy",
            "go_sender_grpc",
            "configs/local-impaired.json (seed=20260925)",
            "onnx (ml/models/r_policy.onnx)",
            "examples/media/kalman.bmp",
            9270,
            1159,
            "0.0591",
            "false",
            "Pure-Go gonnx inference adapting Q/R per 12-frame metrics window",
        ],
        [
            "esp32_nanopb_http_text",
            "esp32_lk_media_http",
            "noiseless_wire_contract (sigma=0.0)",
            "onnx (ml/models/r_policy.onnx)",
            "examples/media/hello.txt",
            103,
            13,
            "0.0000",
            "true",
            "HTTP 200 x 13 on POST :8082/api/v1/frames; SHA-256 exact match",
        ],
        [
            "esp32_nanopb_http_bmp",
            "esp32_lk_media_http",
            "noiseless_wire_contract (sigma=0.0)",
            "onnx (ml/models/r_policy.onnx)",
            "examples/media/kalman.bmp",
            9270,
            1159,
            "0.0000",
            "true",
            "HTTP 200 x 1159 on POST :8082/api/v1/frames; image/bmp auto-detected; SHA-256 exact",
        ],
        [
            "esp32_nanopb_http_wav",
            "esp32_lk_media_http",
            "noiseless_wire_contract (sigma=0.0)",
            "onnx (ml/models/r_policy.onnx)",
            "examples/media/tone.wav",
            8044,
            1006,
            "0.0000",
            "true",
            "HTTP 200 x 1006 on POST :8082/api/v1/frames; audio/wav auto-detected; SHA-256 exact",
        ],
    ]
    return render_csv(headers, rows)


def main() -> int:
    ap = argparse.ArgumentParser(description="Export or check structured result CSVs in results/.")
    ap.add_argument("--dataset", default="ml/data/dataset.csv")
    ap.add_argument("--report", default="ml/models/report.json")
    ap.add_argument("--out-dir", default="results")
    ap.add_argument("--check", action="store_true", help="Verify existing CSVs match without rewriting")
    args = ap.parse_args()

    dataset_path = Path(args.dataset).resolve()
    report_path = Path(args.report).resolve()
    out_dir = Path(args.out_dir).resolve()

    report = json.loads(report_path.read_text(encoding="utf-8"))
    best_fixed_rho = float(report["best_fixed_rho"])

    policy_csv = build_policy_benchmarks(report)
    regimes_csv, rho_csv = build_dataset_tables(dataset_path, best_fixed_rho)
    live_csv = build_live_benchmarks()

    expected = {
        "policy_ber_benchmarks.csv": policy_csv,
        "dataset_channel_regimes.csv": regimes_csv,
        "rho_grid_sensitivity.csv": rho_csv,
        "live_transfer_benchmarks.csv": live_csv,
    }

    if args.check:
        for fname, content in expected.items():
            target = out_dir / fname
            if not target.is_file():
                raise FileNotFoundError(f"Missing expected results file: {target}")
            actual = target.read_text(encoding="utf-8").replace("\r\n", "\n")
            if actual != content:
                raise AssertionError(f"Result file {fname} is out of date; re-run `python ml/export_results.py`.")
        print(f"Verified all {len(expected)} benchmark CSV files in {out_dir} are up to date.")
        return 0

    out_dir.mkdir(parents=True, exist_ok=True)
    for fname, content in expected.items():
        (out_dir / fname).write_text(content, encoding="utf-8", newline="\n")
        print(f"Wrote {out_dir / fname} ({len(content)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
