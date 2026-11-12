# Kalman Parameter Lab — Mobile Application Design Suite

This directory contains the architectural, mathematical, UI/UX, and CI/CD engineering specifications for **Kalman Parameter Lab** ([`apps/flutter/kalman_mobile`](../../apps/flutter/kalman_mobile)), added on branch `feature/mobile-app`.

## Document Index

| Document | Scope |
| :--- | :--- |
| [**MOBILE_APP_DESIGN.md**](MOBILE_APP_DESIGN.md) | Dual-mode system architecture (3-Node Live gRPC/HTTP + On-Device Kalman Workbench), deterministic Riccati shadow observer, reconnection state machine, and security boundaries. |
| [**KALMAN_PARAMETERS_SPEC.md**](KALMAN_PARAMETERS_SPEC.md) | Complete mathematical definitions, units, healthy operating bounds, protobuf wire sources, and provenance rules for all **25 measured, derived, and ML-predicted parameters**. |
| [**UI_UX_SPECIFICATION.md**](UI_UX_SPECIFICATION.md) | Responsive mobile/tablet screen architecture, 4-tab navigation hierarchy, oscilloscope chart specifications, formula bottom-sheet inspector, and design tokens. |
| [**CICD_PIPELINE.md**](CICD_PIPELINE.md) | GitHub Actions CI/CD pipeline design ([`mobile-ci.yml`](../../.github/workflows/mobile-ci.yml), [`ci.yml`](../../.github/workflows/ci.yml), [`release.yml`](../../.github/workflows/release.yml)), Android APK/AAB packaging, SHA-256 verification, and signing workflow. |

## Quick Summary

- **Application Path:** `apps/flutter/kalman_mobile` (`com.livekalman.kalman_mobile`)
- **Shared SDK:** `sdk/dart/livekalman_sdk` (generated Protocol Buffers v1 & gRPC client for `Sender`, `Receiver`, and `Controller`)
- **Dual Operating Modes:**
  1. **On-Device Lab Mode:** Runs a pure-Dart scalar Kalman filter and 512-sample BPSK channel/sensor simulator (`ScalarKalmanFilter`, `processBpskFrame`) directly on the phone at 10 Hz or single-step cadence—requiring zero server infrastructure.
  2. **3-Node Live gRPC Mode:** Streams real-time telemetry (`WatchExperiment`, `WatchFrameTraces`, `WatchTxEvents`, `WatchMedia`, `NodeService` 1 s health probes, and `/api/v1/monitor`) from the distributed 3-laptop Go cluster over LAN Wi-Fi (`grpc://`) or TLS Cloudflare Tunnel (`grpcs://`), while maintaining a deterministic shadow Riccati observer synchronized to `ReceiverMetrics`.
