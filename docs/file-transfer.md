# Sending text, images and audio over the BPSK link

The Sender modulates real file bytes into its frames. The Receiver demodulates
them, reassembles and checks the file, and streams it to clients through the
media pipeline (see [receiver-media-pipeline.md](receiver-media-pipeline.md)).

```text
file -> [optional BYTE_SHIFT] -> 8-byte chunk per frame -> scramble (per-frame keystream)
     -> BPSK samples (+ simulated channel) -> gRPC TxFrame {media, media_offset, media_end,
        payload_byte_count, scrambled}
Receiver: Kalman DC tracking + decisions -> descramble -> [reverse shift] -> CRC / reassembly
     -> type detection -> WatchMedia (gRPC) and GET /api/v1/media (NDJSON)
```

## Sending a file

**At startup** (repeatable):
```powershell
.\bin\sender.exe -config configs\local.json -send examples\media\hello.txt -send examples\media\kalman.bmp
```

**At run time**, with the HTTP API on `sender.httpListen` (default
`127.0.0.1:8081`):
```powershell
curl.exe -X POST --data-binary "@examples\media\tone.wav" "http://127.0.0.1:8081/api/v1/transfers?name=tone.wav"
curl.exe http://127.0.0.1:8081/api/v1/transfers    # active, queued, recent, bytesPerSecond
```

The POST query takes `name` (required for type detection), plus optional
`encoding=raw|byte_shift` and `key=0..255`. The media type comes from the
`Content-Type` header, or from the file extension when the header is missing
or generic. Files are queued and sent one after another, up to 1 MiB each.
Progress also appears as `TxEvent`s on `WatchTxEvents`.

**Receiving:** `GET http://127.0.0.1:8082/api/v1/media` streams one JSON event
per frame, with base64 `data`, `offset`, `detected_content_type`, and on the
last frame `end_of_stream`, `checksum_valid` and `message` (`complete` or
`checksum mismatch`).

## Link rate

Each 512-sample frame at 8 samples/symbol carries 64 bits, which is 8 bytes.
At 48 kHz that is 93.75 frames/s, or **750 B/s**.

| File | Size | Time to send |
|---|---|---|
| `examples/media/hello.txt` | 103 B | instant |
| `examples/media/tone.wav` (8 kHz 8-bit PCM) | 8,044 B | ~11 s |
| `examples/media/kalman.bmp` (64×48 24-bit) | 9,270 B | ~12 s |

`go run ./cmd/mediagen` regenerates these files.

## Behaviour on a noisy channel

- **Use uncompressed formats** (text, PCM WAV, BMP). A bit error then becomes
  one wrong character, a click, or one off-colour pixel. PNG, JPEG and MP3
  usually become undecodable after a single error.
- **Headers can be damaged too.** A damaged BMP or WAV header can make a
  normal viewer or player refuse the file, even though most of the pixels or
  samples are fine.
- **A damaged file is still delivered.** It arrives with
  `checksum_valid=false` / `checksum mismatch`, and the signal stream keeps
  running for the next transfer. (Before this change, a CRC mismatch tore down
  the whole gRPC stream.)
- **A reconnect restarts the file.** A new stream is a sequence gap, which
  aborts the partial transfer on the Receiver, so the Sender begins that file
  again at offset 0.

## Verified live

Three servers on one PC, with each received file compared to the original:
- **Clean channel** (noise σ 0.30): text, BMP and WAV all byte-for-byte
  identical, CRC OK, types detected as text/plain, image/bmp and audio/wav.
- **Impaired channel** (`local-impaired.json`): all three delivered and
  flagged `checksum mismatch`, with 0 stream disconnects. See
  [ml-policy.md](ml-policy.md) for the BER comparison and the images.
