import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/schemes_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../shell/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  int? _age;
  String? _gender;
  String _state = 'All India';
  int _currentPage = 0;
  bool _saving = false;

  List<_OnboardingContent> _slides(AppLocalizations loc) => <_OnboardingContent>[
        _OnboardingContent(
          title: loc.translate('welcome_title'),
          description: loc.translate('welcome_subtitle'),
          assetColor: const Color(0xFF1E5BFF),
          icon: Icons.public,
        ),
        _OnboardingContent(
          title: loc.translate('recommend_title'),
          description: loc.translate('recommend_subtitle'),
          assetColor: const Color(0xFF5B8CFF),
          icon: Icons.auto_awesome,
        ),
        _OnboardingContent(
          title: loc.translate('apply_confidence_title'),
          description: loc.translate('apply_confidence_subtitle'),
          assetColor: const Color(0xFF1E5BFF),
          icon: Icons.fact_check,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.translate('form_error'))),
      );
      return;
    }
    if (_age == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.translate('form_error'))),
      );
      return;
    }
    setState(() => _saving = true);
    final UserProfile profile = UserProfile(
      name: _nameController.text.trim(),
      age: _age!,
      gender: _gender!,
      occupation: _occupationController.text.trim(),
      income: int.parse(_incomeController.text.trim()),
      state: _state,
    );
    final UserProfileProvider profileProvider = context.read<UserProfileProvider>();
    final SchemesProvider schemesProvider = context.read<SchemesProvider>();
    await profileProvider.saveProfile(profile);
    await schemesProvider.loadRecommendations();
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides(context.loc).length) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _slides(context.loc).length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final List<_OnboardingContent> slides = _slides(loc);
    final bool isProfileStep = _currentPage == slides.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1B5CE5), Color(0xFF2F6BFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: <Widget>[
                    const _OnboardingLogo(),
                    const Spacer(),
                    if (!isProfileStep)
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: Text(loc.translate('skip')),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: slides.length + 1,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == slides.length) {
                      return _ProfileForm(
                        formKey: _formKey,
                        nameController: _nameController,
                        age: _age,
                        onAgeChanged: (int? value) => setState(() => _age = value),
                        incomeController: _incomeController,
                        occupationController: _occupationController,
                        gender: _gender,
                        onGenderChanged: (String? value) => setState(() => _gender = value),
                        state: _state,
                        onStateChanged: (String? value) => setState(() => _state = value ?? 'All India'),
                      );
                    }
                    return _OnboardingSlide(content: slides[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        slides.length + 1,
                        (int idx) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: idx == _currentPage ? 32 : 12,
                          decoration: BoxDecoration(
              color: idx == _currentPage
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                if (!isProfileStep) {
                                  _nextPage();
                                } else {
                                  _saveProfile();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    isProfileStep
                                        ? loc.translate('find_my_schemes')
                                        : loc.translate('next'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700, color: primaryBlue),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    isProfileStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.title,
    required this.description,
    required this.assetColor,
    required this.icon,
  });

  final String title;
  final String description;
  final Color assetColor;
  final IconData icon;
}

class _OnboardingLogo extends StatelessWidget {
  const _OnboardingLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.layers_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Text(
            'SchemePlus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width > 420 ? 48 : 24, vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x1A113BFF), blurRadius: 32, offset: Offset(0, 22)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      content.assetColor.withValues(alpha: 0.18),
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: content.assetColor.withValues(alpha: 0.18),
                    ),
                    child: Icon(content.icon, size: 78, color: content.assetColor),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A1F44),
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                content.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5B6C94),
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.nameController,
    required this.age,
    required this.onAgeChanged,
    required this.incomeController,
    required this.occupationController,
    required this.gender,
    required this.onGenderChanged,
    required this.state,
    required this.onStateChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final int? age;
  final ValueChanged<int?> onAgeChanged;
  final TextEditingController incomeController;
  final TextEditingController occupationController;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final String state;
  final ValueChanged<String?> onStateChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x1A113BFF), blurRadius: 32, offset: Offset(0, 20)),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  loc.translate('profile_form_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A1F44),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.translate('recommend_subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B6C94),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: nameController,
                  decoration: decoration(loc.translate('name')),
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty) ? loc.translate('form_error') : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: age,
                  decoration: decoration(loc.translate('age')),
                  hint: Text(loc.translate('select_option')),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  borderRadius: BorderRadius.circular(18),
                  items: List<int>.generate(48, (int index) => 18 + index)
                      .map((int value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          ))
                      .toList(),
                  onChanged: onAgeChanged,
                  validator: (int? value) => value == null ? loc.translate('form_error') : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  decoration: decoration(loc.translate('gender')),
                  hint: Text(loc.translate('select_option')),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  borderRadius: BorderRadius.circular(18),
                  items: <MapEntry<String, String>>[
                    MapEntry('male', loc.translate('gender_male')),
                    MapEntry('female', loc.translate('gender_female')),
                    MapEntry('other', loc.translate('gender_other')),
                  ]
                      .map(
                        (MapEntry<String, String> entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: onGenderChanged,
                  validator: (String? value) => value == null ? loc.translate('form_error') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: occupationController,
                  decoration: decoration(loc.translate('occupation')),
                  validator: (String? value) =>
                      (value == null || value.isEmpty) ? loc.translate('form_error') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: incomeController,
                  keyboardType: TextInputType.number,
                  decoration: decoration(loc.translate('income')),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return loc.translate('form_error');
                    return int.tryParse(value) == null ? loc.translate('form_error') : null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state,
                  decoration: decoration(loc.translate('state')),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
                  borderRadius: BorderRadius.circular(18),
                  items: indianStates
                      .map(
                        (String s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        ),
                      )
                      .toList(),
                  onChanged: onStateChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
