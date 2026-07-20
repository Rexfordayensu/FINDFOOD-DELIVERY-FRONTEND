import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';

class OrderChatScreen extends StatefulWidget {
  final Order order;
  final String otherPartyLabel; // e.g. "Kofi's Kitchen" or "Your rider"

  const OrderChatScreen({
    super.key,
    required this.order,
    required this.otherPartyLabel, required int orderId,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final msgs = await ApiService.getChatMessages(
          token: auth.token!, orderId: widget.order.id);
      if (!mounted) return;
      final wasAtBottom = _isNearBottom();
      setState(() => _messages = msgs);
      if (wasAtBottom || !silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  bool _isNearBottom() {
    if (!_scrollCtrl.hasClients) return true;
    return _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 100;
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await ApiService.sendChatMessage(
          token: auth.token!, orderId: widget.order.id, message: text);
      await _load(silent: true);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final bg = AppColors.bg(context);
    
    // Dynamically infer role type for quick replies
    String partyRole = 'restaurant';
    if (widget.otherPartyLabel.toLowerCase().contains('rider')) {
      partyRole = 'rider';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentDim,
              child: Text(
                widget.otherPartyLabel.isNotEmpty ? widget.otherPartyLabel[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherPartyLabel, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
                  Text(
                    'Order #${widget.order.id}',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textHint(context)),
                            const SizedBox(height: 14),
                            Text('No messages yet', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Send a message to get started', style: TextStyle(color: AppColors.textSecondary(context))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMine = msg['sender_id'] == auth.userId;
                          return _MessageBubble(
                            message: msg['message'] ?? '',
                            isMine: isMine,
                          );
                        },
                      ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _quickReplies(partyRole)
                  .map((q) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () { _msgCtrl.text = q; _send(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Text(q, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 12)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        style: TextStyle(color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppColors.textHint(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      child: _sending
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _quickReplies(String role) {
    switch (role) {
      case 'rider': return ['Where are you now?', "Please call me when you arrive", 'Thank you!'];
      case 'restaurant': return ['Is my food ready?', 'Can I change an item?', 'Thank you'];
      default: return ['Hello', 'Thank you!', 'OK'];
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.accent : AppColors.card(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppColors.border(context)),
        ),
        child: Text(message, style: TextStyle(color: isMine ? Colors.black : AppColors.textPrimary(context), fontSize: 14)),
      ),
    );
  }
}
