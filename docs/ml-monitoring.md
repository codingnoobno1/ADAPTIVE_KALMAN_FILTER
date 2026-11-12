# Live monitoring and the channel-quality ML module

This document describes the monitoring and ML additions on branch
`feature/ml-monitoring`: what is measured, what is predicted, what is
recommended, and what is not available. The existing gRPC architecture is
reused. No transport was replaced, and every live value shown comes from the
running Sender, Receiver and Controller.

## 1. Data that actually exists

| Source | Message | Fields used |
|---|---|---|
| Sender (`WatchTxEvents`) | `TxFrameTrace` | sequence, clean symbols, first 64 noisy samples, payload bits, original file bytes + offset, timestamp |
| Receiver (`WatchFrameTraces`) | `RxFrameTrace` | sequence, first 64 noisy samples, Kalman DC estimate, detected bits, bit errors / compared bits, BER, timestamp |
| Receiver to Controller (`Adapt`) | `ReceiverMetrics` | SNR (decision-directed), noise variance, BER (only with reference bits), latency, frame mean, DC estimate, **applied Q/R**, **sequence gaps** |
| Receiver (`WatchMedia`) | `MediaEvent` | reconstructed file chunks + offset, end of stream, CRC result |
| Every node (`NodeService`) | `NodeInfo`, `NodeStatus` | role, node id, health, last sequence, peer connected |

**Not available, and shown as such:**
- **Phase error, Doppler, multipath:** samples are real-valued BPSK and the receiver has no carrier-phase tracker.
- **PSNR/SSIM for the general signal:** these are image metrics only.

### Smallest backend changes made

1. `ReceiverMetrics` gained `active_kalman_q`, `active_kalman_r` and
   `sequence_gaps`, so *applied* parameters can be shown next to
   *recommended* ones, and frame loss is measured by the receiver itself.
2. `PolicyDecision.sent_to_receiver` and the Controller option
   `recommendOnly` publish recommendations without applying them.
3. New `ChannelAssessment` message (`ExperimentEvent.assessment`), one per
   non-overlapping 12-frame window.
4. Sender and Receiver now trace **every** frame, not only file-transfer
   frames, so the signal can be probed on an idle stream too. Subscribers use
   bounded channels and drop traces when slow, so the DSP is never blocked.

All protobuf changes are additive. Go, Dart and C# bindings were regenerated;
the ESP32 nanopb files are unaffected.

## 2. Connection health

Implemented in `sdk/dart/livekalman_sdk/lib/src/monitor/health.dart`. Used by
the dashboard and by `example/health_watch.dart`.

Every second, each node gets `GetNodeInfo` and `GetNodeStatus` calls with a
2 s deadline:

| Status | Rule |
|---|---|
| Connection Checking | first probe pending, or node reports `STARTING` |
| Connected | both calls answered, by the **expected role**, with a non-empty node id |
| Service Unavailable | never reached yet, wrong role on that endpoint, or a non-network gRPC error (e.g. `UNIMPLEMENTED`) |
| Connection Lost | first network failure (`UNAVAILABLE`, `DEADLINE_EXCEEDED`, ...) after having been connected |
| Reconnecting | further failures while retrying |
| Data Flow Active / Inactive | the node's `last_sequence` advanced within the last 3 s / did not |

- **TX → RX link:** the Sender reports an open stream to the Receiver
  (`peer_connected`) **and** both nodes' sequences advance.
- **Latency:** the round-trip time of the probe.
- **Reconnection:** every live stream in the dashboard (`LiveLab._keep`)
  resubscribes after errors with backoff of 0.5, 1, 2, 4, then 8 s (capped),
  plus jitter.

A tunnel answering does **not** count as connected. Only the application
protocol does.

### Connectivity options

| Option | Fits this system? | Notes |
|---|---|---|
| Direct LAN | **Recommended** for the 3-laptop demo | Lowest latency; no third party. Use `configs/lan.example.json`. |
| Cloudflare Tunnel | Yes, for remote viewing | Proxies gRPC over HTTP/2 with TLS. Connect the dashboard with `grpcs://host` (TLS is now supported; default port 443) and give each node its own hostname (`txHost`, `rxHost`). The node-to-node links (Sender → Receiver → Controller) should stay on the LAN. |
| ngrok | Possible, with limits | gRPC needs HTTP/2 end to end: use an ngrok TLS/TCP endpoint and `grpcs://` or `grpc://` accordingly. One tunnel per node. |

Whichever is used, check it with the same probes:

```bash
dart run example/health_watch.dart "grpc://127.0.0.1:55053" 30
```

## 3. Structured monitoring API

`GET http://<controller>:8080/api/v1/monitor` (schema `"1"`, Go:
`server/controller/core/monitor.go`; Dart validator: `monitor_json.dart`):

```json
{
  "schema_version": "1",
  "generated_at": "2026-11-12T13:45:01.2Z",
  "device_id": "controller-1",
  "policy": "onnx",
  "recommend_only": false,
  "quality_model_version": "quality-mlp_32x32_relu-20261112-21a8b8a17515",
  "runs": [{
    "run_id": "local-impaired",
    "device_id": "receiver-1",
    "connection_status": "connected",
    "stream_status": "data_flow_active",
    "sequence_number": 1520,
    "timestamp": "2026-11-12T13:45:01.17Z",
    "age_ms": 12,
    "frames_received": 1519,
    "frames_lost": 0,
    "snr": 3.1, "ber": 0.047, "noise_variance": 0.49,
    "phase_error": null, "phase_error_note": "not measured: ...",
    "latency_ms": 0.6,
    "psnr": null, "ssim": null, "image_metrics_note": "...",
    "applied": {"config_version": 23, "kalman_q": 0.013, "kalman_r": 0.49, "rho": 0.027},
    "recommended": {"policy": "onnx", "rho": 0.031, "sent_to_receiver": true, "...": "..."},
    "ml": {"measured_class": "poor", "predicted_class": "poor", "confidence": 0.93, "...": "..."}
  }]
}
```

- **Nulls stay null.** Non-finite values become `null` rather than invalid
  JSON. BER is `null` with `ber_note` when a frame carries no reference bits.
- **Connection and stream status:** `connection_status` is `connection_lost`
  once the Receiver's `Adapt` stream closes. `stream_status` becomes
  `data_flow_inactive` after `staleAfterMs` (default 2000) without metrics.
- **Other endpoints:** `/api/v1/ml/history` (recent assessments) and
  `/api/v1/ml/model` (the model's training report, or 404 when no model is
  loaded).

## 4. Image quality (PSNR / SSIM)

Implemented in `shared/quality/image.go` (Go), `image_quality.dart` (Dart) and
`cmd/imgquality` (CLI). Both implementations match an independent NumPy
reference (`ml/quality_reference.py`) to 1e-6.

- **Inputs:** the transmitted BMP (assembled from Sender `original_bytes` by
  offset) and the receiver's reconstruction (assembled from `MediaEvent`
  chunks by offset). Metrics are computed only when **both** are complete.
- **Preprocessing:** uncompressed 24/32-bit BMP, uint8 RGB. The
  reconstruction's pixels are read with the **original's** header geometry,
  because bit errors can corrupt the received header while pixels stay at the
  same offsets. A truncated reconstruction is an error, never a metric.
- **Definitions:**
  - MSE and PSNR over all R, G, B samples (peak 255).
  - SSIM per Wang et al. 2004 on BT.601 luma: 11×11 Gaussian window, σ = 1.5,
    K1 = 0.01, K2 = 0.03, mean over all full windows.
- **Scope:** BER describes bitstreams; PSNR/SSIM describe images only.

```bash
go run ./cmd/imgquality -original examples/media/kalman.bmp -reconstructed received.bmp
```

## 5. ML module

### A. Channel-quality prediction

- **Task:** from the current 12-frame window, predict the **next** window's
  measured class: good, moderate, poor or unstable.
- **Measured class:** documented rules in `shared/quality/channel.go`.
  - **unstable:** SNR standard deviation > 3 dB, or a new sequence gap.
  - **With BER:** good ≤ 1e-3, moderate ≤ 2e-2, otherwise poor.
  - **Without reference bits:** SNR bands of 10 dB and 5 dB.
- **Features (10):**
  - SNR mean, standard deviation and trend;
  - noise-variance mean and standard deviation;
  - BER mean and standard deviation, and whether BER is available;
  - frame-mean standard deviation and step.

  Latency is reported but not used as a feature: it mostly measures host load.
  The same Go code computes features for training (`cmd/qualitygen`) and at
  run time (Controller), so they cannot drift apart.
- **Data:** `cmd/qualitygen` produced 2,000 **simulated** streams with
  time-varying noise, regime shifts, fading, DC drift, bursts, lost frames and
  some streams without reference bits. That gives 58,000 window pairs. Every
  frame runs through the Receiver's own `dsp.ProcessBPSK`.
- **Training:** `ml/train_quality.py`.
  - Split **by scenario** 70/15/15, so overlapping windows of one stream never
    appear on both sides.
  - Candidates: balanced logistic regression and an MLP (32×32, ReLU).
  - The MLP was chosen on **validation** macro-F1 (0.788 vs 0.745).
  - Exported to ONNX (Sub/Mul/Gemm/Relu, opset 13). Softmax is applied in Go.
  - The Go runtime (gonnx) matches onnxruntime on 32 recorded vectors to 1e-4.

**Test set** (8,700 windows from scenarios never seen in training):

| Predictor | Accuracy | Macro-F1 | Correct when the class changes |
|---|---|---|---|
| Persistence baseline (next = current) | 83.7% | 0.769 | 0% |
| **MLP 32×32 (chosen)** | **85.1%** | **0.787** | **22.4%** |

Per-class F1 for the MLP: good 0.861, moderate 0.703, poor 0.933, unstable
0.652.

**Honest reading:** channel classes usually persist, so "predict no change" is
already strong. The model adds a modest but real gain, mainly by sometimes
anticipating a change. It is trained on simulation only. The dashboard
therefore also shows a **live** check: each prediction is compared with the
next measured window.

### B. Adaptive parameter recommendation

The existing Q/R policies (`rule`, ONNX ρ policy) are reused. They are
validated (bounded R, positive Q, versioned, applied at a future frame), and
the dashboard shows separately:

- **Recommended:** `PolicyDecision` (policy, ρ, version, `sent_to_receiver`);
- **Applied:** `ReceiverMetrics.active_kalman_q/r` and config version.

Set `"recommendOnly": true` in the Controller config to publish
recommendations without applying them. There are no PLL parameters in this
receiver, so none are recommended.

### C. Training on real data

1. Set `"metricsLog": "ml/data/live_metrics.jsonl"` in the Controller config
   (`configs/local-monitor.json` does). Every `ReceiverMetrics` is appended as
   one JSON line.
2. Run real sessions across varied conditions. Labels need no manual work:
   the measured class of the next window is computed from the recording.
3. Convert the recording into the same windowed CSV and retrain with
   `ml/train_quality.py`. This conversion step is not yet automated. A small
   reader using `shared/quality.Summarise` is the next step.

Until then, treat predictions as simulation-trained.

### D. Dashboard

On the Controller role, the **ML channel quality & adaptation** panel shows:
- measured class, predicted class and confidence, and class probabilities;
- model inputs, recommended vs applied Q/R;
- prediction history with ✓/✗, live prediction accuracy;
- the model's offline test metrics.

## 6. Reproduce

```bash
go run ./cmd/qualitygen                                   # ml/data/quality_dataset.csv
ml/.venv/Scripts/python.exe ml/train_quality.py           # ml/models/quality.*
go test ./shared/quality ./server/controller/...          # parity + monitor tests
ml/.venv/Scripts/python.exe ml/quality_reference.py       # SSIM reference value
```

Run the live system with the model loaded:

```bash
bin/controller.exe -config configs/local-monitor.json
bin/receiver.exe -config configs/local-monitor.json
bin/sender.exe -config configs/local-monitor.json
```

Then connect the dashboard with `grpc://127.0.0.1:55053?controllerHttpPort=8080`.
