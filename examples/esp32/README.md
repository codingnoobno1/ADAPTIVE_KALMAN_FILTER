# ESP32 file sender

The ESP32 sends text, image and audio files to the Receiver (Laptop 2) over
Wi-Fi. Each frame is a binary protobuf `TxFrame`, sent with
`POST http://<receiver>:8082/api/v1/frames`, and the reply is a binary
`RxFeedback`. This avoids needing gRPC/HTTP2 on the microcontroller, while the
frames follow the same contract as the Go Sender:

- 8 file bytes per 512-sample frame at 8 samples/symbol, least-significant bit
  first;
- the payload scrambled with the per-frame keystream of `shared/dsp.Scramble`
  (`scrambled = true`);
- a `MediaDescriptor` (file name, type, size, CRC-32) on every frame.

The Receiver demodulates each frame, reassembles and CRC-checks the file, and
streams it to every client: `GET :8082/api/v1/media`, `WatchMedia`, and the
Flutter app.

## Layout

```text
platformio/
  platformio.ini        esp32dev, Arduino, LittleFS, nanopb runtime from the registry
  src/main.cpp          Wi-Fi, LittleFS, HTTP; sends every file in kFiles, then repeats
  lib/lk_media/         portable C framing (lk_media.c/.h), no Arduino dependency
    common/v1, rx/v1    generated nanopb code (scripts/generate-esp32.ps1), committed
  data/                 files uploaded to the ESP32 flash (hello.txt, kalman.bmp, tone.wav)
hosttest/               builds the same lk_media code on a PC and checks it against a real Receiver
```

## Run it on an ESP32

1. Install [PlatformIO](https://platformio.org/install).
2. In `src/main.cpp`, set `kSsid`, `kPassword` and `kReceiverUrl` (Laptop 2's
   IP address, port 8082). Optionally change `kFiles` or `kNoiseStddev`.
   Noise around 1.5–2.5 corrupts bits visibly.
3. From `examples/esp32/platformio`:
   ```powershell
   pio run -t uploadfs      # copy data/ to the ESP32's LittleFS flash
   pio run -t upload        # build and flash the firmware
   pio device monitor       # watch "sending ... / sent ... (B/s)"
   ```
4. On Laptop 2, run the Receiver and allow inbound TCP 8082. **Do not run the
   Go Sender against the same Receiver at the same time.** The Receiver tracks
   one signal stream, and two interleaved streams look like sequence gaps that
   abort transfers.

Throughput is limited by one HTTP request per 8-byte frame, typically a few
hundred bytes per second over Wi-Fi. The 9 KB BMP takes a few tens of seconds.
To add a file, put it in `data/`, add it to `kFiles`, and run `uploadfs`. A
file name longer than 63 characters is truncated. Files are read in chunks,
so a file can be as large as the flash partition, but keep it small because
of the link rate.

## After changing `receiver.proto` or `common.proto`

```powershell
ml\.venv\Scripts\python.exe -m pip install nanopb
.\scripts\generate-esp32.ps1 -Python ml\.venv\Scripts\python.exe
```

Size limits for strings and arrays live in `proto/rx/v1/receiver.options` and
`proto/common/v1/common.options`.

## Verify without hardware (host test)

`hosttest/lk_hosttest.c` compiles the same `lib/lk_media` code with nanopb on
a PC. It checks the scrambler against Go's known vector and CRC-32 against the
standard check value, then writes every frame the ESP32 would POST.
`hosttest/post_frames.py` sends those frames to a real Receiver over HTTP
keep-alive. You need the nanopb C runtime (`pb_encode.c`, `pb_common.c`)
from a [nanopb 0.4.x release](https://github.com/nanopb/nanopb/releases).
From a "x64 Native Tools" (MSVC) prompt:

```bat
set L=examples\esp32\platformio\lib\lk_media
cl /std:c11 /I <nanopb> /I %L% /Fe:lk_hosttest.exe examples\esp32\hosttest\lk_hosttest.c %L%\lk_media.c %L%\rx\v1\receiver.pb.c %L%\common\v1\common.pb.c <nanopb>\pb_encode.c <nanopb>\pb_common.c
lk_hosttest.exe examples\media\kalman.bmp frames [noise_stddev]
python examples\esp32\hosttest\post_frames.py frames http://127.0.0.1:8082/api/v1/frames
```

**Verified on 2026-09-28.** With the Receiver alone on this PC:
- `hello.txt` (13 frames), `kalman.bmp` (1,159 frames) and `tone.wav` (1,006
  frames) were all accepted with HTTP 200, reported `complete` with a valid
  CRC and the right type, and were byte-for-byte identical to the originals.
- With `noise_stddev` 2.0, the text arrived damaged and was flagged
  `checksum mismatch`, with every request still HTTP 200.
- `src/main.cpp` was compiled against stand-in Arduino headers to catch
  C++ errors. It has not yet been built with the real ESP32 toolchain or run
  on a board.

## Production notes

For a real deployment:
- enable TLS and authenticate the device;
- keep Wi-Fi credentials out of source control;
- keep sampling (ADC/DMA) separate from HTTP sending, with a bounded queue,
  and never transmit from an interrupt handler.
