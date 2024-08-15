import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_manager.g.dart';

typedef PreferenceKey = String;

class PreferenceManager {
  final SharedPreferences _prefs;

  PreferenceManager(this._prefs);

  Future<bool> setData<T>(T data, PreferenceKey key) async {
    const invalidTypeError = 'Invalid Type';
    assert(
      T == String || T == bool || T == int || T == double || T == List<String>,
      invalidTypeError,
    );

    final setFuncs = <Type, Future<bool> Function()>{
      String: () => _prefs.setString(key, data as String),
      bool: () => _prefs.setBool(key, data as bool),
      int: () => _prefs.setInt(key, data as int),
      double: () => _prefs.setDouble(key, data as double),
      List<String>: () => _prefs.setStringList(key, data as List<String>),
    };

    final result = await (setFuncs[T] ?? () async => false)();
    return result;
  }

  T? getData<T>(PreferenceKey key) {
    const invalidTypeError = 'Invalid Type';
    assert(
      T == String || T == bool || T == int || T == double || T == List<String>,
      invalidTypeError,
    );

    final getFuncs = <Type, T? Function()>{
      String: () => _prefs.getString(key) as T?,
      bool: () => _prefs.getBool(key) as T?,
      int: () => _prefs.getInt(key) as T?,
      double: () => _prefs.getDouble(key) as T?,
      List<String>: () => _prefs.getStringList(key) as T?,
    };

    final data = getFuncs[T]?.call();
    return data;
  }
}

@riverpod
PreferenceManager preferenceManager(PreferenceManagerRef ref) {
  final prefs = ref.read(sharedPreferencesProvider).requireValue;
  return PreferenceManager(prefs);
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) {
  return SharedPreferences.getInstance();
}
