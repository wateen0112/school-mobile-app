import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/network/background_notification_service.dart';
import '../../core/network/profile_service.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/module_localization.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _notificationsKey = 'notifications_enabled';

  late final ProfileService _service;
  late final UserRole _role;
  late final String _languageCode;

  String? _displayName;
  String? _displaySubtitle;
  String? _recordId;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _obscurePassword = true;
  bool _notificationsEnabled = true;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameAr = TextEditingController();
  final _nameMotherAr = TextEditingController();
  final _phoneFather = TextEditingController();
  final _phoneMother = TextEditingController();
  final _address = TextEditingController();
  final _addressFather = TextEditingController();
  final _addressMother = TextEditingController();

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _service = ProfileService(session.api);
    _role = session.currentRole;
    _languageCode = session.locale.languageCode;
    _loadProfile();
    _loadNotificationsPref();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nameAr.dispose();
    _nameMotherAr.dispose();
    _phoneFather.dispose();
    _phoneMother.dispose();
    _address.dispose();
    _addressFather.dispose();
    _addressMother.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    });
  }

  Future<void> _saveNotificationsPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    if (value) {
      await BackgroundNotificationService.startPolling();
    } else {
      await BackgroundNotificationService.stopPolling();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.getProfile();
      _email.text = '${profile['email'] ?? ''}';
      _password.clear();

      final id = profile['id'] ?? profile['ID'];
      final prefix = switch (_role) {
        UserRole.student => 'STD',
        UserRole.teacher => 'TCH',
        UserRole.parent => 'PRN',
        UserRole.driver => 'DRV',
        UserRole.admin => 'ADM',
      };
      _recordId = id == null ? null : '#$prefix-$id';

      if (_role == UserRole.parent) {
        _nameAr.text = '${profile['name_father_ar'] ?? ''}';
        _nameMotherAr.text = '${profile['name_mother_ar'] ?? ''}';
        _phoneFather.text = '${profile['phone_father'] ?? ''}';
        _phoneMother.text = '${profile['phone_mother'] ?? ''}';
        _addressFather.text = '${profile['address_father'] ?? ''}';
        _addressMother.text = '${profile['address_mother'] ?? ''}';
        _displayName = ProfileService.displayName(profile, _role, languageCode: _languageCode);
        _displaySubtitle = profile['email'] as String?;
      } else {
        _nameAr.text = '${profile['name_ar'] ?? ''}';
        _address.text = '${profile['address'] ?? ''}';
        _displayName = ProfileService.displayName(profile, _role, languageCode: _languageCode);
        _displaySubtitle = profile['email'] as String?;
      }
    } catch (error) {
      _error = ApiService.failureFrom(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final session = context.read<SessionController>();
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'email': _email.text.trim(),
        if (_password.text.isNotEmpty) 'password': _password.text,
      };

      if (_role == UserRole.parent) {
        payload.addAll({
          'name_father_ar': _nameAr.text.trim(),
          'name_mother_ar': _nameMotherAr.text.trim(),
          'phone_father': _phoneFather.text.trim(),
          'phone_mother': _phoneMother.text.trim(),
          'address_father': _addressFather.text.trim(),
          'address_mother': _addressMother.text.trim(),
        });
      } else {
        payload.addAll({
          'name_ar': _nameAr.text.trim(),
          if (_role == UserRole.teacher) 'address': _address.text.trim(),
        });
      }

      final updated = await _service.updateProfile(payload);
      final newName = ProfileService.displayName(updated, _role, languageCode: _languageCode);
      if (newName.isNotEmpty) {
        session.updateUserFromProfile(name: newName, email: _email.text.trim());
        await session.authStorage.saveSession(
          token: session.authStorage.token ?? '',
          user: {'id': session.user?.id, 'name': newName, 'email': _email.text.trim()},
          role: _role,
        );
        setState(() => _displayName = newName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appIsArabic(context) ? 'تم تحديث الملف الشخصي.' : 'Profile updated.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiService.failureFrom(error).message),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = appIsArabic(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: _buildErrorCard(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHero(context),
        const SizedBox(height: 20),
        _buildSectionTitle(context, isAr ? 'معلومات الحساب' : 'Account Information'),
        const SizedBox(height: 8),
        _infoCard(
          children: [
            _infoField(
              controller: _email,
              label: isAr ? 'البريد الإلكتروني' : 'Email',
              keyboardType: TextInputType.emailAddress,
              iconBox: const _InfoIconBox(
                icon: Icons.email_rounded,
                background: Color(0xffEFF6FF),
                foreground: Color(0xff2563EB),
              ),
            ),
            _divider(),
            _infoField(
              controller: _password,
              label: isAr ? 'كلمة المرور الجديدة (اختياري)' : 'New Password (optional)',
              obscure: _obscurePassword,
              placeholder: '••••••••••',
              iconBox: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 18,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _InfoIconBox(
                    icon: Icons.lock_rounded,
                    background: Color(0xffEFF6FF),
                    foreground: Color(0xff2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_role == UserRole.parent) ...[
          _buildSectionTitle(context, isAr ? 'معلومات الأب' : 'Father Information'),
          const SizedBox(height: 8),
          _infoCard(
            children: [
              _infoField(
                controller: _nameAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                iconBox: const _InfoIconBox(
                  icon: Icons.person_rounded,
                  background: Color(0xffEEF2FF),
                  foreground: Color(0xff4F46E5),
                ),
              ),
              _divider(),
              _infoField(
                controller: _phoneFather,
                label: isAr ? 'رقم الهاتف' : 'Phone',
                keyboardType: TextInputType.phone,
                iconBox: const _InfoIconBox(
                  icon: Icons.phone_rounded,
                  background: Color(0xffEFF6FF),
                  foreground: Color(0xff2563EB),
                ),
              ),
              _divider(),
              _infoField(
                controller: _addressFather,
                label: isAr ? 'العنوان' : 'Address',
                iconBox: const _InfoIconBox(
                  icon: Icons.location_on_rounded,
                  background: Color(0xffF8FAFC),
                  foreground: Color(0xff475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, isAr ? 'معلومات الأم' : 'Mother Information'),
          const SizedBox(height: 8),
          _infoCard(
            children: [
              _infoField(
                controller: _nameMotherAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                iconBox: const _InfoIconBox(
                  icon: Icons.person_rounded,
                  background: Color(0xffEEF2FF),
                  foreground: Color(0xff4F46E5),
                ),
              ),
              _divider(),
              _infoField(
                controller: _phoneMother,
                label: isAr ? 'رقم الهاتف' : 'Phone',
                keyboardType: TextInputType.phone,
                iconBox: const _InfoIconBox(
                  icon: Icons.phone_rounded,
                  background: Color(0xffEFF6FF),
                  foreground: Color(0xff2563EB),
                ),
              ),
              _divider(),
              _infoField(
                controller: _addressMother,
                label: isAr ? 'العنوان' : 'Address',
                iconBox: const _InfoIconBox(
                  icon: Icons.location_on_rounded,
                  background: Color(0xffF8FAFC),
                  foreground: Color(0xff475569),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildSectionTitle(context, isAr ? 'معلومات شخصية' : 'Personal Information'),
          const SizedBox(height: 8),
          _infoCard(
            children: [
              _infoField(
                controller: _nameAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                iconBox: const _InfoIconBox(
                  icon: Icons.person_rounded,
                  background: Color(0xffEEF2FF),
                  foreground: Color(0xff4F46E5),
                ),
              ),
              if (_role == UserRole.student) ...[
                _divider(),
                _readOnlyField(
                  label: isAr ? 'رقم الهوية / القيد الأكاديمي' : 'Student ID',
                  value: _recordId ?? '—',
                  iconBox: const _InfoIconBox(
                    icon: Icons.badge_rounded,
                    background: Color(0xffF8FAFC),
                    foreground: Color(0xff475569),
                  ),
                ),
              ],
              if (_role == UserRole.teacher) ...[
                _divider(),
                _infoField(
                  controller: _address,
                  label: isAr ? 'العنوان' : 'Address',
                  iconBox: const _InfoIconBox(
                    icon: Icons.location_on_rounded,
                    background: Color(0xffF8FAFC),
                    foreground: Color(0xff475569),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (_role == UserRole.teacher) ...[
          const SizedBox(height: 24),
          _buildSectionTitle(context, isAr ? 'الراتب' : 'Salary'),
          const SizedBox(height: 8),
          _infoCard(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('profile-salary-link'),
                  onTap: () => context.push('/teacher/salary'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        const _InfoIconBox(
                          icon: Icons.payments_rounded,
                          background: Color(0xffF5F3FF),
                          foreground: Color(0xff7C3AED),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الراتب الشهري',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff1E293B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isAr
                                    ? 'عرض الراتب الأساسي وسجل الدفعات'
                                    : 'View base salary and payment history',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Color(0xffCBD5E1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle(context, isAr ? 'الإعدادات العامة' : 'General Settings'),
        const SizedBox(height: 8),
        _infoCard(
          children: [
            _settingsRow(
              icon: Icons.language_rounded,
              iconBackground: const Color(0xffECFDF5),
              iconForeground: const Color(0xff059669),
              title: isAr ? 'العربية' : 'Arabic',
              subtitle: isAr ? 'لغة التطبيق الافتراضية' : 'Default app language',
              value: isAr,
              onChanged: (value) {
                final next = value ? const Locale('ar') : const Locale('en');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<SessionController>().selectLocale(next);
                });
              },
            ),
            _divider(),
            _settingsRow(
              icon: Icons.notifications_rounded,
              iconBackground: const Color(0xffFFF7ED),
              iconForeground: const Color(0xffF97316),
              title: isAr ? 'إشعارات الاختبارات والواجبات' : 'Exam & homework notifications',
              subtitle: isAr ? 'تنبيهات فورية على الهاتف' : 'Instant alerts on your phone',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveNotificationsPref(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 26),
        _saveButton(context, isAr),
        const SizedBox(height: 16),
        _logoutButton(context),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildProfileHero(BuildContext context) {
    final isAr = appIsArabic(context);
    final roleLabel = isAr ? _roleLabelAr(_role) : _roleLabelEn(_role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1E3C72), Color(0xFF2A52BE)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withValues(alpha: .3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: _HeroCircle(
              size: 120,
              color: Colors.white.withValues(alpha: .1),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -16,
            child: _HeroCircle(
              size: 130,
              color: const Color(0xff60A5FA).withValues(alpha: .2),
            ),
          ),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: Color(0xff2563EB),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xff34D399),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (_displayName ?? '').isEmpty ? '—' : _displayName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .25),
                            ),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (_displaySubtitle != null && _displaySubtitle!.isNotEmpty)
                      Text(
                        _displaySubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xffDBEAFE),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_recordId != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _recordId!,
                          style: const TextStyle(
                            color: Color(0xffDBEAFE),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xff64748B),
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D4ED8).withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _infoField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? placeholder,
    required Widget iconBox,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff334155),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      color: Color(0xffCBD5E1),
                      letterSpacing: 2,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          iconBox,
        ],
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required Widget iconBox,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          iconBox,
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required Color iconBackground,
    required Color iconForeground,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _InfoIconBox(
            icon: icon,
            background: iconBackground,
            foreground: iconForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xff2563EB),
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _saveButton(BuildContext context, bool isAr) {
    final label = isAr ? 'حفظ التغييرات' : 'Save Changes';
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff2563EB), Color(0xff1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff2563EB).withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _saving ? null : _save,
            child: Center(
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    final session = context.read<SessionController>();
    return TextButton.icon(
      onPressed: () {
        session.logout().then((_) {
          if (context.mounted) context.go('/login');
        });
      },
      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xffF43F5E)),
      label: Text(
        t(context, 'logout'),
        style: const TextStyle(
          color: Color(0xffF43F5E),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xffF1F5F9),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.coral, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(appIsArabic(context) ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabelAr(UserRole role) {
    return switch (role) {
      UserRole.teacher => 'معلم',
      UserRole.student => 'طالب',
      UserRole.parent => 'ولي أمر',
      UserRole.driver => 'سائق',
      UserRole.admin => 'مدير',
    };
  }

  String _roleLabelEn(UserRole role) {
    return switch (role) {
      UserRole.teacher => 'Teacher',
      UserRole.student => 'Student',
      UserRole.parent => 'Parent',
      UserRole.driver => 'Driver',
      UserRole.admin => 'Admin',
    };
  }
}

class _InfoIconBox extends StatelessWidget {
  const _InfoIconBox({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}