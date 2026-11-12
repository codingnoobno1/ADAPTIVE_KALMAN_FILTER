# Kalman Parameter Lab (`kalman_mobile`)

Dedicated mobile telemetry & interactive on-device Kalman filter workbench for the **Adaptive Kalman Filter** platform (`com.livekalman.kalman_mobile`).

## Key Capabilities

1. **25-Parameter Matrix & Formula Inspector (`Parameters` Tab)**
   - **State & Covariance:** $x_k$ (`dc_estimate`), prior covariance $P_k^-$, posterior covariance $P_k$, dynamic Kalman gain $K_k$, steady-state Riccati gain $K_\infty$, convergence gap $|P_k - P_\infty|$, and synthetic ground-truth error $|e_k|$.
   - **Noise & Innovation:** Process covariance $Q$, measurement covariance $R$, tracking ratio $\rho = Q/R$, raw frame/block mean $z_k$, innovation $\tilde{y}_k = z_k - x_{k-1}$, innovation covariance $S_k = P_k^- + R$, $\chi^2(1)$ Normalized Innovation Squared ($\text{NIS}_k$), and rolling innovation RMS.
   - **BPSK Channel & Media Quality:** $\text{SNR}$ ($\text{dB}$), noise variance $\hat{\sigma}^2$, received power $P_{\text{rx}}$, $\text{BER}$, compared/error bits, BMP image reconstruction $\text{PSNR}$ & $\text{SSIM}$, DSP latency, queue depth, and sequence gaps.
   - **Adaptive Policy & ML:** Active policy (`rule` vs `onnx`), config versions, recommended $\hat{\rho}$, and 12-frame ML `ChannelAssessment` (`measured_class` vs `predicted_class` & confidence).
   - Tap any parameter card to open its mathematical equation, physical unit, and provenance badge (`Direct`, `Riccati Derived`, `ML Policy`, or `Not Measured`).
2. **Real-Time Multi-Series Oscilloscope (`Charts` Tab)**
   - Synchronized time-series plots for $x_k$ vs $z_k$ vs true offset, $K_k$ & $P_k$ vs $K_\infty$, $\tilde{y}_k$ inside its $\pm 2\sqrt{S_k}$ ($95\%$) consistency envelope, and $\text{SNR}$ / $\rho$ / $\text{BER}$.
3. **On-Device Kalman Workbench (`Lab` Tab)**
   - Pure-Dart port of `shared/dsp/kalman.go` (`ScalarKalmanFilter` + `processBpskFrame`) supporting **Drifting BPSK Link**, **IMU Tilt / Gyro Bias**, and **Step-Response Benchmark** profiles, interactive $Q/R$ sliders, and $+0.65\text{ V}$ impulse injection.
4. **3-Node Live gRPC & HTTP Link (`Live Link` Tab)**
   - Reuses `sdk/dart/livekalman_sdk` over LAN Wi-Fi (`grpc://`) or TLS Cloudflare Tunnel (`grpcs://`) with 1-second `NodeService` probes, exponential-backoff stream reconnection, and versioned `ApplyReceiverConfig` $Q/R$ overrides.

## Design Documentation

Full architectural, mathematical, UI/UX, and CI/CD specifications live in [`docs/mobile/`](../../../docs/mobile/README.md):

- [Mobile Architecture Design](../../../docs/mobile/MOBILE_APP_DESIGN.md)
- [Kalman Parameter Specification](../../../docs/mobile/KALMAN_PARAMETERS_SPEC.md)
- [Mobile UI/UX Specification](../../../docs/mobile/UI_UX_SPECIFICATION.md)
- [Mobile CI/CD Pipeline Guide](../../../docs/mobile/CICD_PIPELINE.md)

## Local Development & Verification

```bash
cd apps/flutter/kalman_mobile
flutter pub get
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --debug
flutter build apk --release --split-per-abi
```
