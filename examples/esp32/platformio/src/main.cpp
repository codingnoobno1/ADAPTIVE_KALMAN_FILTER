// ESP32 file sender for the Kalman BPSK lab.
//
// Sends files from the ESP32's LittleFS flash to the Receiver (Laptop 2) as
// binary protobuf TxFrames over HTTP (POST /api/v1/frames). Frames use the same
// contract as the Go Sender (lib/lk_media): 8 bytes per 512-sample frame,
// scrambled, CRC-checked, so the Receiver reassembles and streams the file to
// every client (GET :8082/api/v1/media, WatchMedia, the Flutter app).
//
// Put files in platformio/data/ and upload them with `pio run -t uploadfs`.
// Do not run the Go Sender against the same Receiver at the same time: the
// Receiver tracks one signal stream, and two interleaved streams look like
// sequence gaps that abort transfers.
#include <Arduino.h>
#include <HTTPClient.h>
#include <LittleFS.h>
#include <WiFi.h>
#include <pb_encode.h>

#include "lk_media.h"

// ---- configuration --------------------------------------------------------
// Copy credentials into a private header for a real deployment.
static const char *kSsid = "YOUR_WIFI";
static const char *kPassword = "YOUR_PASSWORD";
static const char *kReceiverUrl = "http://192.168.1.12:8082/api/v1/frames";
static const char *kFiles[] = {"/hello.txt", "/kalman.bmp", "/tone.wav"};
static const float kNoiseStddev = 0.0f;       // simulated channel noise; try 1.5-2.5
static const uint32_t kRepeatDelayMs = 10000; // pause before sending the files again
static const int kMaxRetries = 3;
// ---------------------------------------------------------------------------

static const lk_frame_config kFrameConfig = {"esp32-demo", 8000, 8, 512, 1.0f, kNoiseStddev};

static HTTPClient http;
static uint64_t streamId = 0;
static uint64_t sequenceNumber = 0;
static uint32_t transferCounter = 0;
// Large structs live in static storage, not on the 8 KB loop-task stack.
static livekalman_rx_v1_TxFrame frame;
static uint8_t encoded[3072];

static uint32_t hwRandom() { return esp_random(); }

static bool postFrame() {
  pb_ostream_t os = pb_ostream_from_buffer(encoded, sizeof(encoded));
  if (!pb_encode(&os, livekalman_rx_v1_TxFrame_fields, &frame)) {
    Serial.printf("encode failed: %s\n", PB_GET_ERROR(&os));
    return false;
  }
  for (int attempt = 1; attempt <= kMaxRetries; ++attempt) {
    int status = http.POST(encoded, os.bytes_written);
    if (status == 200) return true;
    // A retry after a lost reply can reach the Receiver twice; it treats the
    // duplicate as a gap and aborts the transfer, which the next file recovers.
    Serial.printf("frame %llu: HTTP %d (attempt %d)\n", frame.sequence, status, attempt);
    http.end();
    delay(200 * attempt);
    http.begin(kReceiverUrl);
    http.addHeader("Content-Type", "application/x-protobuf");
  }
  return false;
}

static bool sendFile(const char *path) {
  File f = LittleFS.open(path, "r");
  if (!f) {
    Serial.printf("missing %s (upload it with: pio run -t uploadfs)\n", path);
    return false;
  }
  // Pass 1: CRC of the original bytes, carried in every frame's descriptor.
  uint8_t buf[512];
  uint32_t crc = 0;
  size_t size = 0;
  while (size_t n = f.read(buf, sizeof(buf))) {
    crc = lk_crc32_update(crc, buf, n);
    size += n;
  }
  if (size == 0) {
    Serial.printf("%s is empty\n", path);
    return false;
  }
  char id[40];
  snprintf(id, sizeof(id), "esp32-%08lx-%lu", (unsigned long)(uint32_t)streamId, (unsigned long)++transferCounter);
  lk_transfer t;
  lk_transfer_init(&t, path, id, size, crc);
  const size_t cap = lk_frame_capacity(&kFrameConfig);
  Serial.printf("sending %s: %u bytes, crc32 %08lx, %s, %u frames\n", t.file_name, (unsigned)size, (unsigned long)crc,
                t.content_type, (unsigned)((size + cap - 1) / cap));

  // Pass 2: one frame per chunk.
  f.seek(0);
  const uint32_t started = millis();
  uint8_t chunk[64];
  for (size_t offset = 0; offset < size;) {
    size_t n = f.read(chunk, cap);
    if (n == 0) break;
    const bool end = offset + n >= size;
    if (lk_build_frame(&frame, &kFrameConfig, streamId, ++sequenceNumber, esp_timer_get_time(), &t, chunk, n, offset, end, hwRandom) != 0 ||
        !postFrame()) {
      Serial.printf("aborting %s at byte %u\n", t.file_name, (unsigned)offset);
      f.close();
      return false;
    }
    offset += n;
  }
  f.close();
  const float secs = (millis() - started) / 1000.0f;
  Serial.printf("sent %s in %.1f s (%.0f B/s)\n", t.file_name, secs, size / (secs > 0 ? secs : 1));
  return true;
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(kSsid, kPassword);
  while (WiFi.status() != WL_CONNECTED) delay(250);
  Serial.printf("Wi-Fi connected, IP %s\n", WiFi.localIP().toString().c_str());
  if (!LittleFS.begin()) Serial.println("LittleFS mount failed; run: pio run -t uploadfs");
  // A new random stream id per boot tells the Receiver this is a new stream.
  streamId = (((uint64_t)esp_random() << 32) | esp_random()) | 1;
  http.setReuse(true);  // keep-alive: one TCP connection for all frames
  http.begin(kReceiverUrl);
  http.addHeader("Content-Type", "application/x-protobuf");
}

void loop() {
  for (const char *path : kFiles) {
    sendFile(path);
    delay(1000);
  }
  delay(kRepeatDelayMs);
}
