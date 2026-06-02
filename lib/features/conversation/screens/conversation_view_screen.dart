import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_handler.dart';
import '../../../models/conversation.dart';
import '../../../theme/app_theme.dart';

final _messagesProvider = FutureProvider.autoDispose
    .family<List<StoredMessage>, String>((ref, conversationId) async {
  final rows = await Supabase.instance.client
      .from('messages')
      .select(
          'id,conversation_id,role,content,eval_score,eval_suggestion,eval_explanation,created_at')
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .limit(500);
  return (rows as List)
      .map((e) => StoredMessage.fromMap(e as Map<String, dynamic>))
      .toList();
});

class ConversationViewScreen extends ConsumerWidget {
  final String conversationId;
  const ConversationViewScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(_messagesProvider(conversationId));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Geri',
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.primaryContainer, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Sohbet',
                        style: AppText.title(20,
                            color: AppColors.primary, weight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: messages.when(
                  data: (items) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _Bubble(message: items[i]),
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryContainer),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(getErrorMessage(context, e),
                          textAlign: TextAlign.center,
                          style: AppText.body(13, color: AppColors.error)),
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

class _Bubble extends StatelessWidget {
  final StoredMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: isUser
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.10),
                      border: Border.all(
                          color: AppColors.primaryContainer.withOpacity(0.4)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: AppText.ink(14,
                          color: AppColors.primary, weight: FontWeight.w500),
                    ),
                  )
                : GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    radius: 18,
                    child: Text(
                      message.content,
                      style: AppText.ink(14, color: AppColors.ink),
                    ),
                  ),
          ),
          if (isUser && message.evalScore != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Puan: ${message.evalScore}'
                '${message.evalSuggestion?.isNotEmpty == true ? " · ${message.evalSuggestion}" : ""}',
                style: AppText.label(10,
                    color: AppColors.primaryFixedDim, weight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
