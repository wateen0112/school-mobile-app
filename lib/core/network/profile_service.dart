import '../models/app_models.dart';
import 'api_service.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiService _api;

  /// Fetch the currently authenticated user's profile.
  Future<Map<String, dynamic>> getProfile() async {
    final body = await _api.get('/profile');
    final data = body['data'] ?? body;
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  /// Update the currently authenticated user's profile.
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> values,
  ) async {
    final body = await _api.put('/profile', data: values);
    final data = body['data'] ?? body;
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }

  /// Build a display name from the profile map according to the current locale.
  static String displayName(
    Map<String, dynamic> profile,
    UserRole role, {
    required String languageCode,
  }) {
    final isAr = languageCode == 'ar';

    if (role == UserRole.parent) {
      final ar = profile['name_father_ar'] as String?;
      final en = profile['name_father_en'] as String?;
      final fallback = profile['name_father'] as String?;
      return (isAr ? ar : en) ?? fallback ?? '';
    }

    final ar = profile['name_ar'] as String?;
    final en = profile['name_en'] as String?;
    final fallback = profile['name'] as String?;
    return (isAr ? ar : en) ?? fallback ?? '';
  }
}
