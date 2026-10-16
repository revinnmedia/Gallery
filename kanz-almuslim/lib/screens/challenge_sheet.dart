import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/defaults.dart';
import '../l10n.dart';
import '../services/cloud_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// طلب صداقة منافسة: رمز الصديق + آية قرآنية + كلمة اختيارية.
/// ﴿وَفِي ذَٰلِكَ فَلْيَتَنَافَسِ الْمُتَنَافِسُونَ﴾ هي الآية الافتراضية.
Future<void> showChallengeSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _ChallengeSheet(),
);

class _ChallengeSheet extends StatefulWidget {
  const _ChallengeSheet();

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  final _code = TextEditingController();
  final _note = TextEditingController();
  int _verse = 0;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _message => competitionMessage(_verse, _note.text);

  Future<void> _send() async {
    final lang = context.read<AppState>().language;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (_code.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'enterCode'))));
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await CloudService.instance.sendFriendRequest(_code.text, message: _message);
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, ok ? 'requestSent' : 'codeNotFound'))));
      if (ok) nav.pop();
    } catch (e) {
      debugPrint('Challenge request failed: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(trLang(lang, 'error'))));
    }
  }

  /// لمن ليس لديه التطبيق بعد: نرسل الدعوة مع رمزي عبر واتساب أو غيره.
  void _share() {
    final code = CloudService.instance.friendCode ?? '';
    SharePlus.instance.share(
      ShareParams(text: tr(context, 'shareInviteText', args: {'msg': _message, 'code': code})),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.emoji_events, color: KanzColors.gold, size: 40),
              const SizedBox(height: 6),
              Text(
                tr(context, 'challengeFriend'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700),
              ),
              Text(
                tr(context, 'challengeHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: tr(context, 'enterCode'),
                    hintStyle: const TextStyle(fontSize: 15, letterSpacing: 0, fontWeight: FontWeight.w400),
                    counterText: '',
                    filled: true,
                    fillColor: KanzColors.inputBox,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr(context, 'chooseVerse'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              for (var i = 0; i < competitionVerses.length; i++)
                _VerseOption(
                  text: competitionVerses[i].$1,
                  ref: competitionVerses[i].$2,
                  selected: i == _verse,
                  onTap: () => setState(() => _verse = i),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLength: 100,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: tr(context, 'addNote'),
                  filled: true,
                  fillColor: KanzColors.inputBox,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Text(tr(context, 'messagePreview'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              InviteMessage(text: _message),
              const SizedBox(height: 16),
              if (_busy)
                const Center(child: CircularProgressIndicator(color: KanzColors.cyan))
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: KanzColors.switchGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _send,
                        icon: const Icon(Icons.send),
                        label: Text(tr(context, 'sendChallenge')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: KanzColors.cyan),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share),
                        label: Text(tr(context, 'shareInvite')),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseOption extends StatelessWidget {
  const _VerseOption({required this.text, required this.ref, required this.selected, required this.onTap});
  final String text;
  final String ref;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? KanzColors.cardBlue : KanzColors.cardBlue.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? KanzColors.gold : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? KanzColors.gold : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '﴿$text﴾',
                  style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(ref, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// صندوق رسالة الدعوة (يُستخدم أيضاً لعرض الطلب الوارد).
class InviteMessage extends StatelessWidget {
  const InviteMessage({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KanzColors.bgTop.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KanzColors.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: KanzColors.paleAqua, fontSize: 17, height: 1.8),
      ),
    );
  }
}
