class HistoryItem {
  final String jobId;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool hasResult;

  HistoryItem({
    required this.jobId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.hasResult,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      hasResult: json['has_result'] as bool? ?? false,
    );
  }
}
