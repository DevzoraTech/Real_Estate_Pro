import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }
    final userId = user.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          // Filter chats where user is a participant
          final userChats =
              docs.where((doc) {
                final chatId = doc.id;
                return chatId.contains(userId);
              }).toList();
          if (userChats.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }
          return ListView.builder(
            itemCount: userChats.length,
            itemBuilder: (context, index) {
              final chatDoc = userChats[index];
              final chatId = chatDoc.id;
              final ids = chatId.split('_');
              final otherUserId = ids.firstWhere(
                (id) => id != userId,
                orElse: () => '',
              );
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                builder: (context, msgSnapshot) {
                  final lastMsgDoc =
                      msgSnapshot.data?.docs.isNotEmpty == true
                          ? msgSnapshot.data!.docs.first
                          : null;
                  final lastMsg =
                      lastMsgDoc != null
                          ? (lastMsgDoc.data()
                                  as Map<String, dynamic>)['message'] ??
                              ''
                          : '';
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                    builder: (context, userSnapshot) {
                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;
                      final otherName = userData?['displayName'] ?? 'User';
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(otherName),
                        subtitle: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatPage(
                                    agentId: otherUserId,
                                    agentName: otherName,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
