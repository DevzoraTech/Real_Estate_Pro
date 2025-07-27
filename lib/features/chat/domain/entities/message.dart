import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, file, system }

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.readAt,
    this.metadata,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['message'] ?? data['content'] ?? '', // Support both field names
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      readAt: data['readAt']?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': content, // Keep for backward compatibility
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp,
      'readAt': readAt,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isRead => readAt != null;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        receiverId,
        content,
        type,
        status,
        timestamp,
        readAt,
        metadata,
      ];
}
