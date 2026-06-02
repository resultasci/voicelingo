import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_handler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/conversation.dart';
import '../../../theme/app_theme.dart';
import 'conversation_view_screen.dart';

final _historyProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const [];
  final rows = await Supabase.instance.client
      .from('conversations')
      .select()
      .eq('user_id', user.id)
      .order('updated_at', ascending: false)
      .limit(100);
  return (rows as List)
      .map((e) => ConversationSummary.fromMap(e as Map<String, dynamic>))
      .toList();
});

class ConversationHistoryScreen extends ConsumerWidget {
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final history = ref.watch(_historyProvider);
    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: history.when(
                  data: (items) => items.isEmpty
                      ? _EmptyView()
                      : RefreshIndicator(
                          color: c.primaryContainer,
                          backgroundColor: c.bgCard,
                          onRefresh: () async {
                            ref.invalidate(_historyProvider);
                            await ref.read(_historyProvider.future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _Tile(item: items[i]),
                          ),
                        ),
                  loading: () => Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.primaryContainer),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(getErrorMessage(context, e),
                              textAlign: TextAlign.center,
                              style: AppText.body(13, color: c.error)),
                          const SizedBox(height: 16),
                          GhostButton(
                            label: l.common_retry,
                            icon: Icons.refresh,
                            onTap: () => ref.invalidate(_historyProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          Semantics(
            label: l.common_back,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: c.primaryContainer, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l.convHist_title,
            style: AppText.title(20, color: c.primary, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ConversationSummary item;
  const _Tile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final title = item.title?.isNotEmpty == true
        ? item.title!
        : (item.scenario ?? l.convHist_freeChat);
    final date = '${item.updatedAt.day.toString().padLeft(2, '0')}.'
        '${item.updatedAt.month.toString().padLeft(2, '0')}.'
        '${item.updatedAt.year}';
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationViewScreen(conversationId: item.id),
        ));
      },
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: c.primaryContainer, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.title(16,
                        color: c.primary, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: AppText.code(11, color: c.inkDim)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.primaryContainer, size: 18),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, color: c.primaryContainer, size: 32),
              const SizedBox(height: 12),
              Text(
                l.convHist_empty,
                style: AppText.body(13, color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
