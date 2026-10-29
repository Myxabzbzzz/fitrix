import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/day_badge.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/features/auth/presentation/sign_in_prompt.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

enum _Cat { forYou, challenges, programs, articles }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  _Cat _cat = _Cat.forYou;
  bool _joining = false;

  bool _show(_Cat c) => _cat == _Cat.forYou || _cat == c;

  Future<void> _refresh() async {
    ref.invalidate(programsProvider);
    ref.invalidate(articlesProvider);
    ref.invalidate(challengesProvider);
    ref.invalidate(joinedChallengesProvider);
    await ref.read(challengesProvider.future);
  }

  void _promptSignIn() => showSignInPrompt(
      context, ref, AppLocalizations.of(context).discoverSignInToJoin);

  Future<void> _join(Challenge challenge) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return _promptSignIn();
    if (_joining) return;
    _joining = true;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(contentRepositoryProvider)
          .joinChallenge(challenge.id, user.id);
      ref.invalidate(joinedChallengesProvider);
    } on SignInRequired {
      if (mounted) _promptSignIn();
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.discoverJoinFailed),
        action: SnackBarAction(
          label: l10n.shopRetry,
          onPressed: () {
            if (mounted) _join(challenge);
          },
        ),
      ));
    } finally {
      _joining = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    ref.watch(currentUserProvider); // keep the auth state loaded
    final loading = [
      ref.watch(challengesProvider),
      ref.watch(programsProvider),
      ref.watch(articlesProvider),
    ].any((a) => a.isLoading && !a.hasValue);
    // Seed and server rows share ids, so both read in the app language.
    final text = ref.watch(catalogTextProvider);
    final challenges = [
      for (final c in ref.watch(challengesProvider).valueOrNull ?? const [])
        text.challenge(c),
    ];
    final programs = [
      for (final p in ref.watch(programsProvider).valueOrNull ?? const [])
        text.program(p),
    ];
    final articles = [
      for (final a in ref.watch(articlesProvider).valueOrNull ?? const [])
        text.article(a),
    ];
    final joined = ref.watch(joinedChallengesProvider).valueOrNull ?? const {};
    const pad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    final labels = {
      _Cat.forYou: l10n.discoverForYou,
      _Cat.challenges: l10n.discoverChallenges,
      _Cat.programs: l10n.discoverPrograms,
      _Cat.articles: l10n.discoverArticles,
    };

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(
              l10n.discoverTitle,
              trailing: IconButton(
                tooltip: l10n.discoverNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
                color: palette.textPrimary,
                onPressed: () {
                  final m = ScaffoldMessenger.of(context);
                  m.hideCurrentSnackBar();
                  m.showSnackBar(
                      SnackBar(content: Text(l10n.discoverNoNotifications)));
                },
              ),
            ),
            PillSelector<_Cat>(
              items: _Cat.values,
              selected: _cat,
              labelOf: (c) => labels[c]!,
              onSelected: (c) => setState(() => _cat = c),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                      top: AppSpacing.md, bottom: AppSpacing.lg),
                  children: [
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                    if (_show(_Cat.challenges) && challenges.isNotEmpty)
                      Padding(
                        padding: pad,
                        child: _ChallengeHero(
                          challenge: challenges.first,
                          joined: joined.contains(challenges.first.id),
                          onJoin: () => _join(challenges.first),
                        ),
                      ),
                    if (_show(_Cat.programs) && programs.isNotEmpty) ...[
                      Padding(
                        padding: pad.copyWith(top: AppSpacing.md),
                        child: SectionHeader(
                          l10n.discoverProgramsForYou,
                          actionLabel: l10n.discoverAll,
                          onAction: () => context.go(AppRouter.workouts),
                        ),
                      ),
                      SizedBox(
                        height: _ProgramCard.height,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: pad,
                          itemCount: programs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) =>
                              _ProgramCard(program: programs[i]),
                        ),
                      ),
                    ],
                    if (_cat == _Cat.forYou)
                      Padding(
                        padding: pad.copyWith(top: AppSpacing.md),
                        child: CoachCard(
                          eyebrow: l10n.discoverFelixEyebrow,
                          title: l10n.discoverFelixTitle,
                          message: l10n.discoverFelixMessage,
                          imageAsset: 'assets/images/felix_robot.png',
                          imageWidth: 56,
                          imageHeight: 84,
                          primaryLabel: l10n.discoverAskFelix,
                          onPrimary: () => context.go(AppRouter.felix),
                        ),
                      ),
                    if (_show(_Cat.articles) && articles.isNotEmpty) ...[
                      Padding(
                        padding: pad.copyWith(top: AppSpacing.md),
                        child: Text(l10n.discoverRead,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                      ),
                      for (final a in articles)
                        Padding(
                          padding: pad.copyWith(top: AppSpacing.xs),
                          child: _ArticleRow(article: a),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({
    required this.challenge,
    required this.joined,
    required this.onJoin,
  });

  final Challenge challenge;
  final bool joined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    // Monday-first short weekdays ("пн"): single letters are ambiguous.
    final days = [for (var i = 1; i <= 7; i++) weekdayName(context, i)];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DayBadge(label: l10n.discoverThisWeek, today: true),
          const SizedBox(height: AppSpacing.sm),
          Text(challenge.title,
              style: AppText.displayLarge.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(challenge.dailyTarget,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          // Progress isn't tracked per join date yet, so no day is filled.
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Container(
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: palette.buttonMuted,
                        borderRadius: AppRadius.smAll),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(days[i],
                          maxLines: 1,
                          style: AppText.microStrong
                              .copyWith(color: palette.textSecondary)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (joined)
            Semantics(
              label: l10n.discoverJoined,
              container: true,
              excludeSemantics: true,
              child: Container(
                key: const Key('joined-chip'),
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: palette.buttonMuted,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 16, color: palette.textPrimary),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(l10n.discoverJoined,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ],
                ),
              ),
            )
          else
            AppButton(
              label: l10n.discoverJoin,
              size: AppButtonSize.large,
              expand: true,
              onPressed: onJoin,
            ),
        ],
      ),
    );
  }
}

String _levelLabel(AppLocalizations l10n, String level) => switch (level) {
      'beginner' => l10n.programLevelBeginner,
      'medium' => l10n.programLevelMedium,
      'advanced' => l10n.programLevelAdvanced,
      _ => level,
    };

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});

  static const double height = 188;
  final Program program;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final image = program.image;
    return GestureDetector(
      key: Key('program-${program.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final m = ScaffoldMessenger.of(context);
        m.hideCurrentSnackBar();
        m.showSnackBar(
            SnackBar(content: Text(l10n.discoverProgramSoon(program.title))));
      },
      child: Container(
        width: 168,
        height: height,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration:
            BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
        child: Stack(
          children: [
            if (image != null)
              Positioned(
                right: 0,
                bottom: AppSpacing.lg,
                width: 108,
                height: 96,
                child: Image.asset('assets/images/$image.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                      color: palette.badge, borderRadius: AppRadius.fullAll),
                  child: Text(_levelLabel(l10n, program.level),
                      style: AppText.microStrong
                          .copyWith(color: palette.textPrimary)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.displayMedium
                        .copyWith(color: palette.textPrimary)),
                const Spacer(),
                Text(program.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AppRouter.article(article.id)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration:
              BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: palette.buttonMuted, borderRadius: AppRadius.smAll),
                child: Icon(Icons.article_outlined, color: palette.accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.tag.toUpperCase(),
                        style: AppText.microStrong
                            .copyWith(color: palette.accent)),
                    Text(article.title,
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textPrimary)),
                    Text(l10n.discoverMinRead(article.minutes),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
