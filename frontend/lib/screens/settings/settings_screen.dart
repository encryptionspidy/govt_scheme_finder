import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/hive_boxes.dart';
import '../../data/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_language_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/schemes_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../notifications/notifications_screen.dart';
import '../splash/splash_screen.dart';

const String _helpCenterUrl = 'https://www.myscheme.gov.in/support';
const String _privacyPolicyUrl = 'https://www.mygov.in/privacy-policy/';
const String _termsUrl = 'https://www.mygov.in/terms-conditions/';
const String _playStoreUrl =
  'https://play.google.com/store/apps/details?id=com.example.schemeplus_app';
const String _supportEmail = 'mailto:support@schemeplus.gov.in';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _profileBox;
  bool _deadlineReminders = true;
  bool _newSchemeAlerts = true;
  bool _pushEnabled = true;
  bool _isRefreshingCache = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box(HiveBoxes.profile);
    _deadlineReminders = _profileBox.get('deadlineReminders', defaultValue: true) as bool;
    _newSchemeAlerts = _profileBox.get('newSchemeAlerts', defaultValue: true) as bool;
    _pushEnabled = _profileBox.get('pushEnabled', defaultValue: true) as bool;
  }

  void _updatePreference(String key, bool value) {
    setState(() {
      switch (key) {
        case 'deadlineReminders':
          _deadlineReminders = value;
          break;
        case 'newSchemeAlerts':
          _newSchemeAlerts = value;
          break;
        case 'pushEnabled':
          _pushEnabled = value;
          break;
      }
    });
    _profileBox.put(key, value);
  }

  Future<void> _refreshOfflineCache(BuildContext context) async {
    if (_isRefreshingCache) return;
    setState(() => _isRefreshingCache = true);
    final AppLocalizations loc = context.loc;
    try {
      final SchemesProvider schemesProvider = context.read<SchemesProvider>();
      await schemesProvider.fetchAllCategories(forceRefresh: true);
      await schemesProvider.cachedAllSchemes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('offline_cache_success'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('generic_error'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingCache = false);
      }
    }
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final LaunchMode mode = uri.scheme == 'mailto'
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication;
      final bool launched = await launchUrl(uri, mode: mode);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.translate('generic_error'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.translate('generic_error'))),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    if (!mounted) return;
    final AppLocalizations loc = context.loc;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(loc.translate('confirm')),
        content: Text(loc.translate('logout_confirm_body')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.translate('logout')),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      final UserProfileProvider profileProvider = context.read<UserProfileProvider>();
      final BookmarksProvider bookmarksProvider = context.read<BookmarksProvider>();
      final SchemesProvider schemesProvider = context.read<SchemesProvider>();

      await Future.wait(<Future<void>>[
        profileProvider.resetProfile(),
        bookmarksProvider.clearAll(),
      ]);
      await Hive.box(HiveBoxes.schemesCache).clear();
      await schemesProvider.fetchAllCategories(forceRefresh: true);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('generic_error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final AppLanguageProvider languageProvider = context.watch<AppLanguageProvider>();
    final UserProfileProvider profileProvider = context.watch<UserProfileProvider>();

    final UserProfile? profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SettingsHeader(
                      loc: loc,
                      onBookmarksTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
                      ),
                      onNotificationsTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                title: loc.translate('language'),
                child: _LanguageToggle(
                  current: languageProvider.locale.languageCode,
                  onChanged: (String code) => languageProvider.changeLocale(Locale(code)),
                  labels: <String, String>{
                    'en': loc.translate('english_short'),
                    'ta': loc.translate('tamil_short'),
                  },
                ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: loc.translate('profile_edit'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _ProfileSummaryCard(profile: profile, loc: loc),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(loc.translate('profile_edit_cta')),
                              onPressed: () => _showProfileDialog(context, profile),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: loc.translate('notification_settings'),
                      child: Column(
                        children: <Widget>[
                          _ToggleRow(
                            icon: Icons.notifications_active_outlined,
                            title: loc.translate('deadline_reminders'),
                            value: _deadlineReminders,
                            onChanged: (bool value) => _updatePreference('deadlineReminders', value),
                          ),
                          const Divider(height: 28),
                          _ToggleRow(
                            icon: Icons.new_releases_outlined,
                            title: loc.translate('new_scheme_alerts'),
                            value: _newSchemeAlerts,
                            onChanged: (bool value) => _updatePreference('newSchemeAlerts', value),
                          ),
                          const Divider(height: 28),
                          _ToggleRow(
                            icon: Icons.sms_outlined,
                            title: loc.translate('push_notifications'),
                            value: _pushEnabled,
                            onChanged: (bool value) => _updatePreference('pushEnabled', value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: loc.translate('app_preferences'),
                      child: Column(
                        children: <Widget>[
                          _SettingTile(
                            icon: Icons.cloud_download_outlined,
                            title: loc.translate('offline_cache'),
                            subtitle: loc.translate('offline_cache_desc'),
                            onTap: () => _refreshOfflineCache(context),
                            trailing: _isRefreshingCache
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _SettingTile(
                            icon: Icons.star_rate_outlined,
                            title: loc.translate('rate_app'),
                            subtitle: loc.translate('rate_app_desc'),
                            onTap: () => _launchExternal(context, _playStoreUrl),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: loc.translate('support_section'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SupportTile(
                            icon: Icons.help_outline,
                            title: loc.translate('help_center'),
                            subtitle: loc.translate('help_center_desc'),
                            onTap: () => _launchExternal(context, _helpCenterUrl),
                          ),
                          const SizedBox(height: 16),
                          _SupportTile(
                            icon: Icons.mail_outline,
                            title: loc.translate('contact_us'),
                            subtitle: loc.translate('contact_us_email'),
                            onTap: () => _launchExternal(context, _supportEmail),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: loc.translate('legal_section'),
                      child: Column(
                        children: <Widget>[
                          _SettingTile(
                            icon: Icons.privacy_tip_outlined,
                            title: loc.translate('privacy_policy'),
                            subtitle: loc.translate('privacy_policy_desc'),
                            onTap: () => _launchExternal(context, _privacyPolicyUrl),
                          ),
                          const SizedBox(height: 16),
                          _SettingTile(
                            icon: Icons.article_outlined,
                            title: loc.translate('terms_conditions'),
                            subtitle: loc.translate('terms_conditions_desc'),
                            onTap: () => _launchExternal(context, _termsUrl),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _DangerButton(
                        label: loc.translate('app_reset'),
                        onPressed: () => _confirmReset(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoggingOut ? null : _handleLogout,
                        icon: _isLoggingOut
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(loc.translate('logout')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: errorRed,
                          side: const BorderSide(color: errorRed, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context, UserProfile? profile) async {
    final AppLocalizations loc = context.loc;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: profile?.name ?? '');
    final TextEditingController ageController = TextEditingController(text: profile?.age.toString() ?? '');
    final TextEditingController incomeController =
        TextEditingController(text: profile?.income.toString() ?? '');
    final TextEditingController occupationController =
        TextEditingController(text: profile?.occupation ?? '');
    String gender = profile?.gender ?? 'any';
    String selectedState = profile?.state ?? 'All India';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: bottomInset + 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        loc.translate('profile_edit'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: loc.translate('name')),
                        validator: (String? value) =>
                            (value == null || value.trim().isEmpty) ? loc.translate('form_error') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: loc.translate('age')),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return loc.translate('form_error');
                          return int.tryParse(value) == null ? loc.translate('form_error') : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        decoration: InputDecoration(labelText: loc.translate('gender')),
                        items: <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'any', child: Text(loc.translate('gender_other'))),
                          DropdownMenuItem(value: 'male', child: Text(loc.translate('gender_male'))),
                          DropdownMenuItem(value: 'female', child: Text(loc.translate('gender_female'))),
                        ],
                        onChanged: (String? value) => gender = value ?? 'any',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: occupationController,
                        decoration: InputDecoration(labelText: loc.translate('occupation')),
                        validator: (String? value) =>
                            (value == null || value.isEmpty) ? loc.translate('form_error') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: incomeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: loc.translate('income')),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) return loc.translate('form_error');
                          return int.tryParse(value) == null ? loc.translate('form_error') : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedState,
                        decoration: InputDecoration(labelText: loc.translate('state')),
                        items: indianStates
                            .map((String state) => DropdownMenuItem<String>(value: state, child: Text(state)))
                            .toList(),
                        onChanged: (String? value) => selectedState = value ?? 'All India',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final int? ageValue = int.tryParse(ageController.text.trim());
                            final int? incomeValue = int.tryParse(incomeController.text.trim());
                            if (ageValue == null || incomeValue == null) {
                              return;
                            }
                            final UserProfile updated = UserProfile(
                              name: nameController.text.trim(),
                              age: ageValue,
                              gender: gender,
                              occupation: occupationController.text.trim(),
                              income: incomeValue,
                              state: selectedState,
                            );
                            final UserProfileProvider profileProvider = context.read<UserProfileProvider>();
                            final SchemesProvider schemesProvider = context.read<SchemesProvider>();
                            await profileProvider.saveProfile(updated);
                            await schemesProvider.loadRecommendations();
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          child: Text(loc.translate('update')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final AppLocalizations loc = context.loc;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(loc.translate('confirm')),
        content: Text(loc.translate('app_reset_confirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final UserProfileProvider profileProvider = context.read<UserProfileProvider>();
      final BookmarksProvider bookmarksProvider = context.read<BookmarksProvider>();
      await profileProvider.resetProfile();
      await bookmarksProvider.clearAll();
      Hive.box(HiveBoxes.schemesCache).clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('profile_reset'))),
      );
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.loc,
    required this.onBookmarksTap,
    required this.onNotificationsTap,
  });

  final AppLocalizations loc;
  final VoidCallback onBookmarksTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: schemeBlueGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(color: primaryBlueDark.withAlpha(60), blurRadius: 24, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      loc.translate('settings_title'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.translate('settings_intro'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white.withAlpha(230), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeaderActionButton(
                icon: Icons.bookmark_border_rounded,
                tooltip: loc.translate('bookmarks_title'),
                onTap: onBookmarksTap,
              ),
              const SizedBox(width: 12),
              _HeaderActionButton(
                icon: Icons.notifications_none_rounded,
                tooltip: loc.translate('notifications_title'),
                onTap: onNotificationsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
    return Tooltip(message: tooltip, child: button);
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dividerColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  gradient: softBlueGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: primaryBlueDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, color: neutralText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.current,
    required this.onChanged,
    required this.labels,
  });

  final String current;
  final void Function(String) onChanged;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentLightBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: labels.entries.map((MapEntry<String, String> entry) {
          final bool selected = entry.key == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile, required this.loc});

  final UserProfile? profile;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final String name = profile?.name.trim() ?? '';
    final String occupation = profile?.occupation.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentPaleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  gradient: schemeBlueGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name.isNotEmpty ? name : loc.translate('add_name'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      occupation.isNotEmpty
                          ? occupation
                          : (profile?.state ?? loc.translate('state_placeholder')),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: <Widget>[
              _ProfileStatChip(
                icon: Icons.cake_outlined,
                label: loc.translate('age'),
                value: profile != null ? '${profile!.age}' : '--',
              ),
              _ProfileStatChip(
                icon: Icons.work_outline,
                label: loc.translate('occupation'),
                value: occupation.isNotEmpty
                    ? occupation
                    : loc.translate('add_occupation'),
              ),
              _ProfileStatChip(
                icon: Icons.currency_rupee_outlined,
                label: loc.translate('income'),
                value: profile != null ? '₹${profile!.income.toString()}' : '--',
                expanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style:
                      Theme.of(context).textTheme.labelMedium?.copyWith(color: mutedText, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: content,
      );
    }
    return SizedBox(width: 180, child: content);
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: accentLightBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: neutralText),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => Colors.white,
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.selected) ? primaryBlue : dividerColor,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accentLightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600, color: neutralText),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: mutedText, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right_rounded, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  gradient: softBlueGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primaryBlueDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedText),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.open_in_new_rounded, color: primaryBlueDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: errorRed,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const Icon(Icons.restart_alt_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
