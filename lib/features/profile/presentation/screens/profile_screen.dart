import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  /// Field → error, shown after the first Continue tap.
  Map<String, ProfileError> _errors = const {};
  bool _submitted = false;

  /// Asked here so Nutrition can work out daily targets right away.
  Sex? _sex;

  List<TextEditingController> get _controllers => [
        _nameController,
        _surnameController,
        _ageController,
        _weightController,
        _heightController,
      ];

  @override
  void initState() {
    super.initState();
    _sex = ref.read(performanceProfileProvider).sex;
    _prefill();
  }

  /// Fills in what's already known: a profile restored from the account,
  /// or one typed earlier on this device.
  Future<void> _prefill() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (profile == null || !mounted) return;
    _saved = profile;
    if (_controllers.any((c) => c.text.isNotEmpty)) return;
    _nameController.text = profile.name;
    _surnameController.text = profile.surname;
    _ageController.text = profile.age;
    _weightController.text = profile.weight;
    _heightController.text = profile.height;
  }

  /// What was stored when the form opened; carries the onboarding answers
  /// (goal, level, sports) through a save.
  UserProfile? _saved;

  UserProfile _currentProfile() => UserProfile(
        name: _nameController.text,
        surname: _surnameController.text,
        age: _ageController.text,
        weight: _weightController.text,
        height: _heightController.text,
        goal: _saved?.goal ?? '',
        experience: _saved?.experience ?? '',
        sports: _saved?.sports ?? const [],
      );

  Future<void> _continue() async {
    final errors = ProfileValidator.validate(_currentProfile());
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty || _sex == null) return;

    final profile = ProfileValidator.normalize(_currentProfile());
    await ref.read(profileProvider.notifier).saveProfile(profile);
    // Uploaded in the background; retried later if offline.
    unawaited(ref.read(accountServiceProvider)?.profileChanged());
    final perf = ref.read(performanceProfileProvider);
    if (perf.sex != _sex) {
      await ref.read(performanceProfileProvider.notifier).save(
            PerformanceProfile(
              sex: _sex,
              restingHr: perf.restingHr,
              maxHr: perf.maxHr,
              lthr: perf.lthr,
              ftpW: perf.ftpW,
              fiveK: perf.fiveK,
            ),
          );
    }
    await _firstWeighIn(profile);
    if (mounted) context.go(AppRouter.chat);
  }

  /// The weight typed here starts the body-weight chart (only while it has
  /// no entry yet, e.g. not for a profile restored from the account).
  Future<void> _firstWeighIn(UserProfile profile) async {
    final kg = parseProfileNumber(profile.weight);
    if (kg == null || ref.read(bodyWeightProvider).isNotEmpty) return;
    await ref
        .read(bodyWeightProvider.notifier)
        .record(WeighIn(at: ref.read(clockProvider)(), kg: kg.toDouble()));
  }

  void _revalidate() {
    if (!_submitted) return;
    setState(() => _errors = ProfileValidator.validate(_currentProfile()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String? _errorText(ProfileError? e) {
    if (e == null) return null;
    final l10n = AppLocalizations.of(context);
    return switch (e.kind) {
      ProfileErrorKind.nameRequired => l10n.profileErrNameRequired,
      ProfileErrorKind.nameTooLong => l10n.profileErrNameTooLong,
      ProfileErrorKind.surnameTooLong => l10n.profileErrSurnameTooLong,
      ProfileErrorKind.ageRequired => l10n.profileErrAgeRequired,
      ProfileErrorKind.ageWhole => l10n.profileErrAgeWhole,
      ProfileErrorKind.ageRange => l10n.profileErrAgeRange(e.min, e.max),
      ProfileErrorKind.weightRequired => l10n.profileErrWeightRequired,
      ProfileErrorKind.weightNumber => l10n.profileErrWeightNumber,
      ProfileErrorKind.weightRange => l10n.profileErrWeightRange(e.min, e.max),
      ProfileErrorKind.heightRequired => l10n.profileErrHeightRequired,
      ProfileErrorKind.heightNumber => l10n.profileErrHeightNumber,
      ProfileErrorKind.heightRange => l10n.profileErrHeightRange(e.min, e.max),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // FITRIX Logo
              const FitrixLogo(fontSize: 36),

              const SizedBox(height: AppSpacing.xl),

              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.tile,
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: palette.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Name Input
              _buildInputField(
                controller: _nameController,
                label: l10n.profileFieldName,
                field: 'name',
              ),

              const SizedBox(height: AppSpacing.md),

              // Surname Input
              _buildInputField(
                controller: _surnameController,
                label: l10n.profileFieldSurname,
                field: 'surname',
              ),

              const SizedBox(height: AppSpacing.md),

              // Age Input
              _buildInputField(
                controller: _ageController,
                label: l10n.age,
                field: 'age',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: AppSpacing.md),

              // Weight Input
              _buildInputField(
                controller: _weightController,
                label: l10n.profileFieldWeightKg,
                field: 'weight',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: AppSpacing.md),

              // Height Input
              _buildInputField(
                controller: _heightController,
                label: l10n.profileFieldHeightCm,
                field: 'height',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: AppSpacing.md),

              _buildSexChoice(),

              const SizedBox(height: AppSpacing.xl),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.fromHeight(54))),
                  onPressed: _continue,
                  child: Text(l10n.continueButton),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Male / Female, like the pills on Edit profile.
  Widget _buildSexChoice() {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final missing = _submitted && _sex == null;

    Widget pill(String label, Sex value) {
      final selected = _sex == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: Key('profile-sex-${value.name}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _sex = value),
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.curve,
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: selected ? palette.pillSelected : palette.buttonMuted,
                borderRadius: AppRadius.smAll,
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppText.headingS.copyWith(
                      fontWeight: FontWeight.w400,
                      color: selected
                          ? palette.onPillSelected
                          : palette.textPrimary)),
            ),
          ),
        ),
      );
    }

    return Column(
      key: const Key('profile-sex'),
      children: [
        Text(l10n.editProfileSex,
            style: AppText.headingS.copyWith(
                fontWeight: FontWeight.w400, color: palette.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          pill(l10n.sexMale, Sex.male),
          const SizedBox(width: AppSpacing.xs),
          pill(l10n.sexFemale, Sex.female),
        ]),
        if (missing)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(l10n.profileErrSexRequired,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: palette.danger)),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String field,
    TextInputType? keyboardType,
  }) {
    return TextField(
      key: Key('profile-$field'),
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next,
      onChanged: (_) => _revalidate(),
      decoration: InputDecoration(
        hintText: label,
        errorText: _errorText(_errors[field]),
        errorMaxLines: 2,
        hintStyle: AppText.headingS.copyWith(
          fontWeight: FontWeight.w400,
          color: AppPalette.of(context).textSecondary,
        ),
      ),
    );
  }
}
