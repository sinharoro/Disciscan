import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String gateName;
  final String guardName;
  final String adminPin;
  final bool isLoaded;

  SettingsState({
    this.gateName = 'Gate A',
    this.guardName = 'Guard',
    this.adminPin = '1234',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    String? gateName,
    String? guardName,
    String? adminPin,
    bool? isLoaded,
  }) {
    return SettingsState(
      gateName: gateName ?? this.gateName,
      guardName: guardName ?? this.guardName,
      adminPin: adminPin ?? this.adminPin,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState());

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      gateName: prefs.getString('gateName') ?? 'Gate A',
      guardName: prefs.getString('guardName') ?? 'Guard',
      adminPin: prefs.getString('adminPin') ?? '1234',
      isLoaded: true,
    );
  }

  Future<void> setGateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gateName', name);
    state = state.copyWith(gateName: name);
  }

  Future<void> setGuardName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardName', name);
    state = state.copyWith(guardName: name);
  }

  Future<void> setAdminPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminPin', pin);
    state = state.copyWith(adminPin: pin);
  }

  bool verifyPin(String pin) {
    return pin == state.adminPin;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});