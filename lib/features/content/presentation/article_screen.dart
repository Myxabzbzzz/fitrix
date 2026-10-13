import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final async = ref.watch(articlesProvider);
    final article = async.valueOrNull?.where((a) => a.id == id).firstOrNull;

    Widget body;
    if (article != null) {
      final paragraphs = article.body
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty);
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
        children: [
          Text(article.title,
              style: AppText.headingL.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.discoverMinRead(article.minutes),
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          for (final p in paragraphs) ...[
            const SizedBox(height: AppSpacing.md),
            Text(p,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textPrimary)),
          ],
        ],
      );
    } else if (async.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l10n.discoverArticleMissing,
            style: AppText.bodyRegular.copyWith(color: palette.textSecondary)),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(article?.tag ?? l10n.discoverArticles),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
