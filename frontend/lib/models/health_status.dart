class HealthStatus {
  final String status;
  final String timestamp;
  final String environment;
  final String version;
  final String? database;

  const HealthStatus({
    required this.status,
    required this.timestamp,
    required this.environment,
    required this.version,
    this.database,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      timestamp: json['timestamp'] as String? ?? '',
      environment: json['environment'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '0.0.0',
      database: json['database'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp,
      'environment': environment,
      'version': version,
      'database': database,
    };
  }
}
