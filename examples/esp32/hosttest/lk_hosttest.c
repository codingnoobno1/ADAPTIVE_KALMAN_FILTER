// Host (PC) test for the ESP32 media code: builds the exact protobuf frames the
// ESP32 would POST, from lib/lk_media + nanopb, and writes them to a directory.
// examples/esp32/hosttest/post_frames.py then sends them to a real Receiver.
//
//   lk_hosttest <file> <out_dir> [noise_stddev]
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <pb_encode.h>

#include "lk_media.h"

static uint32_t rng_state = 20260927u;
static uint32_t host_random(void) {  // stand-in for esp_random()
    rng_state ^= rng_state << 13;
    rng_state ^= rng_state >> 17;
    rng_state ^= rng_state << 5;
    return rng_state;
}

static int self_test(void) {
    uint8_t ks[4] = {0};
    lk_scramble(ks, 4, 1);
    const uint8_t want[4] = {0x19, 0x3e, 0x3a, 0xb5};  // shared/dsp TestScrambleKnownVector
    if (memcmp(ks, want, 4) != 0) {
        fprintf(stderr, "scramble vector mismatch: %02x %02x %02x %02x\n", ks[0], ks[1], ks[2], ks[3]);
        return 1;
    }
    if (lk_crc32_update(0, (const uint8_t *)"123456789", 9) != 0xCBF43926u) {
        fprintf(stderr, "crc32 check value mismatch\n");
        return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s <file> <out_dir> [noise_stddev]\n", argv[0]);
        return 2;
    }
    if (self_test()) return 1;
    FILE *in = fopen(argv[1], "rb");
    if (!in) { perror(argv[1]); return 1; }
    fseek(in, 0, SEEK_END);
    long size = ftell(in);
    fseek(in, 0, SEEK_SET);
    uint8_t *data = malloc(size > 0 ? (size_t)size : 1);
    if (!data || fread(data, 1, (size_t)size, in) != (size_t)size) { fprintf(stderr, "read failed\n"); return 1; }
    fclose(in);

    lk_frame_config cfg = {"esp32-host", 8000, 8, 512, 1.0f, argc > 3 ? (float)atof(argv[3]) : 0.0f};
    lk_transfer t;
    // Unique per transfer, as on the device: stream id + file checksum.
    const uint64_t stream_id = 0xE5932001u;
    const uint32_t crc = lk_crc32_update(0, data, (size_t)size);
    char transfer_id[40];
    snprintf(transfer_id, sizeof(transfer_id), "esp32-%llx-%08x", (unsigned long long)stream_id, crc);
    lk_transfer_init(&t, argv[1], transfer_id, (uint64_t)size, crc);
    const size_t cap = lk_frame_capacity(&cfg);

    static livekalman_rx_v1_TxFrame frame;
    static uint8_t buf[3072];
    uint64_t seq = 0;
    for (size_t off = 0; off < (size_t)size; off += cap) {
        size_t n = (size_t)size - off < cap ? (size_t)size - off : cap;
        if (lk_build_frame(&frame, &cfg, stream_id, ++seq, 1000 + seq, &t, data + off, n, off, off + n == (size_t)size, host_random)) {
            fprintf(stderr, "build failed at offset %zu\n", off);
            return 1;
        }
        pb_ostream_t os = pb_ostream_from_buffer(buf, sizeof(buf));
        if (!pb_encode(&os, livekalman_rx_v1_TxFrame_fields, &frame)) {
            fprintf(stderr, "encode failed: %s\n", PB_GET_ERROR(&os));
            return 1;
        }
        char path[512];
        snprintf(path, sizeof(path), "%s/frame_%06llu.bin", argv[2], (unsigned long long)seq);
        FILE *out = fopen(path, "wb");
        if (!out || fwrite(buf, 1, os.bytes_written, out) != os.bytes_written) { perror(path); return 1; }
        fclose(out);
    }
    printf("%s: %ld bytes, crc32 %08x, type %s -> %llu frames (%zu bytes/frame, max encoded %zu bytes)\n",
           t.file_name, size, t.crc32, t.content_type, (unsigned long long)seq, cap, sizeof(buf));
    free(data);
    return 0;
}
