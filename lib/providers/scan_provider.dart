import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/models/student.dart';
import '../db/models/scan_log.dart';
import '../db/database_helper.dart';

class ScanState {
  final String studentId;
  final Student? student;
  final bool uniformComplete;
  final bool idVisible;
  final String scanType;
  final bool isLoading;
  final String? error;

  ScanState({
    this.studentId = '',
    this.student,
    this.uniformComplete = false,
    this.idVisible = false,
    this.scanType = 'entry',
    this.isLoading = false,
    this.error,
  });

  ScanState copyWith({
    String? studentId,
    Student? student,
    bool? uniformComplete,
    bool? idVisible,
    String? scanType,
    bool? isLoading,
    String? error,
    bool clearStudent = false,
    bool clearError = false,
  }) {
    return ScanState(
      studentId: studentId ?? this.studentId,
      student: clearStudent ? null : (student ?? this.student),
      uniformComplete: uniformComplete ?? this.uniformComplete,
      idVisible: idVisible ?? this.idVisible,
      scanType: scanType ?? this.scanType,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canConfirm => student != null && studentId.isNotEmpty;
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref ref;
  final DatabaseHelper _db = DatabaseHelper.instance;

  ScanNotifier(this.ref) : super(ScanState());

  Future<void> lookupStudent(String studentId) async {
    if (studentId.trim().isEmpty) {
      state = state.copyWith(clearStudent: true, studentId: '');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final student = await _db.getStudent(studentId.trim());
    
    if (student != null) {
      state = state.copyWith(
        student: student,
        studentId: studentId.trim(),
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        clearStudent: true,
        studentId: studentId.trim(),
        isLoading: false,
        error: 'Student not registered. Add manually.',
      );
    }
  }

  void setStudentId(String id) {
    state = state.copyWith(studentId: id);
  }

  void toggleUniformComplete() {
    state = state.copyWith(uniformComplete: !state.uniformComplete);
  }

  void toggleIdVisible() {
    state = state.copyWith(idVisible: !state.idVisible);
  }

  void toggleScanType() {
    state = state.copyWith(scanType: state.scanType == 'entry' ? 'exit' : 'entry');
  }

  Future<ScanLog?> confirmEntry(String gateName, String guardName) async {
    if (!state.canConfirm) return null;

    final isCompliant = state.uniformComplete && state.idVisible;
    final status = isCompliant ? 'granted' : 'denied';
    
    String? deniedReason;
    if (!state.uniformComplete && !state.idVisible) {
      deniedReason = 'Incomplete uniform and no ID';
    } else if (!state.uniformComplete) {
      deniedReason = 'Incomplete uniform';
    } else if (!state.idVisible) {
      deniedReason = 'ID not visible';
    }

    final scanLog = ScanLog(
      studentId: state.studentId,
      studentName: state.student?.name,
      grade: state.student?.grade,
      scanTime: DateTime.now().toIso8601String(),
      scanType: state.scanType,
      uniformComplete: state.uniformComplete,
      idVisible: state.idVisible,
      status: status,
      deniedReason: deniedReason,
      gate: gateName,
      scannedBy: guardName,
    );

    await _db.insertScanLog(scanLog);
    
    ref.invalidate(todayLogsProvider);
    ref.invalidate(todayStatsProvider);

    return scanLog.copyWith(id: 1);
  }

  void reset() {
    state = ScanState();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref);
});

final todayLogsProvider = FutureProvider<List<ScanLog>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getTodayLogs();
});

final todayStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getTodayStats();
});