class ProcessJob {
  final String jobId;
  final String status;

  ProcessJob({required this.jobId, required this.status});

  factory ProcessJob.fromJson(Map<String, dynamic> json) {
    return ProcessJob(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
    );
  }
}

class PhotoResult {
  final String jobId;
  final String status;
  final String? imageBase64;
  final String? mimeType;
  final String? error;

  PhotoResult({
    required this.jobId,
    required this.status,
    this.imageBase64,
    this.mimeType,
    this.error,
  });

  factory PhotoResult.fromJson(Map<String, dynamic> json) {
    return PhotoResult(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      imageBase64: json['image_base64'] as String?,
      mimeType: json['mime_type'] as String?,
      error: json['error'] as String?,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'queued' || status == 'processing';
}
