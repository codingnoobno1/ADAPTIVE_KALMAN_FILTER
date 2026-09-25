#include <Arduino.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <pb_encode.h>
#include "receiver.pb.h"

// Copy credentials and the Laptop 2 address into a private secrets header for
// a real deployment. This example is deliberately explicit and bounded.
static const char *ssid = "YOUR_WIFI";
static const char *password = "YOUR_PASSWORD";
static const char *receiverUrl = "http://192.168.1.12:8082/api/v1/frames";
static uint64_t sequenceNumber = 0;

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) delay(250);
}

void loop() {
  livekalman_rx_v1_TxFrame frame = livekalman_rx_v1_TxFrame_init_zero;
  strlcpy(frame.run_id, "esp32-demo", sizeof(frame.run_id));
  frame.stream_id = 1;
  frame.sequence = ++sequenceNumber;
  frame.sample_rate_hz = 8000;
  frame.samples_per_symbol = 8;
  frame.capture_timestamp_us = esp_timer_get_time();
  frame.config_version = 1;
  frame.sample_format = livekalman_common_v1_SAMPLE_FORMAT_FLOAT32_LE;

  // Replace with ADC/DMA input. The alternating pattern is a transport test.
  frame.samples_count = 512;
  for (size_t i = 0; i < frame.samples_count; ++i) frame.samples[i] = ((i / 8) % 2) ? 1.0f : -1.0f;
  frame.reference_bits.size = 8;
  for (size_t i = 0; i < frame.reference_bits.size; ++i) frame.reference_bits.bytes[i] = 0xAA;

  uint8_t payload[3072];
  pb_ostream_t stream = pb_ostream_from_buffer(payload, sizeof(payload));
  if (!pb_encode(&stream, livekalman_rx_v1_TxFrame_fields, &frame)) {
    Serial.printf("encode failed: %s\n", PB_GET_ERROR(&stream));
    delay(1000); return;
  }

  HTTPClient http;
  http.begin(receiverUrl);
  http.addHeader("Content-Type", "application/x-protobuf");
  int status = http.POST(payload, stream.bytes_written);
  Serial.printf("frame=%llu status=%d reply-bytes=%d\n", sequenceNumber, status, http.getSize());
  http.end();
  delay(64);
}

