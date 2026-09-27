// lk_media: portable C (no Arduino) helpers that turn file bytes into the
// livekalman.rx.v1.TxFrame contract used by the Go Sender. The Receiver cannot
// tell a frame built here from one sent by server/sender:
//   - 8 payload bytes per 512-sample frame at 8 samples/symbol (LSB first),
//   - payload XORed with the per-frame keystream of shared/dsp.Scramble,
//   - reference_bits = the transmitted (scrambled) bits,
//   - a MediaDescriptor with CRC-32 (IEEE) of the original file on every frame.
// The same code is compiled on a PC by examples/esp32/hosttest and checked
// against the real Go Receiver.
#ifndef LK_MEDIA_H
#define LK_MEDIA_H

#include <stddef.h>
#include <stdint.h>

#include "rx/v1/receiver.pb.h"

#ifdef __cplusplus
extern "C" {
#endif

// Returns 32 random bits (esp_random() on the ESP32).
typedef uint32_t (*lk_random_fn)(void);

typedef struct {
    const char *run_id;
    uint32_t sample_rate_hz;      // e.g. 8000
    uint32_t samples_per_symbol;  // 8 matches the Go sender
    uint32_t samples_per_frame;   // <= 512 (receiver.options max_count)
    float amplitude;              // BPSK level, e.g. 1.0
    float noise_stddev;           // simulated AWGN added on the device, 0 = none
} lk_frame_config;

// Describes one file transfer. Fill it with lk_transfer_init.
typedef struct {
    char transfer_id[40];
    char file_name[64];
    char content_type[48];
    livekalman_common_v1_MediaType media_type;
    uint64_t total_size;
    uint32_t crc32;
} lk_transfer;

// Payload bytes one frame carries (8 for 512 samples at 8 samples/symbol).
size_t lk_frame_capacity(const lk_frame_config *cfg);

// Incremental CRC-32 (IEEE, same as Go's crc32.ChecksumIEEE). Start with 0.
uint32_t lk_crc32_update(uint32_t crc, const uint8_t *data, size_t len);

// XOR buf with the per-frame keystream of shared/dsp.Scramble. Self-inverse.
void lk_scramble(uint8_t *buf, size_t len, uint64_t sequence);

// Sets name, id, size, CRC and a media type/content type from the extension.
void lk_transfer_init(lk_transfer *t, const char *file_name, const char *transfer_id, uint64_t total_size, uint32_t crc32);

// Builds one frame. With t == NULL it is an idle frame of random bits.
// Otherwise chunk/chunk_len (<= lk_frame_capacity) are the next file bytes at
// byte offset `offset`; set `end` on the last chunk. Returns 0 on success.
int lk_build_frame(livekalman_rx_v1_TxFrame *frame, const lk_frame_config *cfg, uint64_t stream_id, uint64_t sequence,
                   uint64_t capture_timestamp_us, const lk_transfer *t, const uint8_t *chunk, size_t chunk_len,
                   uint64_t offset, int end, lk_random_fn rnd);

#ifdef __cplusplus
}
#endif

#endif
