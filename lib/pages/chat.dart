// This page file renders the temporary active-bounty chat.
// Messages live under chats/{bountyId}/messages and are deleted when the request ends.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ChatPage shows realtime messages for one active bounty conversation.
class ChatPage extends StatefulWidget {
  final String bountyId;
  final String peerName;

  const ChatPage({super.key, required this.bountyId, required this.peerName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// _ChatPageState owns the message input controller and send action.
class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Uses StreamBuilder with FirebaseFirestore.
  // Implements the real-time UI for viewing and sending chat messages.
  // The purpose is to provide a live chat interface that updates automatically.
  @override
  Widget build(BuildContext context) {
    final chatRef = _firestore.collection('chats').doc(widget.bountyId);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.peerName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: chatRef.snapshots(),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.hasData && !chatSnapshot.data!.exists) {
              return const _ChatEnded();
            }

            return Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: chatRef
                        .collection('messages')
                        .orderBy('createdAt')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const _EmptyChat();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final senderId = data['senderId']?.toString();
                          final mine = senderId == _auth.currentUser?.uid;
                          return _MessageBubble(
                            text: data['text']?.toString() ?? '',
                            mine: mine,
                            createdAt: data['createdAt'],
                          );
                        },
                      );
                    },
                  ),
                ),
                _MessageInput(
                  controller: _controller,
                  onSend: () => _sendMessage(chatRef),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // This method sends one text message and updates chat preview fields.
  // Uses FirebaseFirestore add and set methods.
  // Implements the logic to save a new message to the database and update the chat's metadata.
  // The purpose is to persist the user's message and update the latest message preview.
  Future<void> _sendMessage(DocumentReference<Map<String, dynamic>> chatRef) async {
    final uid = _auth.currentUser?.uid;
    final text = _controller.text.trim();
    if (uid == null || text.isEmpty) return;

    _controller.clear();
    await chatRef.collection('messages').add({
      'senderId': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// _MessageBubble displays a single incoming or outgoing chat message.
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool mine;
  final dynamic createdAt;

  const _MessageBubble({
    required this.text,
    required this.mine,
    required this.createdAt,
  });

  // Uses basic Flutter UI widgets like Align and Container.
  // Implements a styled chat bubble for an individual message.
  // The purpose is to display the message text visually distinct for the sender and receiver.
  @override
  Widget build(BuildContext context) {
    final time = createdAt is Timestamp
        ? createdAt.toDate().toLocal().toString().substring(11, 16)
        : '';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF8B93FF) : const Color(0xFF1A1D28),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? const Color(0xFF07112C) : Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  color: mine ? const Color(0xAA07112C) : Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// _MessageInput renders the bottom text field and send button.
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  // Uses a TextField and an IconButton within a Row.
  // Implements the text input area at the bottom of the chat screen.
  // The purpose is to allow users to type and submit their messages.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        border: Border(top: BorderSide(color: Color(0xFF202845))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF12172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send),
            color: const Color(0xFF07112C),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFAAB5FF),
            ),
          ),
        ],
      ),
    );
  }
}

// _EmptyChat invites the active pair to start the conversation.
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No messages yet',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}

// _ChatEnded appears if the request ended while the chat page is open.
class _ChatEnded extends StatelessWidget {
  const _ChatEnded();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This request has ended. The conversation was deleted.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
      ),
    );
  }
}
