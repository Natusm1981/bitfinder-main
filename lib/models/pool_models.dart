enum PoolClientStatus { connected, searching, idle, disconnected }

enum PoolRangeStatus { assigned, completed, failed }

enum PoolDistributionMode { sequential, random }

enum PoolWorkerStatus {
  disconnected,
  connecting,
  connected,
  searching,
  idle,
  completed,
}

class PoolClientInfo {
  final String id;
  final String deviceName;
  final String address;
  final PoolClientStatus status;
  final String? currentRangeId;
  final BigInt keysChecked;
  final double speed;
  final DateTime connectedAt;
  final DateTime lastSeenAt;

  const PoolClientInfo({
    required this.id,
    required this.deviceName,
    required this.address,
    required this.status,
    required this.keysChecked,
    required this.speed,
    required this.connectedAt,
    required this.lastSeenAt,
    this.currentRangeId,
  });

  PoolClientInfo copyWith({
    String? deviceName,
    PoolClientStatus? status,
    String? currentRangeId,
    BigInt? keysChecked,
    double? speed,
    DateTime? lastSeenAt,
    bool clearCurrentRangeId = false,
  }) {
    return PoolClientInfo(
      id: id,
      deviceName: deviceName ?? this.deviceName,
      address: address,
      status: status ?? this.status,
      currentRangeId:
          clearCurrentRangeId ? null : currentRangeId ?? this.currentRangeId,
      keysChecked: keysChecked ?? this.keysChecked,
      speed: speed ?? this.speed,
      connectedAt: connectedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class PoolRangeInfo {
  final String id;
  final BigInt startKey;
  final BigInt endKey;
  final BigInt keyCount;
  final PoolRangeStatus status;
  final String? assignedClientId;
  final BigInt keysChecked;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  const PoolRangeInfo({
    required this.id,
    required this.startKey,
    required this.endKey,
    required this.keyCount,
    required this.status,
    required this.keysChecked,
    required this.createdAt,
    this.assignedClientId,
    this.assignedAt,
    this.completedAt,
  });

  BigInt get totalKeys => keyCount;

  PoolRangeInfo copyWith({
    PoolRangeStatus? status,
    String? assignedClientId,
    BigInt? keysChecked,
    DateTime? assignedAt,
    DateTime? completedAt,
  }) {
    return PoolRangeInfo(
      id: id,
      startKey: startKey,
      endKey: endKey,
      keyCount: keyCount,
      status: status ?? this.status,
      assignedClientId: assignedClientId ?? this.assignedClientId,
      keysChecked: keysChecked ?? this.keysChecked,
      createdAt: createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startKey': startKey.toString(),
    'endKey': endKey.toString(),
    'keyCount': keyCount.toString(),
    'status': status.index,
    'assignedClientId': assignedClientId,
    'keysChecked': keysChecked.toString(),
    'createdAt': createdAt.toIso8601String(),
    'assignedAt': assignedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory PoolRangeInfo.fromJson(Map<String, dynamic> json) {
    return PoolRangeInfo(
      id: json['id'] as String,
      startKey: BigInt.parse(json['startKey'] as String),
      endKey: BigInt.parse(json['endKey'] as String),
      keyCount: BigInt.parse(
        json['keyCount'] as String? ??
            (BigInt.parse(json['endKey'] as String) -
                    BigInt.parse(json['startKey'] as String) +
                    BigInt.one)
                .toString(),
      ),
      status: PoolRangeStatus.values[(json['status'] as int).clamp(
        0,
        PoolRangeStatus.values.length - 1,
      )],
      assignedClientId: json['assignedClientId'] as String?,
      keysChecked: BigInt.parse(json['keysChecked'] as String? ?? '0'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      assignedAt:
          json['assignedAt'] == null
              ? null
              : DateTime.parse(json['assignedAt'] as String),
      completedAt:
          json['completedAt'] == null
              ? null
              : DateTime.parse(json['completedAt'] as String),
    );
  }
}

class PoolServerConfig {
  final BigInt startKey;
  final BigInt endKey;
  final BigInt stride;
  final int compressionIndex;
  final List<String> targets;
  final int port;
  final int batchSize;
  final PoolDistributionMode distributionMode;

  const PoolServerConfig({
    required this.startKey,
    required this.endKey,
    required this.stride,
    required this.compressionIndex,
    required this.targets,
    this.distributionMode = PoolDistributionMode.sequential,
    this.port = 40404,
    this.batchSize = 5000000,
  });

  BigInt get totalKeys =>
      endKey >= startKey ? ((endKey - startKey) ~/ stride) + BigInt.one : BigInt.zero;

  String get signature =>
      '${startKey.toRadixString(16)}:${endKey.toRadixString(16)}:${stride.toRadixString(16)}:$compressionIndex:${targets.join(',')}';

  Map<String, dynamic> toJson() => {
    'startKey': startKey.toString(),
    'endKey': endKey.toString(),
    'stride': stride.toString(),
    'compressionIndex': compressionIndex,
    'targets': targets,
    'port': port,
    'batchSize': batchSize,
    'distributionMode': distributionMode.index,
  };

  factory PoolServerConfig.fromJson(Map<String, dynamic> json) {
    final distributionModeIndex = json['distributionMode'] as int? ?? 0;
    return PoolServerConfig(
      startKey: BigInt.parse(json['startKey'] as String),
      endKey: BigInt.parse(json['endKey'] as String),
      stride: BigInt.parse(json['stride'] as String),
      compressionIndex: json['compressionIndex'] as int? ?? 0,
      targets: List<String>.from(json['targets'] as List<dynamic>? ?? const []),
      port: json['port'] as int? ?? 40404,
      batchSize: json['batchSize'] as int? ?? 5000000,
      distributionMode: PoolDistributionMode.values[distributionModeIndex.clamp(
        0,
        PoolDistributionMode.values.length - 1,
      )],
    );
  }
}
