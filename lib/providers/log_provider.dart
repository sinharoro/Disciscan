import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/models/scan_log.dart';
import '../db/database_helper.dart';

enum LogFilter { all, granted, denied, entry, exit }

class LogState {
  final List<ScanLog> logs;
  final LogFilter filter;
  final String searchQuery;
  final bool isLoading;

  LogState({
    this.logs = const [],
    this.filter = LogFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
  });

  LogState copyWith({
    List<ScanLog>? logs,
    LogFilter? filter,
    String? searchQuery,
    bool? isLoading,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<ScanLog> get filteredLogs {
    var filtered = logs;
    
    switch (filter) {
      case LogFilter.granted:
        filtered = filtered.where((l) => l.status == 'granted').toList();
        break;
      case LogFilter.denied:
        filtered = filtered.where((l) => l.status == 'denied').toList();
        break;
      case LogFilter.entry:
        filtered = filtered.where((l) => l.scanType == 'entry').toList();
        break;
      case LogFilter.exit:
        filtered = filtered.where((l) => l.scanType == 'exit').toList();
        break;
      case LogFilter.all:
        break;
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((l) =>
        l.studentName?.toLowerCase().contains(query) == true ||
        l.studentId.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  Map<String, int> get stats {
    return {
      'total': logs.length,
      'granted': logs.where((l) => l.status == 'granted').length,
      'denied': logs.where((l) => l.status == 'denied').length,
      'exit': logs.where((l) => l.scanType == 'exit').length,
    };
  }
}

class LogNotifier extends StateNotifier<LogState> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  LogNotifier() : super(LogState());

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true);
    final logs = await _db.getTodayLogs();
    state = state.copyWith(logs: logs, isLoading: false);
  }

  void setFilter(LogFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> deleteLog(int id) async {
    await _db.deleteScanLog(id);
    await loadLogs();
  }

  Future<void> clearFilter() async {
    state = state.copyWith(filter: LogFilter.all, searchQuery: '');
  }
}

final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier();
});