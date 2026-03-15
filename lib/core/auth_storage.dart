import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu token, profileId và thông tin learner sau login.
/// Dùng SharedPreferences; gọi init() trước khi dùng (vd trong main).
class AuthStorage {
  static const _keyToken = 'learner_token';
  static const _keyProfileId = 'profile_id';
  static const _keyLearnerId = 'learner_id';
  static const _keyFirstName = 'first_name';
  static const _keyLastName = 'last_name';
  static const _keyUsername = 'username';
  static const _keyProfiles = 'profiles_json';

  static SharedPreferences? _prefs;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  static String? get token => _prefs?.getString(_keyToken);
  static int? get profileId {
    final v = _prefs?.getInt(_keyProfileId);
    if (v != null) return v;
    final s = _prefs?.getString(_keyProfileId);
    if (s != null) return int.tryParse(s);
    return null;
  }

  static int? get learnerId => _prefs?.getInt(_keyLearnerId);
  static String? get firstName => _prefs?.getString(_keyFirstName);
  static String? get lastName => _prefs?.getString(_keyLastName);
  static String? get username => _prefs?.getString(_keyUsername);

  /// Danh sách profiles (sau login). Mỗi item: { profileId, status, currentLevelName, ... }
  static List<Map<String, dynamic>> get profiles {
    final raw = _prefs?.getString(_keyProfiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setToken(String value) async {
    await _prefs?.setString(_keyToken, value);
  }

  static Future<void> setProfileId(int value) async {
    await _prefs?.setInt(_keyProfileId, value);
  }

  static Future<void> setLearnerAfterLogin({
    required String token,
    required int learnerId,
    required String username,
    required String firstName,
    required String lastName,
    List<Map<String, dynamic>>? profiles,
  }) async {
    await _prefs?.setString(_keyToken, token);
    await _prefs?.setInt(_keyLearnerId, learnerId);
    await _prefs?.setString(_keyUsername, username);
    await _prefs?.setString(_keyFirstName, firstName);
    await _prefs?.setString(_keyLastName, lastName);
    if (profiles != null) {
      await _prefs?.setString(_keyProfiles, json.encode(profiles));
    } else {
      await _prefs?.remove(_keyProfiles);
    }
    // Không set profileId ở đây; set khi user chọn profile hoặc sau onboarding
  }

  static Future<void> clear() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyProfileId);
    await _prefs?.remove(_keyLearnerId);
    await _prefs?.remove(_keyFirstName);
    await _prefs?.remove(_keyLastName);
    await _prefs?.remove(_keyUsername);
    await _prefs?.remove(_keyProfiles);
  }

  static bool get isLoggedIn => token != null && (token?.isNotEmpty ?? false);
  static bool get hasProfile => profileId != null;
  /// Có ít nhất một profile (để biết đi onboarding hay chọn profile)
  static bool get hasAnyProfile => profiles.isNotEmpty;
}
