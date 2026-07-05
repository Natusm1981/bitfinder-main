/// Compression type for Bitcoin addresses
enum PointCompressionType { compressed, uncompressed, both }

/// Search mode type
enum SearchMode { sequential, random }

/// Represents a Bitcoin address target to search for
class KeySearchTarget {
  final String address;
  final List<int> hash160; // 5 x 32-bit integers = 160 bits

  KeySearchTarget({required this.address, required this.hash160});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! KeySearchTarget) return false;

    for (int i = 0; i < 5; i++) {
      if (hash160[i] != other.hash160[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(hash160);

  Map<String, dynamic> toJson() => {'address': address, 'hash160': hash160};

  factory KeySearchTarget.fromJson(Map<String, dynamic> json) =>
      KeySearchTarget(
        address: json['address'] as String,
        hash160: List<int>.from(json['hash160'] as List),
      );
}

/// Status information during key search
class KeySearchStatus {
  final double speed; // Keys per second (in millions)
  final BigInt total; // Total keys checked
  final int totalTime; // Time in milliseconds
  final String deviceName;
  final int targets;
  final BigInt nextKey;
  final double? batteryTemperatureCelsius;
  final int thermalStatus;
  final DateTime timestamp;

  KeySearchStatus({
    required this.speed,
    required this.total,
    required this.totalTime,
    required this.deviceName,
    required this.targets,
    required this.nextKey,
    this.batteryTemperatureCelsius,
    this.thermalStatus = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get temperatureFormatted =>
      batteryTemperatureCelsius == null
          ? 'Indisponivel'
          : '${batteryTemperatureCelsius!.toStringAsFixed(1)} °C';

  String get thermalStatusFormatted {
    switch (thermalStatus) {
      case 1:
        return 'Leve';
      case 2:
        return 'Moderado';
      case 3:
        return 'Severo';
      case 4:
        return 'Critico';
      case 5:
        return 'Emergencia';
      case 6:
        return 'Desligamento';
      default:
        return 'Normal';
    }
  }

  String get speedFormatted {
    // speed está em milhões (MKey/s), então multiplicamos por 1.000.000
    final keysPerSecond = speed * 1000000;

    if (keysPerSecond >= 1000000) {
      // >= 1 milhão: mostrar em M
      final millions = keysPerSecond / 1000000;
      return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)} M key/s';
    } else if (keysPerSecond >= 1000) {
      // >= 1 mil: mostrar em K
      final thousands = keysPerSecond / 1000;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)} K key/s';
    } else if (keysPerSecond >= 1) {
      // >= 1: mostrar número inteiro
      return '${keysPerSecond.toStringAsFixed(0)} key/s';
    } else {
      return '< 1 key/s';
    }
  }

  String get totalFormatted {
    return total.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String get timeFormatted {
    int seconds = totalTime ~/ 1000;
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class TemperatureSample {
  final double celsius;
  final DateTime timestamp;

  const TemperatureSample({required this.celsius, required this.timestamp});
}

/// Result when a matching key is found
class KeySearchResult {
  final String address;
  final BigInt privateKey;
  final String publicKeyX;
  final String publicKeyY;
  final bool compressed;
  final String privateKeyWIF;
  final DateTime foundAt;
  final int? challengeId;

  KeySearchResult({
    required this.address,
    required this.privateKey,
    required this.publicKeyX,
    required this.publicKeyY,
    required this.compressed,
    required this.privateKeyWIF,
    DateTime? foundAt,
    this.challengeId,
  }) : foundAt = foundAt ?? DateTime.now();

  String get privateKeyHex =>
      privateKey.toRadixString(16).toUpperCase().padLeft(64, '0');

  String get publicKeyFormatted {
    if (compressed) {
      // For compressed keys, just show the x coordinate with prefix
      return publicKeyX;
    } else {
      return 'X: $publicKeyX\nY: $publicKeyY';
    }
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'privateKey': privateKeyHex,
    'privateKeyWIF': privateKeyWIF,
    'publicKeyX': publicKeyX,
    'publicKeyY': publicKeyY,
    'compressed': compressed,
    'foundAt': foundAt.toIso8601String(),
    if (challengeId != null) 'challengeId': challengeId,
  };

  @override
  String toString() {
    return 'Address: $address\n'
        'Private Key (Hex): $privateKeyHex\n'
        'Private Key (WIF): $privateKeyWIF\n'
        'Compressed: ${compressed ? "yes" : "no"}\n'
        'Public Key: $publicKeyFormatted';
  }
}

/// Configuration for key search run
class KeySearchConfig {
  BigInt startKey;
  BigInt nextKey;
  BigInt endKey;
  PointCompressionType compression;
  BigInt stride;
  List<KeySearchTarget> targets;
  String? resultsFile;
  int statusInterval; // milliseconds
  bool isRunning;
  SearchMode searchMode;
  int numThreads; // Number of parallel isolates
  int? challengeId;

  KeySearchConfig({
    BigInt? startKey,
    BigInt? nextKey,
    BigInt? endKey,
    this.compression = PointCompressionType.compressed,
    BigInt? stride,
    List<KeySearchTarget>? targets,
    this.resultsFile,
    this.statusInterval = 1000,
    this.isRunning = false,
    this.searchMode = SearchMode.sequential,
    this.numThreads = 1,
    this.challengeId,
  }) : startKey = startKey ?? BigInt.one,
       nextKey = nextKey ?? BigInt.one,
       endKey = endKey ?? _secp256k1N(),
       stride = stride ?? BigInt.one,
       targets = targets ?? [];

  /// secp256k1 curve order
  static BigInt _secp256k1N() {
    return BigInt.parse(
      'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
      radix: 16,
    );
  }

  KeySearchConfig copyWith({
    BigInt? startKey,
    BigInt? nextKey,
    BigInt? endKey,
    PointCompressionType? compression,
    BigInt? stride,
    List<KeySearchTarget>? targets,
    String? resultsFile,
    int? statusInterval,
    bool? isRunning,
    SearchMode? searchMode,
    int? numThreads,
    int? challengeId,
    bool clearChallengeId = false,
  }) {
    return KeySearchConfig(
      startKey: startKey ?? this.startKey,
      nextKey: nextKey ?? this.nextKey,
      endKey: endKey ?? this.endKey,
      compression: compression ?? this.compression,
      stride: stride ?? this.stride,
      targets: targets ?? this.targets,
      resultsFile: resultsFile ?? this.resultsFile,
      statusInterval: statusInterval ?? this.statusInterval,
      isRunning: isRunning ?? this.isRunning,
      searchMode: searchMode ?? this.searchMode,
      numThreads: numThreads ?? this.numThreads,
      challengeId: clearChallengeId ? null : challengeId ?? this.challengeId,
    );
  }

  Map<String, dynamic> toJson() => {
    'startKey': startKey.toString(),
    'nextKey': nextKey.toString(),
    'endKey': endKey.toString(),
    'compression': compression.index,
    'stride': stride.toString(),
    'targets': targets.map((target) => target.toJson()).toList(),
    'statusInterval': statusInterval,
    'searchMode': searchMode.index,
    'numThreads': numThreads,
    'challengeId': challengeId,
  };

  factory KeySearchConfig.fromJson(Map<String, dynamic> json) {
    final compressionIndex = json['compression'] as int? ?? 0;
    final searchModeIndex = json['searchMode'] as int? ?? 0;
    return KeySearchConfig(
      startKey: BigInt.parse(json['startKey'] as String),
      nextKey: BigInt.parse(json['nextKey'] as String),
      endKey: BigInt.parse(json['endKey'] as String),
      compression:
          PointCompressionType.values[compressionIndex.clamp(
            0,
            PointCompressionType.values.length - 1,
          )],
      stride: BigInt.parse(json['stride'] as String),
      targets:
          (json['targets'] as List<dynamic>? ?? const [])
              .map(
                (target) =>
                    KeySearchTarget.fromJson(target as Map<String, dynamic>),
              )
              .toList(),
      statusInterval: json['statusInterval'] as int? ?? 1000,
      searchMode:
          SearchMode.values[searchModeIndex.clamp(
            0,
            SearchMode.values.length - 1,
          )],
      numThreads: json['numThreads'] as int? ?? 1,
      challengeId: json['challengeId'] as int?,
    );
  }
}
