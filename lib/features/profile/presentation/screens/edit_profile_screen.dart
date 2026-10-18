import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const hrMin = 30, hrMax = 230, ftpMin = 50, ftpMax = 600;
const fiveKMin = Duration(minutes: 12), fiveKMax = Duration(minutes: 60);

/// "20:31" to a Duration; null when it isn't min:sec.
Duration? parseMinSec(String text) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final sec = int.parse(m.group(2)!);
  if (sec > 59) return null;
  return Duration(minutes: int.parse(m.group(1)!), seconds: sec);
}

String formatMinSec(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Edit profile: body numbers (saved through the profile provider like
/// About me, so they sync) and performance numbers (kept on the device).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  final _resting = TextEditingController();
  final _max = TextEditingController();
  final _lthr = TextEditingController();
  final _ftp = TextEditingController();
  final _fiveK = TextEditingController();
  Sex? _sex;

  /// The stored profile the base fields are merged into (keeps surname,
  /// goal, experience and sports as they are).
  UserProfile _stored =
      UserProfile(name: '', surname: '', age: '', weight: '', height: '');
  final Map<String, String> _errors = {};

  List<TextEditingController> get _controllers =>
      [_name, _weight, _height, _age, _resting, _max, _lthr, _ftp, _fiveK];

  @override
  void initState() {
    super.initState();
    final perf = ref.read(performanceProfileProvider);
    _sex = perf.sex;
    _resting.text = perf.restingHr?.toString() ?? '';
    _max.text = perf.maxHr?.toString() ?? '';
    _lthr.text = perf.lthr?.toString() ?? '';
    _ftp.text = perf.ftpW?.toString() ?? '';
    _fiveK.text = perf.fiveK == null ? '' : formatMinSec(perf.fiveK!);
    unawaited(_load());
  }

  Future<void> _load() async {
    final saved = await ref.read(profileRepositoryProvider).getProfile();
    if (!mounted || saved == null) return;
    final p = ProfileValidator.normalize(saved);
    setState(() {
      _stored = saved;
      _name.text = p.name;
      _weight.text = p.weight;
      _height.text = p.height;
      _age.text = p.age;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _baseErrorText(AppLocalizations l10n, ProfileError e) =>
      switch (e.kind) {
        ProfileErrorKind.nameRequired => l10n.profileErrNameRequired,
        ProfileErrorKind.nameTooLong => l10n.profileErrNameTooLong,
        ProfileErrorKind.surnameTooLong => l10n.profileErrSurnameTooLong,
        ProfileErrorKind.ageRequired => l10n.profileErrAgeRequired,
        ProfileErrorKind.ageWhole => l10n.profileErrAgeWhole,
        ProfileErrorKind.ageRange => l10n.profileErrAgeRange(e.min, e.max),
        ProfileErrorKind.weightRequired => l10n.profileErrWeightRequired,
        ProfileErrorKind.weightNumber => l10n.profileErrWeightNumber,
        ProfileErrorKind.weightRange =>
          l10n.profileErrWeightRange(e.min, e.max),
        ProfileErrorKind.heightRequired => l10n.profileErrHeightRequired,
        ProfileErrorKind.heightNumber => l10n.profileErrHeightNumber,
        ProfileErrorKind.heightRange =>
          l10n.profileErrHeightRange(e.min, e.max),
      };

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errors = <String, String>{};

    final base = _stored.copyWith(
      name: _name.text,
      weight: _weight.text,
      height: _height.text,
      age: _age.text,
    );
    for (final e in ProfileValidator.validate(base).entries) {
      if (const {'name', 'weight', 'height', 'age'}.contains(e.key)) {
        errors[e.key] = _baseErrorText(l10n, e.value);
      }
    }

    // Optional integer in [min, max]; blank means "not set".
    int? intField(String id, TextEditingController c, int min, int max,
        String Function() message) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      final v = int.tryParse(t);
      if (v == null || v < min || v > max) {
        errors[id] = message();
        return null;
      }
      return v;
    }

    String hrMsg() => l10n.editProfileErrHr(hrMin, hrMax);
    final resting = intField('resting', _resting, hrMin, hrMax, hrMsg);
    final max = intField('max', _max, hrMin, hrMax, hrMsg);
    final lthr = intField('lthr', _lthr, hrMin, hrMax, hrMsg);
    final ftp = intField('ftp', _ftp, ftpMin, ftpMax,
        () => l10n.editProfileErrFtp(ftpMin, ftpMax));
    if (resting != null &&
        max != null &&
        resting >= max &&
        !errors.containsKey('resting')) {
      errors['resting'] = l10n.editProfileErrRestMax;
    }
    Duration? fiveK;
    final fiveKText = _fiveK.text.trim();
    if (fiveKText.isNotEmpty) {
      fiveK = parseMinSec(fiveKText);
      if (fiveK == null || fiveK < fiveKMin || fiveK > fiveKMax) {
        fiveK = null;
        errors['5k'] = l10n.editProfileErrFiveK;
      }
    }

    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      return;
    }

    final profile = ProfileValidator.normalize(base);
    await ref.read(profileProvider.notifier).saveProfile(profile);
    // Uploaded in the background; retried later if offline.
    unawaited(ref.read(accountServiceProvider)?.profileChanged());
    await ref.read(performanceProfileProvider.notifier).save(
          PerformanceProfile(
            sex: _sex,
            restingHr: resting,
            maxHr: max,
            lthr: lthr,
            ftpW: ftp,
            fiveK: fiveK,
          ),
        );
    if (!mounted) return;
    setState(() {
      _stored = profile;
      _errors.clear();
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.aboutMeSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    Widget field(String id, TextEditingController controller, String label,
        {String? unit,
        TextInputType? keyboardType,
        bool last = false,
        String? hint}) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.caption.copyWith(color: palette.textSecondary)),
            TextField(
              key: Key('edit-$id'),
              controller: controller,
              keyboardType: keyboardType,
              textInputAction:
                  last ? TextInputAction.done : TextInputAction.next,
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
                hintText: hint,
                suffixText: unit,
                suffixStyle:
                    AppText.caption.copyWith(color: palette.textSecondary),
                errorText: _errors[id],
                errorMaxLines: 2,
              ),
            ),
          ],
        ),
      );
    }

    Widget divider() => Divider(height: 1, color: palette.border);

    Widget group(String title, List<Widget> rows) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: palette.tile,
                  borderRadius: AppRadius.mdAll,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: rows),
              ),
            ],
          ),
        );

    Widget sexPill(String label, Sex value) {
      final selected = _sex == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: Key('edit-sex-${value.name}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _sex = selected ? null : value),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? palette.pillSelected : palette.buttonMuted,
                borderRadius: AppRadius.smAll,
              ),
              child: Text(label,
                  style: AppText.bodyStrong.copyWith(
                      color: selected
                          ? palette.onPillSelected
                          : palette.textPrimary)),
            ),
          ),
        ),
      );
    }

    const decimal = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              ScreenTitle(l10n.editProfileTitle),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    group(l10n.editProfileBody, [
                      field('name', _name, l10n.profileFieldName),
                      divider(),
                      field('weight', _weight, l10n.profileFieldWeightKg,
                          keyboardType: decimal),
                      divider(),
                      field('height', _height, l10n.profileFieldHeightCm,
                          keyboardType: decimal),
                      divider(),
                      field('age', _age, l10n.age,
                          unit: l10n.unitYears,
                          keyboardType: TextInputType.number),
                      divider(),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.editProfileSex,
                                style: AppText.caption
                                    .copyWith(color: palette.textSecondary)),
                            const SizedBox(height: AppSpacing.xs),
                            Row(children: [
                              sexPill(l10n.sexMale, Sex.male),
                              const SizedBox(width: AppSpacing.xs),
                              sexPill(l10n.sexFemale, Sex.female),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                    group(l10n.editProfilePerformance, [
                      field('resting', _resting, l10n.editProfileRestingHr,
                          unit: l10n.unitBpm,
                          keyboardType: TextInputType.number),
                      divider(),
                      field('max', _max, l10n.editProfileMaxHr,
                          unit: l10n.unitBpm,
                          keyboardType: TextInputType.number),
                      divider(),
                      field('lthr', _lthr, l10n.editProfileLthr,
                          unit: l10n.unitBpm,
                          keyboardType: TextInputType.number),
                      divider(),
                      field('ftp', _ftp, l10n.editProfileFtp,
                          unit: l10n.unitWatts,
                          keyboardType: TextInputType.number),
                      divider(),
                      field('5k', _fiveK, l10n.editProfileFiveK,
                          unit: l10n.unitMinSec,
                          hint: '20:31',
                          keyboardType: TextInputType.datetime,
                          last: true),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: AppButton(
                  key: const Key('edit-save'),
                  label: l10n.editProfileSave,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
