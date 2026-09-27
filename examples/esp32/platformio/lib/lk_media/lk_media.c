#include "lk_media.h"

#include <ctype.h>
#include <math.h>
#include <string.h>

size_t lk_frame_capacity(const lk_frame_config *cfg) {
    if (cfg->samples_per_symbol == 0) return 0;
    return (cfg->samples_per_frame / cfg->samples_per_symbol) / 8;
}

uint32_t lk_crc32_update(uint32_t crc, const uint8_t *data, size_t len) {
    crc = ~crc;
    for (size_t i = 0; i < len; ++i) {
        crc ^= data[i];
        for (int b = 0; b < 8; ++b) crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}

void lk_scramble(uint8_t *buf, size_t len, uint64_t sequence) {
    uint32_t x = (uint32_t)((sequence * 0x9E3779B97F4A7C15ull) >> 32) | 1u;
    for (size_t i = 0; i < len; ++i) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        buf[i] ^= (uint8_t)x;
    }
}

static void copy_str(char *dst, size_t cap, const char *src) {
    size_t n = strlen(src);
    if (n >= cap) n = cap - 1;
    memcpy(dst, src, n);
    dst[n] = 0;
}

static int ext_is(const char *name, const char *ext) {
    const char *dot = strrchr(name, '.');
    if (!dot) return 0;
    for (++dot; *dot && *ext; ++dot, ++ext)
        if (tolower((unsigned char)*dot) != *ext) return 0;
    return *dot == 0 && *ext == 0;
}

void lk_transfer_init(lk_transfer *t, const char *file_name, const char *transfer_id, uint64_t total_size, uint32_t crc32) {
    memset(t, 0, sizeof(*t));
    const char *base = strrchr(file_name, '/');
    copy_str(t->file_name, sizeof(t->file_name), base ? base + 1 : file_name);
    copy_str(t->transfer_id, sizeof(t->transfer_id), transfer_id);
    t->total_size = total_size;
    t->crc32 = crc32;
    static const struct { const char *ext, *type; livekalman_common_v1_MediaType kind; } table[] = {
        {"txt", "text/plain; charset=utf-8", livekalman_common_v1_MediaType_MEDIA_TYPE_TEXT},
        {"md", "text/markdown", livekalman_common_v1_MediaType_MEDIA_TYPE_TEXT},
        {"csv", "text/csv", livekalman_common_v1_MediaType_MEDIA_TYPE_TEXT},
        {"json", "application/json", livekalman_common_v1_MediaType_MEDIA_TYPE_TEXT},
        {"bmp", "image/bmp", livekalman_common_v1_MediaType_MEDIA_TYPE_IMAGE},
        {"png", "image/png", livekalman_common_v1_MediaType_MEDIA_TYPE_IMAGE},
        {"jpg", "image/jpeg", livekalman_common_v1_MediaType_MEDIA_TYPE_IMAGE},
        {"gif", "image/gif", livekalman_common_v1_MediaType_MEDIA_TYPE_IMAGE},
        {"wav", "audio/wav", livekalman_common_v1_MediaType_MEDIA_TYPE_AUDIO},
        {"mp3", "audio/mpeg", livekalman_common_v1_MediaType_MEDIA_TYPE_AUDIO},
        {"ogg", "audio/ogg", livekalman_common_v1_MediaType_MEDIA_TYPE_AUDIO},
    };
    copy_str(t->content_type, sizeof(t->content_type), "application/octet-stream");
    t->media_type = livekalman_common_v1_MediaType_MEDIA_TYPE_BINARY;
    for (size_t i = 0; i < sizeof(table) / sizeof(table[0]); ++i) {
        if (ext_is(t->file_name, table[i].ext)) {
            copy_str(t->content_type, sizeof(t->content_type), table[i].type);
            t->media_type = table[i].kind;
            break;
        }
    }
}

// Standard normal sample via Box-Muller.
static float gaussian(lk_random_fn rnd) {
    double u1 = ((double)rnd() + 1.0) / 4294967297.0;  // (0, 1]
    double u2 = (double)rnd() / 4294967296.0;
    return (float)(sqrt(-2.0 * log(u1)) * cos(6.283185307179586 * u2));
}

int lk_build_frame(livekalman_rx_v1_TxFrame *frame, const lk_frame_config *cfg, uint64_t stream_id, uint64_t sequence,
                   uint64_t capture_timestamp_us, const lk_transfer *t, const uint8_t *chunk, size_t chunk_len,
                   uint64_t offset, int end, lk_random_fn rnd) {
    const uint32_t sps = cfg->samples_per_symbol;
    if (sps == 0 || cfg->samples_per_frame % sps != 0 || cfg->samples_per_frame > sizeof(frame->samples) / sizeof(frame->samples[0]))
        return -1;
    const uint32_t symbols = cfg->samples_per_frame / sps;
    const size_t ref_bytes = (symbols + 7) / 8;
    if (ref_bytes > sizeof(frame->reference_bits.bytes) || chunk_len > lk_frame_capacity(cfg) || stream_id == 0 || sequence == 0)
        return -1;

    *frame = (livekalman_rx_v1_TxFrame)livekalman_rx_v1_TxFrame_init_zero;
    copy_str(frame->run_id, sizeof(frame->run_id), cfg->run_id);
    frame->stream_id = stream_id;
    frame->sequence = sequence;
    frame->first_sample_index = (sequence - 1) * cfg->samples_per_frame;
    frame->sample_rate_hz = cfg->sample_rate_hz;
    frame->samples_per_symbol = sps;
    frame->capture_timestamp_us = capture_timestamp_us ? capture_timestamp_us : 1;
    frame->config_version = 1;
    frame->sample_format = livekalman_common_v1_SampleFormat_SAMPLE_FORMAT_FLOAT32_LE;

    // Payload (scrambled) in the first bytes, random bits after it.
    uint8_t bits[sizeof(frame->reference_bits.bytes)];
    memset(bits, 0, sizeof(bits));
    for (size_t i = 0; i < ref_bytes; ++i) bits[i] = (uint8_t)rnd();
    if (t && chunk_len) {
        memcpy(bits, chunk, chunk_len);
        lk_scramble(bits, chunk_len, sequence);
    }
    if (symbols % 8) bits[ref_bytes - 1] &= (uint8_t)((1u << (symbols % 8)) - 1u);

    for (uint32_t s = 0; s < symbols; ++s) {
        const float level = (bits[s / 8] >> (s % 8)) & 1u ? cfg->amplitude : -cfg->amplitude;
        for (uint32_t j = 0; j < sps; ++j) {
            float v = level;
            if (cfg->noise_stddev > 0) v += cfg->noise_stddev * gaussian(rnd);
            frame->samples[s * sps + j] = v;
        }
    }
    frame->samples_count = (pb_size_t)(symbols * sps);
    frame->reference_bits.size = (pb_size_t)ref_bytes;
    memcpy(frame->reference_bits.bytes, bits, ref_bytes);

    if (t) {
        frame->has_media = true;
        livekalman_common_v1_MediaDescriptor *m = &frame->media;
        copy_str(m->transfer_id, sizeof(m->transfer_id), t->transfer_id);
        copy_str(m->file_name, sizeof(m->file_name), t->file_name);
        copy_str(m->content_type_hint, sizeof(m->content_type_hint), t->content_type);
        m->media_type_hint = t->media_type;
        m->total_size = t->total_size;
        m->crc32 = t->crc32;
        m->modulation = livekalman_common_v1_Modulation_MODULATION_BPSK;
        m->encoding = livekalman_common_v1_PayloadEncoding_PAYLOAD_ENCODING_RAW;
        frame->media_offset = offset;
        frame->media_end = end ? true : false;
        frame->payload_byte_count = (uint32_t)chunk_len;
        frame->scrambled = true;
    }
    return 0;
}
