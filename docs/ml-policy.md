# Kalman drift tracking and the ML adaptation policy

## What the Kalman filter does

The Receiver's Kalman filter tracks the channel's slowly drifting **DC
offset** and subtracts it before each BPSK decision (`dsp.ProcessBPSK`).
Symbols are decided by integrate-and-dump, the matched filter for BPSK in white
noise.

- **Measurement:** the mean of each block of 8 symbols. BPSK symbols are
  zero-mean, so this is an unbiased reading of the offset that does not depend
  on any decision.
- **Tuning knob:** only the ratio **ρ = Q/R** matters. A larger ρ follows fast
  drift but passes more symbol and noise jitter into the estimate. A smaller ρ
  averages longer.
- **Payload scrambling:** file bytes are not balanced (ASCII has a zero top
  bit, images repeat values), and the block mean would mistake content for DC.
  The Sender XORs every media payload with a per-frame keystream
  (`dsp.Scramble`, `TxFrame.scrambled`), and the Receiver reverses it.
  Without scrambling, tracking gave no benefit on a BMP transfer. With it, BER
  fell 21% on the same channel.

### Designs that were tried and rejected

These are worth mentioning in the viva:

1. **Smoothing the samples** with a random-walk Kalman filter before
   integration (the original design). It spreads each symbol into the next.
   In every channel class tested, BER rose as R increased, so the best
   "adaptive" policy was simply "filter as little as possible".
2. **Decision-directed DC tracking** (residual = sample − decided symbol).
   At low SNR, wrong decisions bias the estimate, which causes more wrong
   decisions. The DC estimate ran away to 5–13 and BER went to 0.5, compared
   with 0.17–0.33 for plain decisions. The block-mean estimator above has no
   such feedback loop.

## Policies (Controller)

| `policy` | Decision |
|---|---|
| `rule` (default) | R = latest noise variance (clamped to `[minKalmanR, maxKalmanR]`), Q = 0.0268 · R. That ratio is the best single fixed ρ on the training set. |
| `onnx` | R as above, Q = ρ · R. ρ comes from the ONNX model evaluated on the last `windowSize` (12) metrics. |

The ONNX model runs inside the Go Controller through
[gonnx](https://github.com/advancedclimatesystems/gonnx), a pure-Go runtime,
so no Python, cgo or DLL is needed. A failed or non-finite prediction is logged
and the active configuration is kept. ρ is clamped to the trained range
[1e-7, 10].

**Model contract:**
- **Input** `features` float32[1,6]:
  - `snr_db_mean`, `snr_db_std`
  - `noise_var_mean`, `noise_var_std`
  - `frame_mean_std`, `frame_mean_step` (mean |Δ frame mean|)
- **Output** `log_rho` float32[1,1].
- Feature scaling is inside the graph. The ops are opset 13
  `Sub, Mul, Gemm, Relu` only, which gonnx supports.
- The features are computed from raw samples, so they do not depend on the
  current policy. `ReceiverMetrics.frame_mean` (field 12) carries the drift
  signal, and `dc_estimate` (field 13) exposes the tracker's state for
  dashboards.

## Retrain

```powershell
python -m venv ml\.venv
ml\.venv\Scripts\python.exe -m pip install numpy scikit-learn onnx onnxruntime
.\.tools\go\bin\go.exe run ./cmd/datagen            # -> ml/data/dataset.csv (~10 s)
ml\.venv\Scripts\python.exe ml\train.py             # -> ml/models/*
.\.tools\go\bin\go.exe test ./server/controller/... # gonnx must match Python
```

- `cmd/datagen` simulates 6,000 channels: amplitude 0.3–2, noise σ 0.05–3.
  About 30% are clean. The rest independently get slow fading, mean-reverting
  DC drift, and/or noise bursts (`dsp.Channel`, the same code the Sender
  uses). Each channel is scored at 29 values of ρ in [1e-7, 10] with the
  Receiver's own `ProcessBPSK`. The label is the ρ with the lowest BER; the
  DC-tracking error against the true offset breaks ties.
- `ml/train.py` trains a 6→16→16→1 ReLU MLP on log ρ, chooses the best fixed
  ρ on the training split only, and exports and cross-checks the ONNX file.
  `r_policy.golden.json` holds onnxruntime outputs, and
  `TestGonnxMatchesPython` requires gonnx to match them within 1e-4.

## Results

### Simulation (1,200 held-out channels, `ml/models/report.json`)

| Policy | Mean BER | Drift channels | > 10 dB |
|---|---|---|---|
| Oracle (best ρ per channel) | 0.0609 | 0.0788 | 0.0022 |
| **ONNX MLP** | **0.0619** | **0.0812** | **0.0028** |
| Best fixed ρ = 0.0268 (the `rule` policy) | 0.0625 | 0.0814 | 0.0031 |
| No drift tracking (ρ = 1e-7) | 0.0657 | 0.0923 | 0.0075 |

### Live (three servers, `configs/local-impaired.json`, same seed, 9,270-byte BMP)

| Policy | BER on the received file |
|---|---|
| No drift tracking | 0.0730 |
| Rule (fixed ρ) | 0.0580 |
| ONNX | 0.0591 |

![sent / no tracking / fixed rho / onnx](images/live-bmp-comparison.png)

## Honest reading

- **Most of the gain comes from DC tracking.** It cuts BER by about 5%
  overall and 12% on drifting channels in simulation, and by 21% live.
- **The learned policy adds a smaller, consistent gain over the best fixed
  ρ in simulation:** 1% overall and about 11% at high SNR. Live, on one
  channel, the two are statistically tied.
- **A fixed ρ is only good because it was tuned on the same simulated
  channel mix.** The model adapts per channel without that retuning. Claim
  the ML as "matches a tuned constant and adapts per channel", not as a large
  BER win.
- **The old random-walk smoothing design has been removed.** Its results in
  earlier revisions of this document are superseded.
