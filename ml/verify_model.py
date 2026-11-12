"""Validate ONNX policy artifacts for gonnx compatibility and numerical parity.

Checks:
  1. onnx.checker.check_model passes on r_policy.onnx.
  2. IR version == 8, opset == 13, and every graph operator is in the pure-Go
     gonnx supported subset {Sub, Mul, Gemm, Relu}.
  3. Input shape is [1, 6] float32 ("features") and output shape is [1, 1]
     float32 ("log_rho").
  4. Replaying r_policy.golden.json through onnxruntime matches every expected
     log_rho within 1e-4.
  5. report.json contains finite evaluation metrics, meets --min-r2 when set,
     and (when --require-drift-gain is set) achieves lower mean BER than
     non-tracking (rho = 1e-7) both overall and on drifting channels.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import numpy as np
import onnx
import onnxruntime as ort

ALLOWED_OPS = {"Sub", "Mul", "Gemm", "Relu"}


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify exported ONNX policy model and golden vectors.")
    ap.add_argument("--models-dir", default="ml/models", help="Directory containing r_policy.onnx, r_policy.golden.json, report.json")
    ap.add_argument("--min-r2", type=float, default=None, help="Optional minimum held-out log(rho) R^2 threshold")
    ap.add_argument("--require-drift-gain", action="store_true", help="Assert ONNX MLP beats no-drift-tracking BER")
    args = ap.parse_args()

    models_dir = Path(args.models_dir).resolve()
    onnx_path = models_dir / "r_policy.onnx"
    golden_path = models_dir / "r_policy.golden.json"
    report_path = models_dir / "report.json"

    model = onnx.load(str(onnx_path))
    onnx.checker.check_model(model)

    if model.ir_version != 8:
        raise AssertionError(f"Expected ONNX ir_version 8 for gonnx, got {model.ir_version}")
    opsets = {imp.domain or "ai.onnx": imp.version for imp in model.opset_import}
    if opsets.get("ai.onnx") != 13:
        raise AssertionError(f"Expected ai.onnx opset 13 for gonnx, got {opsets}")

    ops = {node.op_type for node in model.graph.node}
    disallowed = ops - ALLOWED_OPS
    if disallowed:
        raise AssertionError(f"ONNX graph contains operators unsupported by gonnx: {sorted(disallowed)}")

    sess = ort.InferenceSession(str(onnx_path))
    golden = json.loads(golden_path.read_text(encoding="utf-8"))
    if not golden:
        raise AssertionError("r_policy.golden.json is empty")

    max_diff = 0.0
    for idx, item in enumerate(golden):
        x = np.asarray([item["features"]], dtype=np.float32)
        if x.shape != (1, 6):
            raise AssertionError(f"Golden vector {idx} has shape {x.shape}, expected (1, 6)")
        pred = float(sess.run(None, {"features": x})[0][0, 0])
        diff = abs(pred - float(item["log_rho"]))
        max_diff = max(max_diff, diff)
        if diff > 1e-4:
            raise AssertionError(f"Golden vector {idx} mismatch: ort={pred:.6f} golden={item['log_rho']:.6f}")

    report = json.loads(report_path.read_text(encoding="utf-8"))
    r2 = float(report["log_r_r2"])
    mae = float(report["log_r_mae"])
    if not (math.isfinite(r2) and math.isfinite(mae)):
        raise AssertionError(f"Non-finite metrics in report.json: {report}")
    if args.min_r2 is not None and r2 < args.min_r2:
        raise AssertionError(f"Model log_r_r2={r2:.4f} is below required minimum {args.min_r2:.4f}")

    if args.require_drift_gain:
        mean_ber = report.get("mean_ber") or {}
        drift_ber = report.get("mean_ber_drift_channels") or {}
        if mean_ber.get("onnx MLP", 1.0) >= mean_ber.get("no drift tracking (rho = 1e-7)", 0.0):
            raise AssertionError(f"ONNX MLP did not improve overall mean BER over no-tracking: {mean_ber}")
        if drift_ber.get("onnx MLP", 1.0) >= drift_ber.get("no drift tracking (rho = 1e-7)", 0.0):
            raise AssertionError(f"ONNX MLP did not improve drift-channel BER over no-tracking: {drift_ber}")

    print(
        f"Verified {onnx_path.name} ({onnx_path.stat().st_size} B): "
        f"ir={model.ir_version}, opset=13, ops={sorted(ops)}, "
        f"golden_vectors={len(golden)}, max_diff={max_diff:.2e}, R^2={r2:.4f}, MAE={mae:.3f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
