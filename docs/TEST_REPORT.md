# Test report

## 2026-09-27 continuation

Attempted baseline command:

```powershell
go test ./...
```

Actual result: not run because `go` is not recognized in the local PowerShell
environment. The repository bootstrap script was inspected and invoked with a
process-only execution-policy bypass; its Go download remained a zero-byte
archive, so the toolchain was not installed. No test pass is claimed.

New receiver unit tests are in `server/receiver/core/service_test.go`. Once a
Go 1.24+ toolchain is available, run:

```powershell
go test ./...
.\scripts\build-all.ps1 -SkipApps
```

The receiver tests cover valid frames, malformed/missing frame metadata,
unsupported formats, sample alignment, NaN/Infinity, reference-bit mismatch,
packed samples, pipeline rejection, and invalid Q/R configuration/decisions.
They also verify that changing simulation reference bits changes BER scoring
but not measured/estimated signal-quality features.

## 2026-09-27 verification (merged into original checkout)

Toolchain: project-local Go 1.25.1 (`.tools/go/bin/go.exe`).

- `go test ./shared/...` passes: config, dsp (including the `Decoded` bit
  output and the reference-independent SNR test), and node.
- `server/receiver/core` passes when built without the in-progress
  `media.go`. With `media.go` present, the package does not compile because
  the `MediaDescriptor`/`MediaEvent`/`WatchMediaRequest` protobuf types have
  not yet been regenerated (`scripts/generate.ps1`) and `Server.media` is not
  wired. That failure predates this merge.

## 2026-09-27 media receiver verification

The media protobufs were regenerated and the receiver wiring was completed.

- `.tools/go/bin/go.exe test ./...` passes.
- `.tools/go/bin/go.exe vet ./...` passes.
- Dart SDK `dart analyze` reports no issues.
- `scripts/build-all.ps1 -SkipApps` succeeds.
- Receiver tests cover BPSK byte reconstruction, byte-shift reversal after
  demodulation, CRC validation, text/image/audio detection and filtering,
  packed sample validation, and rejection of mid-transfer key changes.
