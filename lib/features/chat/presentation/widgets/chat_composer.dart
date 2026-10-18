
import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/presentation/providers/dictation_controller.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final DictationController dictation;
  final VoidCallback onMic;
  final VoidCallback onAdd;
  final String? pendingPhoto;
  final VoidCallback onRemovePhoto;

  const Composer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.dictation,
    required this.onMic,
    required this.onAdd,
    required this.pendingPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xxs, AppSpacing.md, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingPhoto != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.xs),
              child: _PendingPhoto(
                path: pendingPhoto!,
                removeLabel: l10n.chatRemovePhoto,
                onRemove: onRemovePhoto,
              ),
            ),
          Row(
            children: [
              IconButton(
                key: const ValueKey('chat-add'),
                icon: const Icon(Icons.add_circle_outline, size: 28),
                color: palette.textPrimary,
                tooltip: l10n.chatAddPhoto,
                onPressed: onAdd,
              ),
              Expanded(
                child: Container(
                  height: 37,
                  padding: const EdgeInsets.only(
                      left: AppSpacing.sm, right: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (enabled) onSend();
                          },
                          style: AppText.bodyRegular
                              .copyWith(color: palette.textPrimary),
                          decoration: InputDecoration.collapsed(
                            hintText:
                                AppLocalizations.of(context).chatMessageHint,
                            filled: false,
                            hintStyle: AppText.bodyRegular
                                .copyWith(color: palette.chartLabel),
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: dictation,
                        builder: (context, _) => _MicButton(
                          listening: dictation.listening,
                          tooltip: dictation.listening
                              ? l10n.chatMicStop
                              : l10n.chatMicStart,
                          onTap: onMic,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32),
                        icon: const Icon(Icons.arrow_circle_up, size: 28),
                        color: palette.textPrimary,
                        disabledColor: palette.border,
                        onPressed: enabled ? onSend : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thumbnail of the photo about to be sent, with a remove button. The
/// button's 44x44 hit area lies inside the widget's bounds.
class _PendingPhoto extends StatelessWidget {
  final String path;
  final String removeLabel;
  final VoidCallback onRemove;

  const _PendingPhoto({
    required this.path,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      key: const ValueKey('chat-pending-photo'),
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            width: 72,
            height: 72,
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: ChatPhotoImage(path: path, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: 44,
            height: 44,
            child: IconButton(
              key: const ValueKey('chat-remove-photo'),
              padding: EdgeInsets.zero,
              tooltip: removeLabel,
              onPressed: onRemove,
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: palette.background),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mic button; pulses while listening (a static highlight with reduced
/// motion).
class _MicButton extends StatefulWidget {
  final bool listening;
  final String tooltip;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.listening && !Motion.reduced(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return IconButton(
      key: const ValueKey('chat-mic'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: widget.tooltip,
      onPressed: widget.onTap,
      icon: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.listening
                ? palette.accent.withValues(alpha: 0.2 + 0.3 * _pulse.value)
                : Colors.transparent,
          ),
          child: Icon(
            widget.listening ? Icons.mic : Icons.mic_none,
            size: 22,
            color: widget.listening ? palette.accent : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
