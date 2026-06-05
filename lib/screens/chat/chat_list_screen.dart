import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/screens/chat/chat_screen.dart';
import 'package:learnxchange/services/chat_service.dart';
import 'package:learnxchange/services/user_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getChatRooms(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No conversations yet.', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          final rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomData = rooms[index].data() as Map<String, dynamic>;
              final users = List<String>.from(roomData['users'] ?? []);
              final otherUserId = users.firstWhere((id) => id != currentUserId);
              final lastMessage = roomData['lastMessage'] ?? '';
              final lastTime = (roomData['lastMessageTime'] as Timestamp?)?.toDate();

              return _ChatRoomTile(
                otherUserId: otherUserId,
                lastMessage: lastMessage,
                lastTime: lastTime,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Chat list requires an index. Check your console for the link:\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final String otherUserId;
  final String lastMessage;
  final DateTime? lastTime;

  const _ChatRoomTile({
    required this.otherUserId,
    required this.lastMessage,
    this.lastTime,
  });

  ImageProvider? _getProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(photoUrl.split(',').last));
      } catch (e) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: UserService().getUserData(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final user = snapshot.data!;

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  otherUserId: user.uid,
                  otherUserName: user.name,
                ),
              ),
            );
          },
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: _getProfileImage(user.photoUrl),
            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: lastTime != null 
            ? Text(
                DateFormat('hh:mm a').format(lastTime!),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              )
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    );
  }
}
