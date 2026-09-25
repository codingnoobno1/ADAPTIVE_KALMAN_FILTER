# Three-person development workflow

## Ownership

1. Sender developer works in `server/sender/`.
2. Receiver developer works in `server/receiver/`.
3. Controller developer works in `server/controller/` and coordinates API consumption with `apps/`.

Shared areas (`proto/`, `shared/`, `pkg/labclient`, `sdk/` and `configs/`) require agreement because they may break another developer's branch.

## Branch convention

- `feature/sender-<topic>`
- `feature/receiver-<topic>`
- `feature/controller-<topic>`
- `contract/<topic>` for coordinated protobuf changes

Rebase or merge `main` before changing a shared contract. Regenerate Go and Dart clients in the same contract commit. Never edit generated files under `gen/` or `sdk/dart/livekalman_sdk/lib/src/generated/` manually.

## Integration gate

Before merging:

```powershell
.\scripts\build-all.ps1
.\scripts\run-all.ps1
.\bin\labctl.exe
.\scripts\stop-all.ps1
```

The merge is ready when all builds pass and `labctl` reports three ready nodes with progressing sequence numbers.

