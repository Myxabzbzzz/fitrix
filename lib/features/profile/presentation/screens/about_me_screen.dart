import 'dart:async';

import 'package:fitrix/features/profile/presentation/widgets/about_me_guard.dart';
import 'package:fitrix/features/profile/presentation/widgets/about_me_labels.dart';
import 'package:fitrix/features/profile/presentation/widgets/about_me_widgets.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';

const _levels = ['Beginner', 'Intermediate', 'Advanced'];
const _otherGoal = '\u0000other';

/// About me: the profile entered during onboarding, editable
/// (opened from the Profile tab).
class AboutMeScreen extends ConsumerStatefulWidget {
  const AboutMeScreen({super.key});

  @override
  ConsumerState<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends ConsumerState<AboutMeScreen> {
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _goalOther = TextEditingController();

  /// A preset from [AppConstants.fitnessGoals], [_otherGoal], or '' (none).
  String _goalChoice = '';
  String _level = '';
  List<String> _sports = [];
  bool _sportsLimitHit = false;

  /// What is stored (normalized); edits are compared against it.
  UserProfile _baseline =
      UserProfile(name: '', surname: '', age: '', weight: '', height: '');
  final Set<String> _touched = {};

  late final StateController<bool> _dirtyFlag;

  @override
  void initState() {
    super.initState();
    _dirtyFlag = ref.read(aboutMeDirtyProvider.notifier);
    for (final c in _controllers) {
      c.addListener(_changed);
    }
    unawaited(_load());
  }

  List<TextEditingController> get _controllers =>
      [_name, _surname, _age, _weight, _height, _goalOther];

  Future<void> _load() async {
    final saved = await ref.read(profileRepositoryProvider).getProfile();
    if (!mounted) return;
    setState(() => _apply(saved ?? _baseline));
  }

  /// Known sports matched case-insensitively to their canonical label
  /// ("gym" typed in the chat becomes "Gym"), duplicates dropped.
  static List<String> _canonicalSports(List<String> sports) {
    final out = <String>[];
    for (final raw in sports) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      final match = Sport.values
          .where((s) => s.label.toLowerCase() == t.toLowerCase())
          .map((s) => s.label);
      final value = match.isEmpty ? t : match.first;
      if (!out.contains(value)) out.add(value);
    }
    return out;
  }

  void _apply(UserProfile saved) {
    var goal = saved.goal.trim();
    if (goal.length > ProfileLimits.answerMaxLength) {
      goal = goal.substring(0, ProfileLimits.answerMaxLength);
    }
    final p = ProfileValidator.normalize(saved).copyWith(
      goal: goal,
      experience: saved.experience.trim(),
      sports: _canonicalSports(saved.sports),
    );
    _baseline = p;
    _name.text = p.name;
    _surname.text = p.surname;
    _age.text = p.age;
    _weight.text = p.weight;
    _height.text = p.height;
    if (AppConstants.fitnessGoals.contains(p.goal)) {
      _goalChoice = p.goal;
      _goalOther.text = '';
    } else if (p.goal.isNotEmpty) {
      _goalChoice = _otherGoal;
      _goalOther.text = p.goal;
    } else {
      _goalChoice = '';
      _goalOther.text = '';
    }
    _level = p.experience;
    _sports = List.of(p.sports);
    _touched.clear();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final dirtyFlag = _dirtyFlag;
    Future.microtask(() {
      try {
        dirtyFlag.state = false;
      } catch (_) {}
    });
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _goalValue =>
      _goalChoice == _otherGoal ? _goalOther.text.trim() : _goalChoice;

  UserProfile _current() => UserProfile(
        name: _name.text,
        surname: _surname.text,
        age: _age.text,
        weight: _weight.text,
        height: _height.text,
        goal: _goalValue,
        experience: _level,
        sports: _sports,
      );

  bool get _dirty {
    final a = ProfileValidator.normalize(_current());
    final b = _baseline;
    return a.name != b.name ||
        a.surname != b.surname ||
        a.age != b.age ||
        a.weight != b.weight ||
        a.height != b.height ||
        a.goal != b.goal ||
        a.experience != b.experience ||
        a.sports.join('\u0000') != b.sports.join('\u0000');
  }

  Map<String, ProfileError> get _errors =>
      ProfileValidator.validate(_current());

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final profile = ProfileValidator.normalize(_current());
    await ref.read(profileProvider.notifier).saveProfile(profile);
    // Uploaded in the background; retried later if offline.
    final answersEdited = profile.goal != _baseline.goal ||
        profile.experience != _baseline.experience ||
        profile.sports.join('\u0000') != _baseline.sports.join('\u0000');
    unawaited(ref
        .read(accountServiceProvider)
        ?.profileChanged(answersEdited: answersEdited));
    if (!mounted) return;
    setState(() => _apply(profile));
    messenger.showSnackBar(SnackBar(content: Text(l10n.aboutMeSaved)));
  }

  String? _errorText(String field) {
    if (!_touched.contains(field) && !_dirty) return null;
    final e = _errors[field];
    if (e == null) return null;
    return aboutMeErrorText(AppLocalizations.of(context), e);
  }

  void _toggleSport(String sport) {
    setState(() {
      if (_sports.contains(sport)) {
        _sports = [..._sports]..remove(sport);
        _sportsLimitHit = false;
      } else if (_sports.length >= ProfileLimits.sportsMax) {
        _sportsLimitHit = true;
      } else {
        _sports = [..._sports, sport];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(accountEmailProvider).valueOrNull;
    final dirty = _dirty;
    final canSave = dirty && _errors.isEmpty;
    if (ref.read(aboutMeDirtyProvider) != dirty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(aboutMeDirtyProvider.notifier).state = dirty;
      });
    }

    final fullName = [_baseline.name, _baseline.surname]
        .where((s) => s.isNotEmpty)
        .join(' ');

    Widget field({
      required String id,
      required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
      bool last = false,
    }) {
      final error = _errorText(id);
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.caption.copyWith(color: palette.textSecondary)),
            TextField(
              key: Key('about-$id'),
              controller: controller,
              keyboardType: keyboardType,
              textInputAction:
                  last ? TextInputAction.done : TextInputAction.next,
              onChanged: (_) => _touched.add(id),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: AppText.bodyStrong.copyWith(color: palette.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                errorText: error,
                errorMaxLines: 2,
              ),
            ),
          ],
        ),
      );
    }

    final knownSports = {for (final s in Sport.values) s.label};
    final extraSports = _baseline.sports
        .followedBy(_sports)
        .where((s) => !knownSports.contains(s))
        .toSet();

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmDiscardChanges(context)) {
          ref.read(aboutMeDirtyProvider.notifier).state = false;
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              children: [
                ScreenTitle(l10n.aboutMeTitle),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: palette.tile,
                          child: Icon(Icons.person,
                              size: 40, color: palette.textSecondary),
                        ),
                      ),
                      // No placeholder handle: the name shows once typed.
                      if (fullName.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: Text(
                            fullName,
                            style: AppText.headingM
                                .copyWith(color: palette.textPrimary),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      aboutMeList(palette, [
                        field(
                            id: 'name',
                            controller: _name,
                            label: l10n.profileFieldName),
                        aboutMeDivider(palette),
                        field(
                            id: 'surname',
                            controller: _surname,
                            label: l10n.profileFieldSurname),
                        aboutMeDivider(palette),
                        field(
                            id: 'age',
                            controller: _age,
                            label: l10n.age,
                            keyboardType: TextInputType.number),
                        aboutMeDivider(palette),
                        field(
                            id: 'weight',
                            controller: _weight,
                            label: l10n.profileFieldWeightKg,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                        aboutMeDivider(palette),
                        field(
                            id: 'height',
                            controller: _height,
                            label: l10n.profileFieldHeightCm,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            last: true),
                      ]),
                      aboutMeSection(
                        palette,
                        l10n.aboutMeGoal,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final g in AppConstants.fitnessGoals)
                                  aboutMePill(
                                    palette,
                                    aboutMeGoalLabel(l10n, g),
                                    _goalChoice == g,
                                    () => setState(() => _goalChoice = g),
                                    key: Key('about-goal-$g'),
                                  ),
                                aboutMePill(
                                  palette,
                                  l10n.aboutMeGoalOther,
                                  _goalChoice == _otherGoal,
                                  () =>
                                      setState(() => _goalChoice = _otherGoal),
                                  key: const Key('about-goal-other'),
                                ),
                              ],
                            ),
                            if (_goalChoice == _otherGoal) ...[
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                key: const Key('about-goal-text'),
                                controller: _goalOther,
                                maxLength: ProfileLimits.answerMaxLength,
                                textInputAction: TextInputAction.done,
                                onTapOutside: (_) => FocusManager
                                    .instance.primaryFocus
                                    ?.unfocus(),
                                decoration: InputDecoration(
                                    hintText: l10n.aboutMeGoalOtherHint),
                              ),
                            ],
                          ],
                        ),
                      ),
                      aboutMeSection(
                        palette,
                        l10n.aboutMeLevel,
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (_level.isNotEmpty && !_levels.contains(_level))
                              aboutMePill(
                                palette,
                                _level,
                                true,
                                () => setState(() => _level = ''),
                                key: Key('about-level-extra-$_level'),
                              ),
                            for (final lv in _levels)
                              aboutMePill(
                                palette,
                                aboutMeLevelLabel(l10n, lv),
                                _level == lv,
                                () => setState(() => _level = lv),
                                key: Key('about-level-$lv'),
                              ),
                          ],
                        ),
                      ),
                      aboutMeSection(
                        palette,
                        l10n.aboutMeSports,
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final s in Sport.values)
                              aboutMePill(
                                palette,
                                s.localizedLabel(l10n),
                                _sports.contains(s.label),
                                () => _toggleSport(s.label),
                                key: Key('about-sport-${s.name}'),
                              ),
                            for (final s in extraSports)
                              aboutMePill(
                                palette,
                                s,
                                _sports.contains(s),
                                () => _toggleSport(s),
                                key: Key('about-sport-extra-$s'),
                              ),
                          ],
                        ),
                        note: _sportsLimitHit ? l10n.aboutMeSportsLimit : null,
                      ),
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        aboutMeList(palette, [
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 20, color: palette.textSecondary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.aboutMeEmail,
                                          style: AppText.caption.copyWith(
                                              color: palette.textSecondary)),
                                      Text(email,
                                          key: const Key('account-email'),
                                          style: AppText.bodyStrong.copyWith(
                                              color: palette.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  child: AppButton(
                    key: const Key('about-save'),
                    label: l10n.aboutMeSave,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: canSave ? _save : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
