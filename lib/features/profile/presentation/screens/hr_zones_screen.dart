import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/domain/hr_zones.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Heart-rate zones from the user's own rest / max / LTHR.
class HrZonesScreen extends ConsumerStatefulWidget {
  const HrZonesScreen({super.key});

  @override
  ConsumerState<HrZonesScreen> createState() => _HrZonesScreenState();
}

class _HrZonesScreenState extends ConsumerState<HrZonesScreen> {
  bool _friel = false;

  String _zoneLabel(AppLocalizations l10n, int index) {
    final name = _friel
        ? const ['Z1', 'Z2', 'Z3', 'Z4', 'Z5a', 'Z5b', 'Z5c'][index]
        : 'Z${index + 1}';
    final label = _friel
        ? [
            l10n.hrZoneRecovery,
            l10n.hrZoneAerobic,
            l10n.hrZoneTempo,
            l10n.hrZoneSubThr,
            l10n.hrZoneThreshPlus,
            l10n.hrZoneCapacity,
            l10n.hrZoneAnaerobic,
          ][index]
        : [
            l10n.hrZoneRecovery,
            l10n.hrZoneAerobic,
            l10n.hrZoneTempo,
            l10n.hrZoneThreshold,
            l10n.hrZoneVo2max,
          ][index];
    return '$name $label';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final perf = ref.watch(performanceProfileProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final age = int.tryParse(profile?.age.trim() ?? '');
    final rest = perf.restingHr;
    final max = perf.maxHr;
    final lthr = perf.lthr;

    Widget stat(int? value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.tile,
              borderRadius: AppRadius.mdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value == null ? '—' : '$value',
                    style:
                        AppText.headingL.copyWith(color: palette.textPrimary)),
                Text(label,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        );

    Widget segment(String label, bool selected, Key key, VoidCallback onTap) =>
        Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? palette.pillSelected : palette.buttonMuted,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(
                        color: selected
                            ? palette.onPillSelected
                            : palette.textPrimary)),
              ),
            ),
          ),
        );

    Widget note(String text, {Key? key, Color? color}) => Text(text,
        key: key,
        style: AppText.bodyRegular
            .copyWith(color: color ?? palette.textSecondary));

    Widget zoneRow(int index, String range, double from, double to,
        {required bool last}) {
      final danger = index == (_friel ? 6 : 4);
      return Container(
        decoration: BoxDecoration(
          border:
              last ? null : Border(bottom: BorderSide(color: palette.border)),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(_zoneLabel(l10n, index),
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, c) => SizedBox(
                  height: 8,
                  child: Stack(children: [
                    Container(
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: AppRadius.fullAll,
                      ),
                    ),
                    Positioned(
                      left: c.maxWidth * from,
                      width: c.maxWidth * (to - from),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: danger ? palette.danger : palette.accent,
                          borderRadius: AppRadius.fullAll,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 3,
              child: Text(range,
                  textAlign: TextAlign.end,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
      );
    }

    Widget header(String left, String mid, String right) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Expanded(
                flex: 5,
                child: Text(left,
                    style: AppText.microStrong
                        .copyWith(color: palette.textSecondary))),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
                flex: 3,
                child: Text(mid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.microStrong
                        .copyWith(color: palette.textSecondary))),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
                flex: 3,
                child: Text(right,
                    textAlign: TextAlign.end,
                    style: AppText.microStrong
                        .copyWith(color: palette.textSecondary))),
          ]),
        );

    Widget table(List<Widget> rows, String mid) => Container(
          decoration: BoxDecoration(
            color: palette.tile,
            borderRadius: AppRadius.mdAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            header(l10n.hrZonesColZone, mid, l10n.hrZonesColBpm),
            Divider(height: 1, color: palette.border),
            ...rows,
          ]),
        );

    final children = <Widget>[];

    // Zones table: Karvonen needs rest + max, Friel needs LTHR.
    if (!_friel) {
      children.add(Row(children: [
        Expanded(
            child: Text(l10n.hrZonesKarvonenTitle,
                style: AppText.headingS.copyWith(color: palette.textPrimary))),
        Text(l10n.hrZonesKarvonenSub,
            style: AppText.caption.copyWith(color: palette.textSecondary)),
      ]));
      children.add(const SizedBox(height: AppSpacing.sm));
      if (rest != null && max != null && max > rest) {
        final zones = karvonenZones(rest, max);
        final span = (max - rest).toDouble();
        children.add(table([
          for (var i = 0; i < zones.length; i++)
            zoneRow(
              i,
              zones[i].karvonenRange,
              (zones[i].low - rest) / span,
              (zones[i].high! - rest) / span,
              last: i == zones.length - 1,
            ),
        ], l10n.hrZonesColHrr));
        children.add(const SizedBox(height: AppSpacing.sm));
        children.add(note(l10n.hrZonesFormula(max - rest)));
        children.add(const SizedBox(height: AppSpacing.md));
        children.add(Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: AppRadius.mdAll,
          ),
          child: Text(l10n.hrZonesZ2Tip(zones[1].low, zones[1].high!),
              style: AppText.bodyRegular.copyWith(color: palette.textPrimary)),
        ));
      } else {
        children.add(
            note(l10n.hrZonesNeedRates, key: const Key('zones-need-rates')));
      }
    } else {
      children.add(Row(children: [
        Expanded(
            child: Text(l10n.hrZonesFrielTitle,
                style: AppText.headingS.copyWith(color: palette.textPrimary))),
        if (lthr != null)
          Text(l10n.hrZonesLthrValue(lthr),
              style: AppText.caption.copyWith(color: palette.textSecondary)),
      ]));
      children.add(const SizedBox(height: AppSpacing.sm));
      if (lthr != null) {
        final zones = frielZones(lthr);
        final top = lthr * 1.1;
        children.add(table([
          for (var i = 0; i < zones.length; i++)
            zoneRow(
              i,
              zones[i].frielRange(first: i == 0),
              (i == 0 ? lthr * 0.7 : zones[i].low) / top,
              (zones[i].high ?? top) / top,
              last: i == zones.length - 1,
            ),
        ], l10n.hrZonesColLthr));
        children.add(const SizedBox(height: AppSpacing.sm));
        children.add(note(l10n.hrZonesFrielNote));
      } else {
        children
            .add(note(l10n.hrZonesNeedLthr, key: const Key('zones-need-lthr')));
      }
    }

    // Measuring help, with the Tanaka estimate when max HR is unknown.
    children.add(const SizedBox(height: AppSpacing.md));
    children.add(Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.hrZonesHowTitle,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          note(l10n.hrZonesHowBody),
          if (max == null) ...[
            const SizedBox(height: AppSpacing.xs),
            if (age != null && age > 0)
              note(l10n.hrZonesTanaka(age, tanakaMaxHr(age)),
                  key: const Key('zones-tanaka'))
            else ...[
              note(l10n.hrZonesNeedAge, key: const Key('zones-need-age')),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('zones-complete-profile'),
                label: l10n.hrZonesCompleteProfile,
                style: AppButtonStyle.secondary,
                onPressed: () => context.push(AppRouter.editProfile),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xs),
          note(l10n.hrZonesRestingTip),
        ],
      ),
    ));

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(l10n.hrZonesTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Row(children: [
                    stat(max, l10n.hrZonesMax),
                    const SizedBox(width: AppSpacing.xs),
                    stat(rest, l10n.hrZonesRest),
                    const SizedBox(width: AppSpacing.xs),
                    stat(lthr, l10n.hrZonesLthr),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const Key('zones-edit'),
                    label: l10n.hrZonesEdit,
                    icon: Icons.edit_outlined,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => context.push(AppRouter.editProfile),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    segment(
                        l10n.hrZonesKarvonen,
                        !_friel,
                        const Key('zones-karvonen'),
                        () => setState(() => _friel = false)),
                    const SizedBox(width: AppSpacing.xs),
                    segment(l10n.hrZonesFriel, _friel, const Key('zones-friel'),
                        () => setState(() => _friel = true)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
