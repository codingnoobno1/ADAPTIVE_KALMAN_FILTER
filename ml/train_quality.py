"""Train the channel-quality classifier and export it for the Go Controller.

Task: from the measurements of the current 12-frame window (shared/quality
features), predict the measured channel class of the NEXT window:
good / moderate / poor / unstable.

Input:  ml/data/quality_dataset.csv from `go run ./cmd/qualitygen` (simulated;
        see ml/README.md for training on recorded live metrics instead).
Output: ml/models/quality.onnx           logits, opset 13: Sub, Mul, Gemm, Relu
        ml/models/quality.golden.json    features -> logits for the Go parity test
        ml/models/quality_report.json    evaluation, baselines, training info

Honest evaluation rules:
- Train/validation/test are split by SCENARIO, so overlapping windows of one
  stream never appear on both sides.
- Model choice uses validation data only; test is touched once.
- Every model is compared with the persistence baseline (next = current),
  which is hard to beat because channel classes usually persist.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import onnx
import sklearn
from onnx import TensorProto, helper, numpy_helper
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler

CLASSES = ["good", "moderate", "poor", "unstable"]
FEATURES = ["snr_db_mean", "snr_db_std", "snr_db_trend", "noise_var_mean", "noise_var_std",
            "ber_mean", "ber_std", "ber_available", "frame_mean_std", "frame_mean_step"]
SEED = 20261112


def load(path: Path):
    header = path.read_text().splitlines()[0].split(",")
    raw = np.genfromtxt(path, delimiter=",", skip_header=1, dtype=str)
    col = {name: raw[:, i] for i, name in enumerate(header)}
    missing = [f for f in FEATURES + ["current_class", "next_class", "scenario"] if f not in col]
    if missing:
        raise SystemExit(f"dataset is missing columns {missing}; regenerate with cmd/qualitygen")
    x = np.column_stack([col[f].astype(np.float64) for f in FEATURES]).astype(np.float32)
    if not np.all(np.isfinite(x)):
        raise SystemExit("dataset contains non-finite features")
    idx = {c: i for i, c in enumerate(CLASSES)}
    cur = np.array([idx[c] for c in col["current_class"]])
    nxt = np.array([idx[c] for c in col["next_class"]])
    return x, cur, nxt, col["scenario"].astype(int)


def split_by_scenario(groups: np.ndarray, rng: np.random.Generator):
    ids = rng.permutation(np.unique(groups))
    n = len(ids)
    train_ids, val_ids = set(ids[: int(0.7 * n)]), set(ids[int(0.7 * n): int(0.85 * n)])
    tr = np.array([g in train_ids for g in groups])
    va = np.array([g in val_ids for g in groups])
    return tr, va, ~(tr | va)


def evaluate(y_true, y_pred, current) -> dict:
    changed = y_true != current
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "macro_f1": float(f1_score(y_true, y_pred, average="macro", labels=range(4), zero_division=0)),
        "per_class_f1": {c: float(v) for c, v in zip(CLASSES, f1_score(y_true, y_pred, average=None, labels=range(4), zero_division=0))},
        "accuracy_when_class_changes": float(np.mean(y_pred[changed] == y_true[changed])) if changed.any() else None,
        "accuracy_when_class_persists": float(np.mean(y_pred[~changed] == y_true[~changed])) if (~changed).any() else None,
        "confusion_matrix": {"labels": CLASSES, "rows_true_cols_pred": confusion_matrix(y_true, y_pred, labels=range(4)).tolist()},
    }


def layers_of(model, scaler):
    """Return (mean, inv_scale, [(W, b), ...]) for a fitted LR or MLP."""
    if isinstance(model, LogisticRegression):
        return [(model.coef_.T, model.intercept_)]
    return list(zip(model.coefs_, model.intercepts_))


def export_onnx(scaler, model, path: Path, doc: str) -> None:
    init = [numpy_helper.from_array(scaler.mean_.astype(np.float32), "scaler_mean"),
            numpy_helper.from_array((1.0 / scaler.scale_).astype(np.float32), "scaler_inv_scale")]
    nodes = [helper.make_node("Sub", ["features", "scaler_mean"], ["centered"]),
             helper.make_node("Mul", ["centered", "scaler_inv_scale"], ["h0"])]
    layers = layers_of(model, scaler)
    for i, (w, b) in enumerate(layers):
        init += [numpy_helper.from_array(w.astype(np.float32), f"W{i}"), numpy_helper.from_array(b.astype(np.float32), f"b{i}")]
        out = "logits" if i == len(layers) - 1 else f"z{i + 1}"
        nodes.append(helper.make_node("Gemm", [f"h{i}", f"W{i}", f"b{i}"], [out]))
        if i != len(layers) - 1:
            nodes.append(helper.make_node("Relu", [out], [f"h{i + 1}"]))
    graph = helper.make_graph(nodes, "channel_quality",
                              [helper.make_tensor_value_info("features", TensorProto.FLOAT, [1, len(FEATURES)])],
                              [helper.make_tensor_value_info("logits", TensorProto.FLOAT, [1, len(CLASSES)])], init)
    m = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 13)], producer_name="streaming-live-kalman/ml/train_quality.py")
    m.ir_version = 8
    m.doc_string = doc
    onnx.checker.check_model(m)
    path.parent.mkdir(parents=True, exist_ok=True)
    onnx.save(m, path)


def logits_of(model, xs):
    if isinstance(model, LogisticRegression):
        return model.decision_function(xs)
    h = xs
    for i, (w, b) in enumerate(zip(model.coefs_, model.intercepts_)):
        h = h @ w + b
        if i < len(model.coefs_) - 1:
            h = np.maximum(h, 0)
    return h


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default="ml/data/quality_dataset.csv")
    ap.add_argument("--out", default="ml/models")
    args = ap.parse_args()
    data, out = Path(args.data), Path(args.out)

    x, cur, y, groups = load(data)
    rng = np.random.default_rng(SEED)
    tr, va, te = split_by_scenario(groups, rng)
    scaler = StandardScaler().fit(x[tr])
    xs = scaler.transform(x)

    candidates = {
        "logistic_regression": LogisticRegression(max_iter=2000, class_weight="balanced"),
        "mlp_32x32_relu": MLPClassifier(hidden_layer_sizes=(32, 32), activation="relu", alpha=1e-4,
                                        learning_rate_init=2e-3, max_iter=400, early_stopping=True,
                                        n_iter_no_change=20, random_state=SEED),
    }
    val = {}
    for name, model in candidates.items():
        model.fit(xs[tr], y[tr])
        val[name] = evaluate(y[va], model.predict(xs[va]), cur[va])
        print(f"validation {name:22s} acc={val[name]['accuracy']:.4f} macroF1={val[name]['macro_f1']:.4f} changes={val[name]['accuracy_when_class_changes']:.4f}")
    val["persistence_baseline"] = evaluate(y[va], cur[va], cur[va])
    print(f"validation {'persistence_baseline':22s} acc={val['persistence_baseline']['accuracy']:.4f} macroF1={val['persistence_baseline']['macro_f1']:.4f}")

    chosen = max(candidates, key=lambda n: val[n]["macro_f1"])  # validation only
    model = candidates[chosen]
    test = {
        chosen: evaluate(y[te], model.predict(xs[te]), cur[te]),
        "persistence_baseline": evaluate(y[te], cur[te], cur[te]),
    }
    print(f"\nchosen on validation macro-F1: {chosen}")
    for k, v in test.items():
        print(f"test {k:22s} acc={v['accuracy']:.4f} macroF1={v['macro_f1']:.4f} changes={v['accuracy_when_class_changes']}")

    beats = test[chosen]["macro_f1"] > test["persistence_baseline"]["macro_f1"]
    onnx_path = out / "quality.onnx"
    tmp_doc = f"features={FEATURES} -> logits over {CLASSES}; softmax in the caller"
    export_onnx(scaler, model, onnx_path, tmp_doc)
    digest = hashlib.sha256(onnx_path.read_bytes()).hexdigest()[:12]
    version = f"quality-{chosen}-{datetime.now(timezone.utc):%Y%m%d}-{digest}"

    import onnxruntime as ort
    sess = ort.InferenceSession(str(onnx_path))
    sample = x[te][:32]
    onnx_logits = np.array([sess.run(None, {"features": row[None, :]})[0][0] for row in sample])
    sk_logits = logits_of(model, scaler.transform(sample))
    max_diff = float(np.max(np.abs(onnx_logits - sk_logits)))
    assert max_diff < 1e-3, f"ONNX logits disagree with sklearn by {max_diff}"
    assert np.all(onnx_logits.argmax(1) == model.predict(scaler.transform(sample))), "ONNX argmax != sklearn predict"

    report = {
        "model_version": version,
        "task": "predict the measured channel class of the next 12-frame window from the current window",
        "classes": CLASSES,
        "features": FEATURES,
        "chosen_model": chosen,
        "selection_rule": "highest validation macro-F1 among candidates",
        "beats_persistence_baseline_on_test_macro_f1": bool(beats),
        "validation": val,
        "test": test,
        "onnx_vs_sklearn_max_abs_logit_diff": max_diff,
        "training": {
            "dataset": str(data).replace("\\", "/"),
            "dataset_sha256": hashlib.sha256(data.read_bytes()).hexdigest(),
            "data_source": "simulated (cmd/qualitygen)",
            "rows": {"train": int(tr.sum()), "validation": int(va.sum()), "test": int(te.sum())},
            "scenarios": int(len(np.unique(groups))),
            "split": "by scenario 70/15/15",
            "seed": SEED,
            "sklearn": sklearn.__version__,
            "trained_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        },
        "class_rules": "shared/quality/channel.go MeasuredClass (unstable: SNR std > 3 dB or new sequence gap; BER <= 1e-3 good, <= 2e-2 moderate, else poor; SNR bands 10/5 dB when BER is unavailable)",
    }
    (out / "quality_report.json").write_text(json.dumps(report, indent=2))
    golden = [{"features": [float(v) for v in f], "logits": [float(v) for v in o]} for f, o in zip(sample, onnx_logits)]
    (out / "quality.golden.json").write_text(json.dumps({"model_version": version, "vectors": golden}, indent=1))
    print(f"\nexported {onnx_path} ({onnx_path.stat().st_size} bytes) version {version}; onnx vs sklearn max diff {max_diff:.2e}")


if __name__ == "__main__":
    main()
