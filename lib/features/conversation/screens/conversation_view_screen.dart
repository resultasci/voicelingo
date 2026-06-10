import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_handler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/models/conversation.dart';
import '../../../core/theme/app_theme.dart';
import '../services/conversation_repository.dart';

final _messagesProvider = FutureProvider.autoDispose
    .family<List<StoredMessage>, String>((ref, conversationId) {
  return ref
      .watch(conversationRepositoryProvider)
      .fetchMessages(conversationId);
});

class ConversationViewScreen extends ConsumerWidget {
  final String conversationId;
  const ConversationViewScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final c = context.c;
    final messages = ref.watch(_messagesProvider(conversationId));
    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: [
                    Semantics(
                      label: l.common_back,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: c.primaryContainer, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(l.convView_title,
                        style: AppText.title(20,
                            color: c.primary, weight: FontWeight.w600)),
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
                      child: Text(getErrorMessage(context, e),
                          textAlign: TextAlign.center,
                          style: AppText.body(13, color: c.error)),
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
    final l = AppL10n.of(context);
    final c = context.c;
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
                      color: c.primaryContainer.withOpacity(0.10),
                      border: Border.all(
                          color: c.primaryContainer.withOpacity(0.4)),
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
                          color: c.primary, weight: FontWeight.w500),
                    ),
                  )
                : GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    radius: 18,
                    child: Text(
                      message.content,
                      style: AppText.ink(14, color: c.ink),
                    ),
                  ),
          ),
          if (isUser && message.evalScore != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${l.convView_score(message.evalScore!)}'
                '${message.evalSuggestion?.isNotEmpty == true ? " · ${message.evalSuggestion}" : ""}',
                style: AppText.label(10,
                    color: c.primaryFixedDim, weight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
