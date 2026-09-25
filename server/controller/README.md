# Controller server - Laptop 3

## Owns

- Metrics windows, adaptation policy and desired configuration state.
- `ControllerService`, experiment events and the SSE dashboard gateway.
- Coordination/audit behavior and future AI policies.
- Stable feeds consumed by MAUI and Flutter applications.

`main.go` wires gRPC and HTTP listeners. Baseline policy remains in `core/`; optional AI policies and exporters implement the interfaces in `extensions/`.

```powershell
go build -o bin/controller.exe ./server/controller
.\bin\controller.exe --config configs/local.json
```

UI code belongs under `apps/`; keep controller APIs presentation-neutral.

