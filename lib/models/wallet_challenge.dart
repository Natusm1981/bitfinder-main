class WalletChallenge {
  final int id;
  final String name;
  final String btcAddress;
  final String keyspace;
  final String privateKey;
  final String privateKeyDecimal;
  final int bits;
  final bool solved;
  final String? solvedDate;
  final bool compressed;
  final String notes;

  WalletChallenge({
    required this.id,
    required this.name,
    required this.btcAddress,
    required this.keyspace,
    required this.privateKey,
    required this.privateKeyDecimal,
    required this.bits,
    required this.solved,
    this.solvedDate,
    required this.compressed,
    required this.notes,
  });

  factory WalletChallenge.fromJson(Map<String, dynamic> json) {
    return WalletChallenge(
      id: json['id'] as int,
      name: json['name'] as String,
      btcAddress: json['btcAddress'] as String,
      keyspace: json['keyspace'] as String,
      privateKey: json['privateKey'] as String? ?? '',
      privateKeyDecimal: json['privateKeyDecimal'] as String? ?? '',
      bits: json['bits'] as int,
      solved: json['solved'] as bool,
      solvedDate: json['solvedDate'] as String?,
      compressed: json['compressed'] as bool,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'btcAddress': btcAddress,
      'keyspace': keyspace,
      'privateKey': privateKey,
      'privateKeyDecimal': privateKeyDecimal,
      'bits': bits,
      'solved': solved,
      'solvedDate': solvedDate,
      'compressed': compressed,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return '$name - $btcAddress (${solved ? "Solved" : "Unsolved"})';
  }
}

class WalletChallengeCollection {
  final String version;
  final String description;
  final String lastUpdated;
  final List<WalletChallenge> challenges;
  final Map<String, dynamic> metadata;

  WalletChallengeCollection({
    required this.version,
    required this.description,
    required this.lastUpdated,
    required this.challenges,
    required this.metadata,
  });

  factory WalletChallengeCollection.fromJson(Map<String, dynamic> json) {
    final challengesList =
        (json['challenges'] as List<dynamic>)
            .map((e) => WalletChallenge.fromJson(e as Map<String, dynamic>))
            .toList();

    return WalletChallengeCollection(
      version: json['version'] as String,
      description: json['description'] as String,
      lastUpdated: json['lastUpdated'] as String,
      challenges: challengesList,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}
