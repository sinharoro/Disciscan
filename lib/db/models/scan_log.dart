class ScanLog {
  final int? id;
  final String studentId;
  final String? studentName;
  final String? grade;
  final String scanTime;
  final String scanType;
  final bool uniformComplete;
  final bool idVisible;
  final String status;
  final String? deniedReason;
  final String gate;
  final String scannedBy;

  ScanLog({
    this.id,
    required this.studentId,
    this.studentName,
    this.grade,
    required this.scanTime,
    required this.scanType,
    required this.uniformComplete,
    required this.idVisible,
    required this.status,
    this.deniedReason,
    this.gate = 'Gate A',
    this.scannedBy = 'Guard',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'grade': grade,
      'scan_time': scanTime,
      'scan_type': scanType,
      'uniform_complete': uniformComplete ? 1 : 0,
      'id_visible': idVisible ? 1 : 0,
      'status': status,
      'denied_reason': deniedReason,
      'gate': gate,
      'scanned_by': scannedBy,
    };
  }

  factory ScanLog.fromMap(Map<String, dynamic> map) {
    return ScanLog(
      id: map['id'] as int?,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String?,
      grade: map['grade'] as String?,
      scanTime: map['scan_time'] as String,
      scanType: map['scan_type'] as String,
      uniformComplete: (map['uniform_complete'] as int) == 1,
      idVisible: (map['id_visible'] as int) == 1,
      status: map['status'] as String,
      deniedReason: map['denied_reason'] as String?,
      gate: map['gate'] as String? ?? 'Gate A',
      scannedBy: map['scanned_by'] as String? ?? 'Guard',
    );
  }

  bool get isGranted => status == 'granted';
  bool get isDenied => status == 'denied';
  bool get isEntry => scanType == 'entry';
  bool get isExit => scanType == 'exit';

  String get formattedTime {
    final dt = DateTime.parse(scanTime);
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  ScanLog copyWith({
    int? id,
    String? studentId,
    String? studentName,
    String? grade,
    String? scanTime,
    String? scanType,
    bool? uniformComplete,
    bool? idVisible,
    String? status,
    String? deniedReason,
    String? gate,
    String? scannedBy,
  }) {
    return ScanLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      grade: grade ?? this.grade,
      scanTime: scanTime ?? this.scanTime,
      scanType: scanType ?? this.scanType,
      uniformComplete: uniformComplete ?? this.uniformComplete,
      idVisible: idVisible ?? this.idVisible,
      status: status ?? this.status,
      deniedReason: deniedReason ?? this.deniedReason,
      gate: gate ?? this.gate,
      scannedBy: scannedBy ?? this.scannedBy,
    );
  }
}