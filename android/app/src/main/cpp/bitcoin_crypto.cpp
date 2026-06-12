#include <jni.h>
#include <android/log.h>
#include <secp256k1.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#define LOG_TAG "BitcoinCrypto"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {

using Bytes20 = std::array<uint8_t, 20>;
using Bytes32 = std::array<uint8_t, 32>;

secp256k1_context* context() {
    static std::once_flag once;
    static secp256k1_context* value = nullptr;
    std::call_once(once, [] {
        value = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    });
    return value;
}

constexpr uint32_t rotr(uint32_t value, int bits) {
    return (value >> bits) | (value << (32 - bits));
}

void sha256(const uint8_t* data, size_t length, uint8_t output[32]) {
    static constexpr uint32_t k[64] = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
        0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
        0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
        0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    };

    uint32_t state[8] = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    };

    const uint64_t bitLength = static_cast<uint64_t>(length) * 8;
    const size_t paddedLength = ((length + 9 + 63) / 64) * 64;
    std::vector<uint8_t> message(paddedLength, 0);
    std::memcpy(message.data(), data, length);
    message[length] = 0x80;
    for (int i = 0; i < 8; ++i) {
        message[paddedLength - 1 - i] = static_cast<uint8_t>(bitLength >> (i * 8));
    }

    for (size_t offset = 0; offset < paddedLength; offset += 64) {
        uint32_t w[64];
        for (int i = 0; i < 16; ++i) {
            const uint8_t* p = message.data() + offset + i * 4;
            w[i] = (static_cast<uint32_t>(p[0]) << 24) |
                   (static_cast<uint32_t>(p[1]) << 16) |
                   (static_cast<uint32_t>(p[2]) << 8) | p[3];
        }
        for (int i = 16; i < 64; ++i) {
            const uint32_t s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
            const uint32_t s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }

        uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
        uint32_t e = state[4], f = state[5], g = state[6], h = state[7];
        for (int i = 0; i < 64; ++i) {
            const uint32_t s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
            const uint32_t ch = (e & f) ^ (~e & g);
            const uint32_t temp1 = h + s1 + ch + k[i] + w[i];
            const uint32_t s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
            const uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            const uint32_t temp2 = s0 + maj;
            h = g; g = f; f = e; e = d + temp1;
            d = c; c = b; b = a; a = temp1 + temp2;
        }
        state[0] += a; state[1] += b; state[2] += c; state[3] += d;
        state[4] += e; state[5] += f; state[6] += g; state[7] += h;
    }

    for (int i = 0; i < 8; ++i) {
        output[i * 4] = static_cast<uint8_t>(state[i] >> 24);
        output[i * 4 + 1] = static_cast<uint8_t>(state[i] >> 16);
        output[i * 4 + 2] = static_cast<uint8_t>(state[i] >> 8);
        output[i * 4 + 3] = static_cast<uint8_t>(state[i]);
    }
}

constexpr uint32_t rol(uint32_t value, int bits) {
    return (value << bits) | (value >> (32 - bits));
}

uint32_t ripemdFunction(int round, uint32_t x, uint32_t y, uint32_t z) {
    if (round < 16) return x ^ y ^ z;
    if (round < 32) return (x & y) | (~x & z);
    if (round < 48) return (x | ~y) ^ z;
    if (round < 64) return (x & z) | (y & ~z);
    return x ^ (y | ~z);
}

void ripemd160(const uint8_t* data, size_t length, uint8_t output[20]) {
    static constexpr uint8_t r[80] = {
        0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
        7,4,13,1,10,6,15,3,12,0,9,5,2,14,11,8,
        3,10,14,4,9,15,8,1,2,7,0,6,13,11,5,12,
        1,9,11,10,0,8,12,4,13,3,7,15,14,5,6,2,
        4,0,5,9,7,12,2,10,14,1,3,8,11,6,15,13
    };
    static constexpr uint8_t rp[80] = {
        5,14,7,0,9,2,11,4,13,6,15,8,1,10,3,12,
        6,11,3,7,0,13,5,10,14,15,8,12,4,9,1,2,
        15,5,1,3,7,14,6,9,11,8,12,2,10,0,4,13,
        8,6,4,1,3,11,15,0,5,12,2,13,9,7,10,14,
        12,15,10,4,1,5,8,7,6,2,13,14,0,3,9,11
    };
    static constexpr uint8_t s[80] = {
        11,14,15,12,5,8,7,9,11,13,14,15,6,7,9,8,
        7,6,8,13,11,9,7,15,7,12,15,9,11,7,13,12,
        11,13,6,7,14,9,13,15,14,8,13,6,5,12,7,5,
        11,12,14,15,14,15,9,8,9,14,5,6,8,6,5,12,
        9,15,5,11,6,8,13,12,5,12,13,14,11,8,5,6
    };
    static constexpr uint8_t sp[80] = {
        8,9,9,11,13,15,15,5,7,7,8,11,14,14,12,6,
        9,13,15,7,12,8,9,11,7,7,12,7,6,15,13,11,
        9,7,15,11,8,6,6,14,12,13,5,14,13,13,7,5,
        15,5,8,11,14,14,6,14,6,9,12,9,12,5,15,8,
        8,5,12,9,12,5,14,6,8,13,6,5,15,13,11,11
    };
    static constexpr uint32_t k[5] = {
        0x00000000, 0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xa953fd4e
    };
    static constexpr uint32_t kp[5] = {
        0x50a28be6, 0x5c4dd124, 0x6d703ef3, 0x7a6d76e9, 0x00000000
    };

    const uint64_t bitLength = static_cast<uint64_t>(length) * 8;
    const size_t paddedLength = ((length + 9 + 63) / 64) * 64;
    std::vector<uint8_t> message(paddedLength, 0);
    std::memcpy(message.data(), data, length);
    message[length] = 0x80;
    for (int i = 0; i < 8; ++i) {
        message[paddedLength - 8 + i] = static_cast<uint8_t>(bitLength >> (i * 8));
    }

    uint32_t h0 = 0x67452301, h1 = 0xefcdab89, h2 = 0x98badcfe;
    uint32_t h3 = 0x10325476, h4 = 0xc3d2e1f0;
    for (size_t offset = 0; offset < paddedLength; offset += 64) {
        uint32_t x[16];
        for (int i = 0; i < 16; ++i) {
            const uint8_t* p = message.data() + offset + i * 4;
            x[i] = p[0] | (static_cast<uint32_t>(p[1]) << 8) |
                   (static_cast<uint32_t>(p[2]) << 16) |
                   (static_cast<uint32_t>(p[3]) << 24);
        }

        uint32_t a = h0, b = h1, c = h2, d = h3, e = h4;
        uint32_t ap = h0, bp = h1, cp = h2, dp = h3, ep = h4;
        for (int i = 0; i < 80; ++i) {
            uint32_t t = rol(a + ripemdFunction(i, b, c, d) + x[r[i]] + k[i / 16], s[i]) + e;
            a = e; e = d; d = rol(c, 10); c = b; b = t;

            const int mirroredRound = 79 - i;
            t = rol(ap + ripemdFunction(mirroredRound, bp, cp, dp) + x[rp[i]] + kp[i / 16], sp[i]) + ep;
            ap = ep; ep = dp; dp = rol(cp, 10); cp = bp; bp = t;
        }
        const uint32_t t = h1 + c + dp;
        h1 = h2 + d + ep;
        h2 = h3 + e + ap;
        h3 = h4 + a + bp;
        h4 = h0 + b + cp;
        h0 = t;
    }

    const uint32_t state[5] = {h0, h1, h2, h3, h4};
    for (int i = 0; i < 5; ++i) {
        output[i * 4] = static_cast<uint8_t>(state[i]);
        output[i * 4 + 1] = static_cast<uint8_t>(state[i] >> 8);
        output[i * 4 + 2] = static_cast<uint8_t>(state[i] >> 16);
        output[i * 4 + 3] = static_cast<uint8_t>(state[i] >> 24);
    }
}

Bytes20 hash160(const uint8_t* data, size_t length) {
    uint8_t sha[32];
    Bytes20 result{};
    sha256(data, length, sha);
    ripemd160(sha, sizeof(sha), result.data());
    return result;
}

bool add256(Bytes32& value, const Bytes32& increment) {
    int carry = 0;
    for (int i = 31; i >= 0; --i) {
        const int sum = value[i] + increment[i] + carry;
        value[i] = static_cast<uint8_t>(sum);
        carry = sum >> 8;
    }
    return carry == 0;
}

bool readBytes32(JNIEnv* env, jbyteArray source, Bytes32& destination) {
    if (source == nullptr || env->GetArrayLength(source) != 32) return false;
    env->GetByteArrayRegion(source, 0, 32, reinterpret_cast<jbyte*>(destination.data()));
    return !env->ExceptionCheck();
}

std::vector<Bytes20> readTargets(JNIEnv* env, jobjectArray source) {
    std::vector<Bytes20> targets;
    if (source == nullptr) return targets;
    const jsize count = env->GetArrayLength(source);
    targets.reserve(count);
    for (jsize i = 0; i < count; ++i) {
        auto item = static_cast<jbyteArray>(env->GetObjectArrayElement(source, i));
        if (item != nullptr && env->GetArrayLength(item) == 20) {
            Bytes20 target{};
            env->GetByteArrayRegion(item, 0, 20, reinterpret_cast<jbyte*>(target.data()));
            targets.push_back(target);
        }
        env->DeleteLocalRef(item);
    }
    return targets;
}

bool matches(const Bytes20& candidate, const std::vector<Bytes20>& targets) {
    return std::find(targets.begin(), targets.end(), candidate) != targets.end();
}

int serializeAndMatch(
    const secp256k1_pubkey& publicKey,
    int compressionMode,
    const std::vector<Bytes20>& targets
) {
    uint8_t serialized[65];
    size_t length;

    if (compressionMode == 0 || compressionMode == 2) {
        length = 33;
        secp256k1_ec_pubkey_serialize(
            context(), serialized, &length, &publicKey, SECP256K1_EC_COMPRESSED);
        if (matches(hash160(serialized, length), targets)) return 1;
    }
    if (compressionMode == 1 || compressionMode == 2) {
        length = 65;
        secp256k1_ec_pubkey_serialize(
            context(), serialized, &length, &publicKey, SECP256K1_EC_UNCOMPRESSED);
        if (matches(hash160(serialized, length), targets)) return 2;
    }
    return 0;
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_br_net_mantovani_bitfinder_NativeCrypto_selfTest(
    JNIEnv*, jobject) {
    const uint8_t expectedCompressed[20] = {
        0x75,0x1e,0x76,0xe8,0x19,0x91,0x96,0xd4,0x54,0x94,
        0x1c,0x45,0xd1,0xb3,0xa3,0x23,0xf1,0x43,0x3b,0xd6
    };
    const uint8_t expectedUncompressed[20] = {
        0x91,0xb2,0x4b,0xf9,0xf5,0x28,0x85,0x32,0x96,0x0a,
        0xc6,0x87,0xab,0xb0,0x35,0x12,0x7b,0x1d,0x28,0xa5
    };
    Bytes32 key{};
    key[31] = 1;
    secp256k1_pubkey publicKey;
    if (!secp256k1_ec_pubkey_create(context(), &publicKey, key.data())) return JNI_FALSE;

    uint8_t serialized[65];
    size_t length = 33;
    secp256k1_ec_pubkey_serialize(
        context(), serialized, &length, &publicKey, SECP256K1_EC_COMPRESSED);
    const auto compressed = hash160(serialized, length);
    length = 65;
    secp256k1_ec_pubkey_serialize(
        context(), serialized, &length, &publicKey, SECP256K1_EC_UNCOMPRESSED);
    const auto uncompressed = hash160(serialized, length);
    return std::memcmp(compressed.data(), expectedCompressed, 20) == 0 &&
           std::memcmp(uncompressed.data(), expectedUncompressed, 20) == 0;
}

extern "C" JNIEXPORT jint JNICALL
Java_br_net_mantovani_bitfinder_NativeCrypto_searchBatchNative(
    JNIEnv* env,
    jobject,
    jbyteArray startKeyBytes,
    jint count,
    jbyteArray strideBytes,
    jint compressionMode,
    jobjectArray targetHashes,
    jbyteArray foundKeyBytes,
    jintArray foundCompressionArray,
    jbyteArray nextKeyBytes) {
    if (count <= 0 || compressionMode < 0 || compressionMode > 2) return -1;

    Bytes32 currentKey{};
    Bytes32 stride{};
    if (!readBytes32(env, startKeyBytes, currentKey) ||
        !readBytes32(env, strideBytes, stride)) {
        return -1;
    }
    const auto targets = readTargets(env, targetHashes);
    if (targets.empty()) return -1;

    secp256k1_pubkey currentPoint;
    secp256k1_pubkey stridePoint;
    if (!secp256k1_ec_pubkey_create(context(), &currentPoint, currentKey.data()) ||
        !secp256k1_ec_pubkey_create(context(), &stridePoint, stride.data())) {
        return -1;
    }

    int checked = 0;
    for (; checked < count; ++checked) {
        const int matchType = serializeAndMatch(currentPoint, compressionMode, targets);
        if (matchType != 0) {
            env->SetByteArrayRegion(
                foundKeyBytes, 0, 32, reinterpret_cast<const jbyte*>(currentKey.data()));
            const jint value = matchType;
            env->SetIntArrayRegion(foundCompressionArray, 0, 1, &value);
            ++checked;
            break;
        }

        if (!add256(currentKey, stride)) {
            ++checked;
            break;
        }
        const secp256k1_pubkey* inputs[2] = {&currentPoint, &stridePoint};
        secp256k1_pubkey nextPoint;
        if (!secp256k1_ec_pubkey_combine(context(), &nextPoint, inputs, 2)) {
            ++checked;
            break;
        }
        currentPoint = nextPoint;
    }

    env->SetByteArrayRegion(
        nextKeyBytes, 0, 32, reinterpret_cast<const jbyte*>(currentKey.data()));
    return checked;
}
