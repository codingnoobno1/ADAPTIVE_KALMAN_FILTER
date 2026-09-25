# Three-server workspace

Each subfolder is an independently buildable process and a separate developer ownership boundary.

| Folder | Machine | Binary | Primary owner |
| --- | --- | --- | --- |
| `sender/` | Laptop 1 | `sender.exe` | Signal generation and outbound sample stream |
| `receiver/` | Laptop 2 | `receiver.exe` | Kalman/DSP, demodulation and metrics |
| `controller/` | Laptop 3 | `controller.exe` | Adaptation policy, coordination and UI feed |

Every folder follows the same convention:

```text
main.go          process composition: config, listeners, clients, lifecycle
core/            required service behavior for the working baseline
extensions/      interfaces for optional hardware, AI and export features
README.md        ownership, inputs, outputs and extension rules
```

The three developers should normally work only inside their assigned server folder. Changes to `proto/`, `shared/` or `configs/` affect more than one person and require a coordinated review.

