# Three-laptop demo guide

| | Laptop 1 (Student A) | Laptop 2 (Student B) | Laptop 3 (Student C) |
|---|---|---|---|
| Role | **Sender** (transmitter) | **Receiver** (Kalman DSP) | **Controller** (ONNX ML policy) |
| Opens inbound TCP | 50051, 8081 | 50052, 8082 | 50053, 8080 |
| Dials | Laptop 2 : 50052 | Laptop 3 : 50053 | nothing |
| Flutter app | `--role sender` | `--role receiver` | `--role controller` |

## What happens in real time

The Sender produces **93.75 frames per second**. For every frame:

```text
Laptop 1 SENDER                          Laptop 2 RECEIVER                        Laptop 3 CONTROLLER
file bytes (8 per frame)
 -> scramble (balance the bits)
 -> BPSK: bit 1 = +A, bit 0 = -A,
    8 samples per bit, 64 bits/frame
 -> ADD NOISE (simulated radio channel:
    Gaussian noise, fading, DC drift, bursts)
 -> protobuf TxFrame: 512 float samples
    + reference bits + file metadata
    ===== gRPC stream ProcessSignal =====>  Kalman filter tracks and removes DC drift
                                            -> BPSK decision per bit
                                            -> descramble -> rebuild file, check CRC
    <==== protobuf RxFeedback (SNR, BER) ==   -> ReceiverMetrics
                                              ===== gRPC stream Adapt ===========>  window of 12 frames
                                                                                    -> 6 features -> ONNX model
                                                                                       (pure Go, gonnx)
                                            <==== protobuf PolicyDecision (Q, R) ==  -> Q/R for the Kalman filter
                                            applied at an agreed frame number
```

Things to be precise about with the professor:

- **The noise is simulated inside the Sender software** (`shared/dsp.Channel`)
  before the samples are packed into protobuf. Wi-Fi/TCP between the laptops
  delivers the samples exactly; the "radio channel" is the simulation. The
  noise level can be changed live from the Sender screen.
- **Modulation is BPSK**, the M = 2 case of M-PSK. QPSK and 8-PSK are **not
  implemented**; the protocol's `Modulation` field reserves space for them. Say
  "BPSK, designed to extend to M-PSK", not "M-PSK".
- **The ONNX model really runs.** It is loaded by the Go Controller and runs on
  every decision, which is visible in the Controller console (step 4). Honest
  result: most of the BER improvement comes from Kalman DC-drift tracking
  (−21% live). The model matches a hand-tuned fixed setting and adapts per
  channel; it is not a large extra gain. See [ml-policy.md](ml-policy.md).

---

## 1. One-time setup (each laptop, the day before)

1. **Put all three laptops on the same network.** A phone hotspot works well;
   university Wi-Fi often blocks laptop-to-laptop traffic. Note each IPv4
   address:
   ```powershell
   ipconfig        # "IPv4 Address" of the Wi-Fi adapter
   ```
2. **Get the code and build the servers.** No Flutter or .NET is needed for
   this; the first run downloads Go into `.tools\`.
   ```powershell
   git clone https://github.com/codingnoobno1/ADAPTIVE_KALMAN_FILTER.git
   cd ADAPTIVE_KALMAN_FILTER
   powershell -ExecutionPolicy Bypass -File scripts\build-servers.ps1
   ```
3. **Create the same `configs\lan.json` on all three laptops.** Copy
   `configs\lan.example.json` and change three values:
   - `sender.receiver` → `"<Laptop 2 IP>:50052"`
   - `receiver.controller` → `"<Laptop 3 IP>:50053"`
   - `controller.policy` → `"onnx"`

   Optional, for a stronger demo of drift tracking: add these to the `sender`
   section: `"fadingDepth": 0.7, "fadingPeriodFrames": 20, "driftStddev": 0.01,
   "driftReversion": 0.001, "burstProbability": 0.1, "burstNoiseMultiplier": 3`.
4. **Open the firewall.** In an Administrator PowerShell, run only your
   laptop's line:
   ```powershell
   New-NetFirewallRule -DisplayName "LiveKalman Sender"     -Direction Inbound -Protocol TCP -LocalPort 50051,8081 -Action Allow   # Laptop 1
   New-NetFirewallRule -DisplayName "LiveKalman Receiver"   -Direction Inbound -Protocol TCP -LocalPort 50052,8082 -Action Allow   # Laptop 2
   New-NetFirewallRule -DisplayName "LiveKalman Controller" -Direction Inbound -Protocol TCP -LocalPort 50053,8080 -Action Allow   # Laptop 3
   ```
   Remove the rule after the demo with `Remove-NetFirewallRule -DisplayName "LiveKalman ..."`.
5. **Build the Flutter app once and copy it to the others.** On the laptop
   with Flutter:
   ```powershell
   cd apps\flutter\signal_monitor
   flutter build windows
   ```
   Copy the whole `build\windows\x64\runner\Release\` folder to the other two
   laptops. They do not need Flutter installed.
6. **Rehearse once** with the steps below. Check that every laptop's console
   shows the lines listed in each step.

## 2. On the day: start in this order (Controller → Receiver → Sender)

Each student runs this from the repository folder:

```powershell
# Laptop 3 (Student C)
.\scripts\run-role.ps1 -Role controller
# Laptop 2 (Student B)
.\scripts\run-role.ps1 -Role receiver
# Laptop 1 (Student A)
.\scripts\run-role.ps1 -Role sender
```

Then each student opens the dashboard for their role. Use the real IP
addresses in `--endpoint`:

```powershell
.\signal_monitor.exe --role sender --endpoint "grpc://<L3>:50053?txHost=<L1>&rxHost=<L2>&txPort=50051&rxPort=50052&txHttpPort=8081"
```

Use `--role receiver` on Laptop 2 and `--role controller` on Laptop 3, with the
same endpoint string.

**Check the three are connected** from any laptop:

```powershell
.\bin\labctl.exe -tx <L1>:50051 -rx <L2>:50052 -controller <L3>:50053
```

It lists `sender-1`, `receiver-1` and `controller-1` with their health, found
through the shared gRPC `NodeService`.

## 3. The showcase (about 10 minutes)

**Step 1: Three independent servers (Student C, 1 min).** Run `labctl` in
front of the professor. Explain the layout: three separate Go processes on
three machines, talking only through versioned protobuf contracts in
`proto/`.

**Step 2: The live gRPC/protobuf stream (Student A → B, 2 min).**
- Laptop 1 console, every 16 frames. This is feedback coming back on the same
  bidirectional gRPC stream:
  ```text
  INFO receiver feedback sequence=64 snr_db=3.40 ber=0.0000 latency_ms=0.00 config=1
  ```
- Laptop 2 console, every 32 frames. This is what arrived as protobuf and what
  the DSP did with it:
  ```text
  INFO frame seq=64 samples=512 snr_db=3.4 ber=0.0000 noise_var=0.371 dc_est=-0.218 Q/R=0.0268
  ```
- Point out: each `TxFrame` holds 512 float samples (about 2 KB of protobuf),
  93.75 frames per second, sequence-numbered with timestamps.

**Step 3: Add noise live (Student A, 2 min).** On the Sender screen, raise the
noise (for example 0.7 → 1.5) and apply. Point out:
- the new TX config version takes effect at a frame boundary;
- Laptop 2's `snr_db` drops and `ber` rises;
- the Receiver screen charts move with it.

**Step 4: The ONNX model deciding (Student C, 2 min).**
- At startup, Laptop 3 prints `INFO adaptation policy policy=onnx model=ml/models/r_policy.onnx`.
- Then on every decision:
  ```text
  INFO decision sent policy=onnx sequence=64 Q=0.0007 R=0.379 Q/R=0.00185 reason="onnx: snr 2.8 dB, drift step 0.175 -> Q/R 0.00185"
  ```
- On Laptop 2, the decision arriving and being applied at an agreed frame:
  ```text
  INFO accepted controller decision version=2 effective_sequence=68
  INFO applied receiver config version=2 sequence=68
  ```
- Laptop 1 then shows `config=2` in its feedback.

Explain the loop: metrics go Receiver → Controller, 6 features go into the
ONNX model, and the chosen Kalman Q/R comes back to the Receiver, all over
gRPC. The model is a 2 KB `.onnx` file trained in Python (`ml/train.py`) and
run in pure Go. `go test ./server/controller/...` proves Go and Python give
identical outputs.

**Step 5: Send a file (Student A → B, 3 min).** On the Sender screen, queue
`examples\media\hello.txt`, then `kalman.bmp`, then `tone.wav`. Without the
app you can use:

```powershell
curl.exe -X POST --data-binary "@examples\media\kalman.bmp" "http://<L1>:8081/api/v1/transfers?name=kalman.bmp"
```

- Laptop 1 prints `sending file file=kalman.bmp bytes=9270` and later
  `file sent`.
- Laptop 2 prints `frame ... file=kalman.bmp offset=... of=9270` while it
  arrives. At the end it prints `file received intact` (clean channel), or a
  `checksum mismatch` warning with the damaged file still delivered (noisy
  channel).
- The Receiver screen shows the decoded file.

Good sequence: send `hello.txt` at noise 0.3 (arrives perfect), then at noise
2.0 (visibly corrupted characters). The BMP takes about 12 s and the WAV about
11 s at 750 B/s.

**Step 6 (optional): Rule vs ONNX.** Stop the controller (Ctrl+C), set
`"policy": "rule"` in Laptop 3's `lan.json`, and restart it. The decision lines
now say `rule: noise ..., fixed Q/R 0.0268`. Nothing else in the system
changes, because both policies sit behind the same interface.

## 4. If something goes wrong

| Symptom | Fix |
|---|---|
| Sender: `receiver stream disconnected` repeating | Wrong Laptop 2 IP in `sender.receiver`, Laptop 2's firewall, or the receiver isn't running. |
| Receiver: `controller stream disconnected` | Wrong Laptop 3 IP in `receiver.controller`, or Laptop 3's firewall. |
| Controller: `load onnx policy` error | Run it with `run-role.ps1` (it starts from the repo folder), or set an absolute `onnxModel` path. |
| `bind: Only one usage of each socket address` | A previous run is still going. Close it, or run `.\scripts\stop-all.ps1`. |
| No decisions in the Controller console | Decisions start after the 12-frame window plus a 64-frame cooldown (under 1 s). Check that the Receiver shows frames at all. |
| Flutter shows nothing | Check the `--endpoint` IPs and ports. The controller address is the main URI. |
| File arrives with `checksum mismatch` | Expected at high noise. Lower the noise to show a perfect transfer. |

Don't run the ESP32 and the Go Sender against the same Receiver at the same
time; see [examples/esp32/README.md](../examples/esp32/README.md).
