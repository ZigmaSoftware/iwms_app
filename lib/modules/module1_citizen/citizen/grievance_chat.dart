// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../../api/chat_proxy.dart';
// import '../../../router/app_router.dart';

// class GrievanceChatScreen extends StatefulWidget {
//   const GrievanceChatScreen({super.key});

//   @override
//   State<GrievanceChatScreen> createState() => _GrievanceChatScreenState();
// }

// class _GrievanceChatScreenState extends State<GrievanceChatScreen> {
//   final ChatProxyApi _chatProxyApi = ChatProxyApi();
//   final TextEditingController _inputController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();

//   final List<_ChatMessage> _messages = <_ChatMessage>[
//     _ChatMessage(
//       role: ChatRole.assistant,
//       text: 'Hello! I am here to assist with your grievance. '
//           'Please describe any issue related to waste collection, schedules, '
//           'or site experience and I will help you draft or track a ticket.',
//     ),
//   ];

//   bool _isSending = false;

//   @override
//   void dispose() {
//     _inputController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSend() async {
//     final text = _inputController.text.trim();
//     if (text.isEmpty || _isSending) return;

//     setState(() {
//       _messages.add(_ChatMessage(role: ChatRole.user, text: text));
//       _isSending = true;
//     });

//     _inputController.clear();
//     _scrollToBottom();

//     try {
//       final prompt = _messages
//           .map((message) => {
//                 'role': message.role.apiRole,
//                 'content': message.text,
//               })
//           .toList(growable: false);

//       final response = await _chatProxyApi.sendPrompt(messages: prompt);
//       setState(() {
//         _messages.add(_ChatMessage(role: ChatRole.assistant, text: response));
//       });
//     } catch (error) {
//       setState(() {
//         _messages.add(
//           _ChatMessage(
//             role: ChatRole.assistant,
//             text: 'I was unable to reach our support service. '
//                 'Please try again later or contact the helpline. '
//                 'Details: $error',
//             isError: true,
//           ),
//         );
//       });
//     } finally {
//       setState(() => _isSending = false);
//       _scrollToBottom();
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollController.hasClients) return;
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent + 60,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI Grievance Assistant'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             final router = GoRouter.of(context);
//             if (router.canPop()) {
//               router.pop();
//             } else {
//               router.go(AppRoutePaths.citizenHome);
//             }
//           },
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 controller: _scrollController,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//                 itemCount: _messages.length,
//                 itemBuilder: (context, index) {
//                   final message = _messages[index];
//                   return _ChatBubble(message: message);
//                 },
//               ),
//             ),
//             const Divider(height: 1),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _inputController,
//                       maxLines: null,
//                       textCapitalization: TextCapitalization.sentences,
//                       decoration: InputDecoration(
//                         hintText: 'Describe your grievance or question...',
//                         filled: true,
//                         fillColor: theme.colorScheme.surfaceContainerHighest
//                             .withValues(alpha: 0.5),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(18),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 12,
//                         ),
//                       ),
//                       onSubmitted: (_) => _handleSend(),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   FilledButton(
//                     onPressed: _isSending ? null : _handleSend,
//                     style: FilledButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 14),
//                       shape: const CircleBorder(),
//                     ),
//                     child: _isSending
//                         ? const SizedBox(
//                             width: 18,
//                             height: 18,
//                             child: CircularProgressIndicator(strokeWidth: 2.4),
//                           )
//                         : const Icon(Icons.send_rounded),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// enum ChatRole {
//   user('user'),
//   assistant('assistant');

//   const ChatRole(this.apiRole);
//   final String apiRole;
// }

// class _ChatMessage {
//   const _ChatMessage({
//     required this.role,
//     required this.text,
//     this.isError = false,
//   });

//   final ChatRole role;
//   final String text;
//   final bool isError;

//   bool get isUser => role == ChatRole.user;
// }

// class _ChatBubble extends StatelessWidget {
//   const _ChatBubble({required this.message});

//   final _ChatMessage message;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isUser = message.isUser;

//     final bubbleColor = message.isError
//         ? Colors.redAccent.withValues(alpha: 0.12)
//         : isUser
//             ? theme.colorScheme.primary.withValues(alpha: 0.14)
//             : theme.colorScheme.surfaceContainerHighest
//                 .withValues(alpha: 0.6);

//     final textColor = message.isError
//         ? Colors.red.shade800
//         : isUser
//             ? theme.colorScheme.primary
//             : theme.colorScheme.onSurface;

//     final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

//     final borderRadius = BorderRadius.only(
//       topLeft: const Radius.circular(18),
//       topRight: const Radius.circular(18),
//       bottomLeft: Radius.circular(isUser ? 18 : 4),
//       bottomRight: Radius.circular(isUser ? 4 : 18),
//     );

//     return Align(
//       alignment: alignment,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: bubbleColor,
//           borderRadius: borderRadius,
//         ),
//         child: Text(
//           message.text,
//           style: theme.textTheme.bodyMedium?.copyWith(
//             color: textColor,
//           ),
//         ),
//       ),
//     );
//   }
// }
