import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnxchange/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a consistent chat ID between two users
  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: docRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
    );

    // Write message and update last message in chat room metadata
    WriteBatch batch = _firestore.batch();
    batch.set(docRef, message.toMap());
    
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'users': [senderId, receiverId],
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String uid1, String uid2) {
    final chatId = getChatId(uid1, uid2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // Get chat rooms for current user
  Stream<QuerySnapshot> getChatRooms(String uid) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
