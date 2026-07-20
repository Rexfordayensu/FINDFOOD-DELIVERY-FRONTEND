import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/providers.dart';

/// Canonical chat screen used by customer tracking, restaurant dashboard,
/// and rider dashboard. Connects via WebSocket for instant delivery —
/// messages from the other party appear live, no polling delay.
class ChatScreen extends StatefulWidget {
  final int orderId;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.otherPartyName, required String otherPartyRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  final Set<int> _messageIds = {}; // dedupe guard between REST + WebSocket
  bool _loading = true;
  String _error = '';
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  WebSocketChannel? _channel;
  bool _connected = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Load message history once via REST ─────────────────────────────────
  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final msgs = await ChatMessage.getMessages(
          token: auth.token!, orderId: widget.orderId);
      setState(() {
        _messages = msgs as List<ChatMessage>;
        _messageIds.addAll(_messages.map((m) => m.id));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Connect to the live WebSocket for this order's chat ────────────────
  void _connectWebSocket() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    // Derive ws:// URL from the existing http:// base URL
    final wsBase = ApiService.baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse(
        '$wsBase/ws/orders/${widget.orderId}/chat?token=${auth.token}');

    try {
      _channel = WebSocketChannel.connect(uri);
      setState(() => _connected = true);

      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final incoming = ChatMessage.fromJson({
              ...data,
              'is_mine': data['sender_id'] == auth.userId,
            });
            // Skip if we already have this message (e.g. we sent it ourselves)
            if (_messageIds.contains(incoming.id)) return;
            setState(() {
              _messages.add(incoming);
              _messageIds.add(incoming.id);
            });
            _scrollToBottom();
          } catch (_) {
            // Ignore malformed frames
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (_) => _handleDisconnect(),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;
    setState(() => _connected = false);
    // Auto-reconnect after a short delay so the chat recovers from
    // brief network drops without the user having to leave the screen
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _connectWebSocket();
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      // Sent via REST; backend broadcasts it to the other party's WebSocket.
      // We add it locally immediately for a snappy feel on our own screen.
      final msg = await ApiService.sendMessage(
        token: auth.token!,
        orderId: widget.orderId,
        content: text,
      );
      
      final chatMsg = msg as ChatMessage;

      if (!_messageIds.contains(chatMsg.id)) {
        setState(() {
          _messages.add(msg);
          _messageIds.add(msg.id);
        });
        _scrollToBottom();
      }
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accentDim,
              child: Text(
                widget.otherPartyName.isNotEmpty
                    ? widget.otherPartyName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.otherPartyName,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: _connected ? AppTheme.success : AppTheme.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connected ? 'Live' : 'Reconnecting...',
                        style: TextStyle(
                          fontSize: 11,
                          color: _connected ? AppTheme.success : AppTheme.textHint,
                        ),
                      ),
                    ],
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent))
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  size: 48, color: AppColors.textHint(context)),
                              const SizedBox(height: 12),
                              Text(_error,
                                  style: TextStyle(
                                      color: AppColors.textSecondary(context)),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                  onPressed: _loadHistory,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: AppColors.textHint(context)),
                                const SizedBox(height: 12),
                                Text('No messages yet',
                                    style: TextStyle(
                                        color:
                                            AppColors.textSecondary(context))),
                                const SizedBox(height: 4),
                                Text('Say hello to get started!',
                                    style: TextStyle(
                                        color: AppColors.textHint(context),
                                        fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) =>
                                _MessageBubble(message: _messages[i]),
                          ),
          ),

          // ── Input bar ────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border:
                    Border(top: BorderSide(color: AppColors.border(context))),
              ),
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
                          hintStyle:
                              TextStyle(color: AppColors.textHint(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.black, size: 20),
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
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeStr =
        '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderRole.isNotEmpty
                      ? message.senderRole[0].toUpperCase() +
                          message.senderRole.substring(1)
                      : '',
                  style: TextStyle(
                      color: AppColors.textHint(context), fontSize: 11),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppTheme.accent : AppColors.card(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine
                    ? null
                    : Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.black : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(timeStr,
                  style: TextStyle(
                      color: AppColors.textHint(context), fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}