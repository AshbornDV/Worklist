class WorkerDocument {
  final int? id;
  final int workerId;
  final String documentType; // 'citizenship', 'passport', 'contract', 'driving_license'
  final String filePath;
  final DateTime uploadedAt;
  final String? fileName;

  const WorkerDocument({
    this.id,
    required this.workerId,
    required this.documentType,
    required this.filePath,
    required this.uploadedAt,
    this.fileName,
  });

  WorkerDocument copyWith({
    int? id,
    int? workerId,
    String? documentType,
    String? filePath,
    DateTime? uploadedAt,
    String? fileName,
  }) =>
      WorkerDocument(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        documentType: documentType ?? this.documentType,
        filePath: filePath ?? this.filePath,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        fileName: fileName ?? this.fileName,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'worker_id': workerId,
        'document_type': documentType,
        'file_path': filePath,
        'uploaded_at': uploadedAt.toIso8601String(),
        if (fileName != null) 'file_name': fileName,
      };

  factory WorkerDocument.fromMap(Map<String, dynamic> map) => WorkerDocument(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int,
        documentType: map['document_type'] as String,
        filePath: map['file_path'] as String,
        uploadedAt: DateTime.parse(map['uploaded_at'] as String),
        fileName: map['file_name'] as String?,
      );

  String get displayName {
    switch (documentType) {
      case 'citizenship':
        return 'Citizenship';
      case 'passport':
        return 'Passport';
      case 'contract':
        return 'Contract';
      case 'driving_license':
        return 'Driving License';
      default:
        return documentType;
    }
  }
}
