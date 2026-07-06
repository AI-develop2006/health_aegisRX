class TokenState {
  final String prescriptionId;
  final bool isDispensed;
  final String ledgerTxHash;
  final String timestamp;

  TokenState({
    required this.prescriptionId,
    required this.isDispensed,
    required this.ledgerTxHash,
    required this.timestamp,
  });

  factory TokenState.fromJson(Map<String, dynamic> json) {
    return TokenState(
      prescriptionId: json['prescriptionId'] ?? '',
      isDispensed: json['isDispensed'] ?? false,
      ledgerTxHash: json['ledgerTxHash'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescriptionId': prescriptionId,
      'isDispensed': isDispensed,
      'ledgerTxHash': ledgerTxHash,
      'timestamp': timestamp,
    };
  }
}
