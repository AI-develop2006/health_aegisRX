class RiskSnapshot {
  final String patientId;
  final String overallAlertLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final String recommendation;
  final int severityScore;
  final List<String> flaggedMedicines;

  RiskSnapshot({
    required this.patientId,
    required this.overallAlertLevel,
    required this.recommendation,
    required this.severityScore,
    required this.flaggedMedicines,
  });

  factory RiskSnapshot.fromJson(Map<String, dynamic> json) {
    return RiskSnapshot(
      patientId: json['patientId'] ?? '',
      overallAlertLevel: json['overallAlertLevel'] ?? 'LOW',
      recommendation: json['recommendation'] ?? '',
      severityScore: json['severityScore'] ?? 0,
      flaggedMedicines: List<String>.from(json['flaggedMedicines'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'overallAlertLevel': overallAlertLevel,
      'recommendation': recommendation,
      'severityScore': severityScore,
      'flaggedMedicines': flaggedMedicines,
    };
  }
}
