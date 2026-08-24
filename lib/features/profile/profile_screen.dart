import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
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
  late final ProfileService _service;
  late final UserRole _role;
  late final String _languageCode;

  String? _displayName;
  String? _displaySubtitle;
  bool _loading = true;
  String? _error;
  bool _saving = false;

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

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _service.getProfile();
      _email.text = '${profile['email'] ?? ''}';
      _password.clear();

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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildErrorCard(context),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
      children: [
        _buildAvatarCard(context),
        const SizedBox(height: 20),
        _buildSectionTitle(context, isAr ? 'معلومات الحساب' : 'Account Information'),
        const SizedBox(height: 10),
        _buildInfoCard(
          context,
          children: [
            _field(
              controller: _email,
              label: isAr ? 'البريد الإلكتروني' : 'Email',
              icon: Icons.email_rounded,
              type: TextInputType.emailAddress,
            ),
            _divider(),
            _field(
              controller: _password,
              label: isAr ? 'كلمة المرور الجديدة (اختياري)' : 'New Password (optional)',
              icon: Icons.lock_rounded,
              obscure: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_role == UserRole.parent) ...[
          _buildSectionTitle(context, isAr ? 'معلومات الأب' : 'Father Information'),
          const SizedBox(height: 10),
          _buildInfoCard(
            context,
            children: [
              _field(
                controller: _nameAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                icon: Icons.person_rounded,
              ),
              _divider(),
              _field(
                controller: _phoneFather,
                label: isAr ? 'رقم الهاتف' : 'Phone',
                icon: Icons.phone_rounded,
                type: TextInputType.phone,
              ),
              _divider(),
              _field(
                controller: _addressFather,
                label: isAr ? 'العنوان' : 'Address',
                icon: Icons.location_on_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, isAr ? 'معلومات الأم' : 'Mother Information'),
          const SizedBox(height: 10),
          _buildInfoCard(
            context,
            children: [
              _field(
                controller: _nameMotherAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                icon: Icons.person_rounded,
              ),
              _divider(),
              _field(
                controller: _phoneMother,
                label: isAr ? 'رقم الهاتف' : 'Phone',
                icon: Icons.phone_rounded,
                type: TextInputType.phone,
              ),
              _divider(),
              _field(
                controller: _addressMother,
                label: isAr ? 'العنوان' : 'Address',
                icon: Icons.location_on_rounded,
              ),
            ],
          ),
        ] else ...[
          _buildSectionTitle(context, isAr ? 'معلومات شخصية' : 'Personal Information'),
          const SizedBox(height: 10),
          _buildInfoCard(
            context,
            children: [
              _field(
                controller: _nameAr,
                label: isAr ? 'الاسم (عربي)' : 'Name (Arabic)',
                icon: Icons.person_rounded,
              ),
              if (_role == UserRole.teacher) ...[
                _divider(),
                _field(
                  controller: _address,
                  label: isAr ? 'العنوان' : 'Address',
                  icon: Icons.location_on_rounded,
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle(context, isAr ? 'الإعدادات' : 'Preferences'),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: SwitchListTile(
            title: Text(t(context, 'arabic')),
            subtitle: Text(t(context, 'language')),
            value: isAr,
            onChanged: (value) {
              final next = value ? const Locale('ar') : const Locale('en');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<SessionController>().selectLocale(next);
              });
            },
            secondary: const Icon(Icons.language_rounded, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded),
          label: Text(isAr ? 'حفظ التغييرات' : 'Save Changes'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAvatarCard(BuildContext context) {
    final isAr = appIsArabic(context);
    final roleLabel = isAr ? _roleLabelAr(_role) : _roleLabelEn(_role);

    return Container(
      decoration: AppTheme.softPanel(
        gradient: AppTheme.heroGradient,
        radius: 28,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 38,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (_displaySubtitle != null && _displaySubtitle!.isNotEmpty)
                    Text(
                      _displaySubtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Color(0xffedf1ff),
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
    };
  }

  String _roleLabelEn(UserRole role) {
    return switch (role) {
      UserRole.teacher => 'Teacher',
      UserRole.student => 'Student',
      UserRole.parent => 'Parent',
    };
  }
}
