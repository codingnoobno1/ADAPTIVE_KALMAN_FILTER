"""Train the Controller's Kalman tracking-ratio policy; export a gonnx-compatible ONNX model.

The Receiver's Kalman filter tracks the channel's DC drift, and only the ratio
rho = Q/R sets how fast it follows. The model predicts log(rho) from the
Controller's metrics window; the Controller sends R = noise variance (clamped)
and Q = rho * R.

Input:  ml/data/dataset.csv produced by `go run ./cmd/datagen` (the same DSP
        and signal synthesis the live Sender/Receiver use).
Output: ml/models/r_policy.onnx      opset 13, ops: Sub, Mul, Gemm, Relu only
        ml/models/r_policy.golden.json  features -> expected log_rho, for the Go test
        ml/models/report.json        held-out evaluation (BER, not just regression error)

The ONNX graph is written by hand from the trained weights rather than with
skl2onnx, because gonnx implements only opset 13 and a fixed operator list;
skl2onnx can emit ops (Identity, Cast, ai.onnx.ml Scaler) gonnx does not run.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper
from sklearn.neural_network import MLPRegressor
from sklearn.preprocessing import StandardScaler

FEATURES = ["snr_db_mean", "snr_db_std", "noise_var_mean", "noise_var_std", "frame_mean_std", "frame_mean_step"]
SEED = 20260927


def load(path: Path):
    # Read the header ourselves: genfromtxt(names=True) strips "." from column
    # names, which would corrupt the R values encoded in "ber_r_<R>".
    header = path.read_text().splitlines()[0].split(",")
    values = np.loadtxt(path, delimiter=",", skiprows=1)
    col = {name: values[:, i] for i, name in enumerate(header)}
    ber_cols = [n for n in header if n.startswith("ber_rho_")]
    grid = np.array([float(n[len("ber_rho_"):]) for n in ber_cols])
    x = np.column_stack([col[f] for f in FEATURES]).astype(np.float32)
    y = np.log(col["best_rho"]).astype(np.float32)
    bers = np.column_stack([col[c] for c in ber_cols])
    true_snr = 20 * np.log10(col["amplitude"] / col["noise_stddev"])
    drift = col["drift_stddev"] > 0
    return x, y, bers, grid, true_snr, drift


def ber_at(r_values: np.ndarray, grid: np.ndarray, bers: np.ndarray) -> np.ndarray:
    """BER each row would get with the given rho (nearest grid point in log space)."""
    idx = np.abs(np.log(r_values)[:, None] - np.log(grid)[None, :]).argmin(axis=1)
    return bers[np.arange(len(bers)), idx]


def export_onnx(scaler: StandardScaler, mlp: MLPRegressor, path: Path) -> None:
    init = [
        numpy_helper.from_array(scaler.mean_.astype(np.float32), "scaler_mean"),
        numpy_helper.from_array((1.0 / scaler.scale_).astype(np.float32), "scaler_inv_scale"),
    ]
    nodes = [
        helper.make_node("Sub", ["features", "scaler_mean"], ["centered"]),
        helper.make_node("Mul", ["centered", "scaler_inv_scale"], ["h0"]),
    ]
    last = len(mlp.coefs_) - 1
    for i, (w, b) in enumerate(zip(mlp.coefs_, mlp.intercepts_)):
        init += [numpy_helper.from_array(w.astype(np.float32), f"W{i}"), numpy_helper.from_array(b.astype(np.float32), f"b{i}")]
        out = "log_rho" if i == last else f"z{i + 1}"
        nodes.append(helper.make_node("Gemm", [f"h{i}", f"W{i}", f"b{i}"], [out]))
        if i != last:
            nodes.append(helper.make_node("Relu", [out], [f"h{i + 1}"]))
    graph = helper.make_graph(
        nodes,
        "kalman_rho_policy",
        [helper.make_tensor_value_info("features", TensorProto.FLOAT, [1, len(FEATURES)])],
        [helper.make_tensor_value_info("log_rho", TensorProto.FLOAT, [1, 1])],
        init,
    )
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 13)], producer_name="streaming-live-kalman/ml/train.py")
    model.ir_version = 8
    model.doc_string = "features=[" + ",".join(FEATURES) + "] (raw, scaling is in-graph) -> log_rho; Q/R = exp(log_rho)"
    onnx.checker.check_model(model)
    path.parent.mkdir(parents=True, exist_ok=True)
    onnx.save(model, path)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default="ml/data/dataset.csv")
    ap.add_argument("--out", default="ml/models")
    args = ap.parse_args()
    out = Path(args.out)

    x, y, bers, grid, true_snr, drift = load(Path(args.data))
    rng = np.random.default_rng(SEED)
    order = rng.permutation(len(x))
    n_test = len(x) // 5
    test, train = order[:n_test], order[n_test:]

    scaler = StandardScaler().fit(x[train])
    mlp = MLPRegressor(hidden_layer_sizes=(16, 16), activation="relu", alpha=1e-4, learning_rate_init=3e-3,
                       max_iter=3000, early_stopping=True, validation_fraction=0.15, n_iter_no_change=50, random_state=SEED)
    mlp.fit(scaler.transform(x[train]), y[train])

    pred_log_r = mlp.predict(scaler.transform(x[test])).astype(np.float32)
    lo, hi = grid.min(), grid.max()
    pred_r = np.clip(np.exp(pred_log_r), lo, hi)
    best_fixed = float(grid[bers[train].mean(axis=0).argmin()])  # chosen on training data only
    policies = {
        "oracle (best rho per channel)": np.exp(y[test]),
        "onnx MLP": pred_r,
        f"best fixed rho = {best_fixed:.3g}": np.full(len(test), best_fixed),
        "no drift tracking (rho = 1e-7)": np.full(len(test), lo),
    }
    bands = [(-99, 0), (0, 5), (5, 10), (10, 99)]
    report = {"train_rows": int(len(train)), "test_rows": int(len(test)),
              "log_r_mae": float(np.mean(np.abs(pred_log_r - y[test]))),
              "log_r_r2": float(1 - np.sum((pred_log_r - y[test]) ** 2) / np.sum((y[test] - y[test].mean()) ** 2)),
              "iterations": int(mlp.n_iter_), "best_fixed_rho": best_fixed, "mean_ber_drift_channels": {}, "mean_ber": {}, "mean_ber_by_true_snr_db": {}}
    print(f"train={len(train)} test={len(test)} iterations={mlp.n_iter_}")
    print(f"log(rho) MAE={report['log_r_mae']:.3f}  R^2={report['log_r_r2']:.3f}\n")
    header = f"{'policy':34s} {'all':>8s} {'drift':>8s}" + "".join(f"{f'{a}..{b} dB':>12s}" for a, b in bands)
    print("held-out mean BER\n" + header)
    for name, r in policies.items():
        b = ber_at(r, grid, bers[test])
        report["mean_ber"][name] = float(b.mean())
        per_band = {}
        report["mean_ber_drift_channels"][name] = float(b[drift[test]].mean())
        line = f"{name:34s} {b.mean():8.5f} {b[drift[test]].mean():8.5f}"
        for a, c in bands:
            m = (true_snr[test] >= a) & (true_snr[test] < c)
            per_band[f"{a}..{c}"] = float(b[m].mean()) if m.any() else None
            line += f"{b[m].mean():12.5f}" if m.any() else f"{'-':>12s}"
        report["mean_ber_by_true_snr_db"][name] = per_band
        print(line)

    model_path = out / "r_policy.onnx"
    export_onnx(scaler, mlp, model_path)

    # Cross-check the hand-built graph against scikit-learn, then write golden
    # vectors that the Go test replays through gonnx.
    import onnxruntime as ort
    sess = ort.InferenceSession(str(model_path))
    sample = x[test[:32]]
    onnx_out = np.array([sess.run(None, {"features": row[None, :]})[0][0, 0] for row in sample])
    sk_out = mlp.predict(scaler.transform(sample))
    max_diff = float(np.max(np.abs(onnx_out - sk_out)))
    assert max_diff < 1e-4, f"ONNX export disagrees with sklearn by {max_diff}"
    report["onnx_vs_sklearn_max_abs_diff"] = max_diff
    golden = [{"features": [float(v) for v in f], "log_rho": float(o)} for f, o in zip(sample, onnx_out)]
    (out / "r_policy.golden.json").write_text(json.dumps(golden, indent=1))
    (out / "report.json").write_text(json.dumps(report, indent=2))
    print(f"\nexported {model_path} ({model_path.stat().st_size} bytes); onnxruntime vs sklearn max diff {max_diff:.2e}")


if __name__ == "__main__":
    main()
