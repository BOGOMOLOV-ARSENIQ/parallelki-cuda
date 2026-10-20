#pragma once
#include <cstdint>
#include <cstring>
#include <string>

#ifdef __CUDACC__
#define HD __host__ __device__
#else
#define HD
#endif

HD inline uint64_t rotl(uint64_t x, int b) {
    return (x << b) | (x >> (64 - b));
}

HD inline void sipround(uint64_t &v0, uint64_t &v1, uint64_t &v2, uint64_t &v3) {
    v0 += v1; v1 = rotl(v1, 13); v1 ^= v0; v0 = rotl(v0, 32);
    v2 += v3; v3 = rotl(v3, 16); v3 ^= v2;
    v0 += v3; v3 = rotl(v3, 21); v3 ^= v0;
    v2 += v1; v1 = rotl(v1, 17); v1 ^= v2; v2 = rotl(v2, 32);
}

HD inline uint64_t siphash24(const uint8_t *in, uint64_t len) {
    uint64_t v0 = 0x736f6d6570736575ULL;
    uint64_t v1 = 0x646f72616e646f6dULL;
    uint64_t v2 = 0x6c7967656e657261ULL;
    uint64_t v3 = 0x7465646279746573ULL;

    uint64_t b = len << 56;
    uint64_t full = len - len % 8;

    for (uint64_t i = 0; i < full; i += 8) {
        uint64_t m;
        memcpy(&m, in + i, 8);
        v3 ^= m;
        sipround(v0, v1, v2, v3);
        sipround(v0, v1, v2, v3);
        v0 ^= m;
    }

    for (uint64_t i = 0; i < len % 8; i++)
        b |= (uint64_t)in[full + i] << (8 * i);

    v3 ^= b;
    sipround(v0, v1, v2, v3);
    sipround(v0, v1, v2, v3);
    v0 ^= b;

    v2 ^= 0xff;
    sipround(v0, v1, v2, v3);
    sipround(v0, v1, v2, v3);
    sipround(v0, v1, v2, v3);
    sipround(v0, v1, v2, v3);

    return v0 ^ v1 ^ v2 ^ v3;
}

inline uint64_t siphash24(const std::string &msg) {
    return siphash24((const uint8_t *)msg.data(), msg.size());
}
