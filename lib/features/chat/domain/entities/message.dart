import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, file, system, voice }

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
  final DateTime? editedAt;
  final bool isEdited;
  final String? propertyId;
  final String? propertyTitle;
  final double? propertyPrice;
  final String? propertyImage;
  final String? propertyAddress;
  final String? fileUrl;
  final int? duration; // For voice messages in seconds
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;
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
    this.editedAt,
    this.isEdited = false,
    this.propertyId,
    this.propertyTitle,
    this.propertyPrice,
    this.propertyImage,
    this.propertyAddress,
    this.fileUrl,
    this.duration,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
    this.metadata,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestampField = data['timestamp'];
    DateTime? timestamp;
    if (timestampField is Timestamp) {
      timestamp = timestampField.toDate();
    } else if (timestampField is DateTime) {
      timestamp = timestampField;
    } else {
      timestamp = null; // or DateTime(2000,1,1)
    }
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content:
          data['content'] ??
          data['message'] ??
          '', // Prioritize 'content' field
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: timestamp ?? DateTime(2000, 1, 1), // or skip if null
      readAt: data['readAt']?.toDate(),
      editedAt: data['editedAt']?.toDate(),
      isEdited: data['isEdited'] ?? false,
      propertyId: data['propertyId'],
      propertyTitle: data['propertyTitle'],
      propertyPrice: data['propertyPrice']?.toDouble(),
      propertyImage: data['propertyImage'],
      propertyAddress: data['propertyAddress'],
      fileUrl: data['fileUrl'],
      duration: data['duration']?.toInt(),
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
      replyToSenderName: data['replyToSenderName'],
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
      'editedAt': editedAt,
      'isEdited': isEdited,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyPrice': propertyPrice,
      'propertyImage': propertyImage,
      'propertyAddress': propertyAddress,
      'fileUrl': fileUrl,
      'duration': duration,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderName': replyToSenderName,
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
    DateTime? editedAt,
    bool? isEdited,
    String? propertyId,
    String? propertyTitle,
    double? propertyPrice,
    String? propertyImage,
    String? propertyAddress,
    String? fileUrl,
    int? duration,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
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
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      propertyImage: propertyImage ?? this.propertyImage,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      fileUrl: fileUrl ?? this.fileUrl,
      duration: duration ?? this.duration,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isRead => readAt != null;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;
  bool get hasProperty => propertyId != null;

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
    editedAt,
    isEdited,
    propertyId,
    propertyTitle,
    propertyPrice,
    propertyImage,
    propertyAddress,
    fileUrl,
    duration,
    replyToMessageId,
    replyToContent,
    replyToSenderName,
    metadata,
  ];
}
