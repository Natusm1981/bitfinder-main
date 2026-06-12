package br.net.mantovani.bitfinder

object NativeCrypto {
    private var loaded = false

    init {
        loaded = try {
            System.loadLibrary("bitcoin_crypto")
            true
        } catch (_: UnsatisfiedLinkError) {
            false
        }
    }

    external fun selfTest(): Boolean

    private external fun searchBatchNative(
        startKey: ByteArray,
        count: Int,
        stride: ByteArray,
        compressionMode: Int,
        targetHashes: Array<ByteArray>,
        foundKey: ByteArray,
        foundCompression: IntArray,
        nextKey: ByteArray
    ): Int

    fun isNativeAvailable(): Boolean {
        if (!loaded) return false
        return try {
            selfTest()
        } catch (_: Throwable) {
            false
        }
    }

    fun searchBatch(
        startKey: ByteArray,
        count: Int,
        stride: ByteArray,
        compressionMode: Int,
        targetHashes: Array<ByteArray>
    ): Map<String, Any?> {
        require(startKey.size == 32) { "startKey must contain 32 bytes" }
        require(stride.size == 32) { "stride must contain 32 bytes" }
        require(count in 1..1_000_000) { "count is outside the supported range" }
        require(targetHashes.isNotEmpty()) { "At least one target is required" }
        require(targetHashes.all { it.size == 20 }) { "Targets must be HASH160 values" }

        val foundKey = ByteArray(32)
        val nextKey = ByteArray(32)
        val foundCompression = IntArray(1)
        val checked = searchBatchNative(
            startKey,
            count,
            stride,
            compressionMode,
            targetHashes,
            foundKey,
            foundCompression,
            nextKey
        )
        check(checked >= 0) { "Native batch processing failed" }

        return mapOf(
            "checked" to checked,
            "nextKey" to nextKey,
            "foundKey" to if (foundCompression[0] == 0) null else foundKey,
            "foundCompressed" to when (foundCompression[0]) {
                1 -> true
                2 -> false
                else -> null
            }
        )
    }
}
