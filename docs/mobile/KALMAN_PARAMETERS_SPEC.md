# Complete Kalman Filter & Channel Parameter Specification

This specification defines all **25 parameters** measured, derived, and predicted by **Kalman Parameter Lab** (`apps/flutter/kalman_mobile/lib/models/kalman_parameters.dart`).

---

## 1. Scalar Random-Walk Kalman State Model

For DC-drift estimation on balanced BPSK blocks (`DCBlockSymbols = 8` symbols, $N_b = 64$ samples/block at $8$ samples/symbol):

$$\begin{aligned}
\text{State Transition:} \quad x_k &= x_{k-1} + w_k, \qquad w_k \sim \mathcal{N}(0, Q) \\
\text{Block Observation:} \quad z_k &= x_k + v_k, \qquad v_k \sim \mathcal{N}(0, R)
\end{aligned}$$

### Prediction & Update Recursion

$$\begin{aligned}
P_k^- &= P_{k-1} + Q && \text{(Prior Error Covariance)} \\
\tilde{y}_k &= z_k - x_{k-1} && \text{(Measurement Innovation / Residual)} \\
S_k &= P_k^- + R && \text{(Innovation Covariance)} \\
K_k &= \frac{P_k^-}{S_k} = \frac{P_k^-}{P_k^- + R} && \text{(Optimal Kalman Gain)} \\
x_k &= x_{k-1} + K_k \tilde{y}_k && \text{(Posterior State Estimate)} \\
P_k &= (1 - K_k) P_k^- && \text{(Posterior Error Covariance)}
\end{aligned}$$

### Algebraic Riccati Steady-State Solution

Setting $P_\infty = P_{k} = P_{k-1}$ yields $P_\infty^2 + Q P_\infty - Q R = 0$. Defining the scale-invariant tracking ratio $\rho = Q / R > 0$:

$$K_\infty = \frac{-\rho + \sqrt{\rho^2 + 4\rho}}{2}, \qquad P_\infty = K_\infty \cdot R$$

Notice that $K_\infty$ depends **exclusively** on $\rho = Q / R$, confirming mathematically why the Controller's rule (`ρ = 0.0268`) and ONNX policy (`log_rho`) parameterize adaptation via $\rho$.

---

## 2. Master Parameter Catalog (25 Parameters)

### Category A — State & Riccati Covariance (`ParameterCategory.stateAndCovariance`)

| # | ID | Symbol | Parameter Name | Mathematical Definition | Unit | Healthy Gate / Range | Wire / Engine Source |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `state_x` | $x_k$ | Kalman State (DC Estimate) | $x_{k-1} + K_k(z_k - x_{k-1})$ | $\text{V}$ | Finite | `ReceiverMetrics.dc_estimate` / `filter.x` |
| 2 | `cov_p_minus` | $P_k^-$ | Prior Error Covariance | $P_{k-1} + Q$ | $\text{V}^2$ | $> 0$ | `ScalarKalmanFilter.pPrior` / Shadow Riccati |
| 3 | `cov_p` | $P_k$ | Posterior Error Covariance | $(1 - K_k) P_k^-$ | $\text{V}^2$ | $\ge 0$ | `ScalarKalmanFilter.p` / Shadow Riccati |
| 4 | `gain_k` | $K_k$ | Dynamic Kalman Gain | $P_k^- / (P_k^- + R)$ | — | $(0, 1)$ | `ScalarKalmanFilter.gainK` / Shadow Riccati |
| 5 | `gain_k_inf` | $K_\infty$ | Steady-State Riccati Gain | $(-\rho + \sqrt{\rho^2 + 4\rho}) / 2$ | — | $(0, 1)$ | Derived from applied $\rho = Q/R$ |
| 6 | `cov_gap` | $\|P_k - P_\infty\|$ | Riccati Convergence Gap | $\|P_k - K_\infty R\|$ | $\text{V}^2$ | $< 0.05$ | Derived + tracks step $k$ & reset count |
| 7 | `true_err` | $\|e_k\|$ | Ground-Truth Tracking Error | $\|x_k - x_{\text{true},k}\|$ | $\text{V}$ | $\to 0$ | On-Device Workbench (`null` on live links) |

### Category B — Noise & Innovation Diagnostics (`ParameterCategory.noiseAndInnovation`)

| # | ID | Symbol | Parameter Name | Mathematical Definition | Unit | Healthy Gate / Range | Wire / Engine Source |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 8 | `noise_q` | $Q$ | Process Noise Covariance | $\mathbb{E}[w_k^2] = \rho R$ | $\text{V}^2$ | $> 0$ | `ReceiverMetrics.active_kalman_q` |
| 9 | `noise_r` | $R$ | Measurement Noise Covariance | $\mathbb{E}[v_k^2]$ | $\text{V}^2$ | $[0.005, 5.0]$ | `ReceiverMetrics.active_kalman_r` |
| 10 | `ratio_rho` | $\rho$ | Kalman Tracking Ratio | $Q / R$ (plus $\log_{10}\rho$) | — | $[10^{-7}, 10]$ | Derived from active $Q, R$ |
| 11 | `meas_z` | $z_k$ | Raw Frame / Block Mean | $\frac{1}{N}\sum_{i=1}^{N} z_i$ | $\text{V}$ | Finite | `ReceiverMetrics.frame_mean` |
| 12 | `innov_y` | $\tilde{y}_k$ | Innovation (Residual) | $z_k - x_{k-1}$ | $\text{V}$ | $\|\tilde{y}_k\| \le 2\sqrt{S_k}$ | `filter.innovationY` / frame residual |
| 13 | `innov_s` | $S_k$ | Innovation Covariance | $P_k^- + R$ | $\text{V}^2$ | $> 0$ | `filter.innovationCovS` / Shadow Riccati |
| 14 | `nis` | $\text{NIS}_k$ | Normalized Innovation Squared | $\tilde{y}_k^2 / S_k \sim \chi^2_1$ | — | $\le 3.841$ ($95\%$) | $\chi^2(1)$ filter consistency detector |
| 15 | `res_rms` | $\text{RMS}(\tilde{y})$ | Rolling Innovation RMS | $\sqrt{\frac{1}{W}\sum_{i=1}^{W} \tilde{y}_i^2}$ | $\text{V}$ | $\approx \sqrt{S_\infty}$ | 32-step rolling window |

### Category C — Physical BPSK Channel & Media Quality (`ParameterCategory.channelAndSignal`)

| # | ID | Symbol | Parameter Name | Mathematical Definition | Unit | Healthy Gate / Range | Wire / Engine Source |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 16 | `snr_db` | $\text{SNR}$ | Signal-to-Noise Ratio | $10 \log_{10}(\hat{A}^2 / \hat{\sigma}^2)$ | $\text{dB}$ | $\ge 5.0\text{ dB}$ | `ReceiverMetrics.snr_db` |
| 17 | `noise_var` | $\hat{\sigma}^2$ | Channel Noise Variance | $\frac{1}{N}\sum (z_i - \hat{d}_i)^2$ | $\text{V}^2$ | $> 0$ | `ReceiverMetrics.noise_variance` |
| 18 | `rx_power` | $P_{\text{rx}}$ | Received Frame Power | $\frac{1}{N}\sum z_i^2$ | $\text{W}$ | $> 0$ | `BpskFrameMetrics.receivedPower` |
| 19 | `ber` | $\text{BER}$ | Bit Error Rate | $N_{\text{err}} / N_{\text{bits}}$ | — | $\le 0.02$ | `ReceiverMetrics.ber` (`null` if `compared_bits == 0`) |
| 20 | `psnr` | $\text{PSNR}$ | Image Reconstruction PSNR | $10 \log_{10}(255^2 / \text{MSE})$ | $\text{dB}$ | $\ge 25\text{ dB}$ | `livekalman_sdk.compareBmp` on BMP transfers |
| 21 | `ssim` | $\text{SSIM}$ | Image Structural Similarity | Wang et al. (2004) $11\times 11$ BT.601 | — | $[0, 1]$ | `livekalman_sdk.compareBmp` on BMP transfers |
| 22 | `latency` | $\Delta t_{\text{dsp}}$ | Frame DSP Latency & Queue | $t_{\text{done}} - t_{\text{capture}}$ | $\text{ms}$ | `sequence_gaps == 0` | `ReceiverMetrics.{latency_ms, queue_depth, sequence_gaps}` |

### Category D — Adaptive Controller & ML Policy (`ParameterCategory.adaptiveAndMl`)

| # | ID | Symbol | Parameter Name | Mathematical Definition | Unit | Healthy Gate / Range | Wire / Engine Source |
| :- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 23 | `policy_mode` | $\pi(\theta)$ | Active Adaptation Policy | `rule` ($\rho=0.0268$) or `onnx` ($6\to16\to16\to1$) | — | Versioned | `PolicyDecision.policy` + `active_config_version` |
| 24 | `pred_rho` | $\hat{\rho}_{\text{ML}}$ | Policy Recommended $\rho$ | $\text{clamp}(10^{\text{MLP}(f_6)}, 10^{-7}, 10)$ | — | $[10^{-7}, 10]$ | `PolicyDecision.{predicted_rho, proposed_kalman_q/r}` |
| 25 | `ml_class` | $C_t \to \hat{C}_{t+1}$ | 12-Frame Channel Quality Class | $\text{Softmax}(\text{MLP}_{32\times 32}(f_{10}))$ | — | `good` / `moderate` | `ChannelAssessment.{measured_class, predicted_class, confidence}` |

---

## 3. Parameters Intentionally Marked Not Available

Following `docs/ml-monitoring.md`, the receiver operates on real-valued baseband BPSK without a carrier phase-locked loop (PLL) or multipath equalizer. Therefore:

- **Carrier Phase Error / Doppler Shift / Delay Spread:** Not present in real-sample BPSK; never fabricated.
- **Ground-Truth DC Offset ($x_{\text{true}}$) in Live Mode:** Unobservable on a physical/remote receiver; `true_err` transitions automatically to `ValueProvenance.unavailable` (`Not Measured`) when `isLiveSource == true`.
- **PSNR / SSIM on Non-Image Streams:** Evaluated strictly on complete uncompressed 24/32-bit BMP transfers using original header geometry.
