import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat extends Equatable {
  final String id;
  final String userId;
  final String agentId;
  final String agentName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.agentName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Chat copyWith({
    String? id,
    String? userId,
    String? agentId,
    String? agentName,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        agentId,
        agentName,
        lastMessage,
        lastMessageTime,
        unreadCount,
        isActive,
        createdAt,
        updatedAt,
      ];
}
