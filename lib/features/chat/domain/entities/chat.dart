import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat extends Equatable {
  final String id;
  final String userId;
  final String agentId;
  final String agentName;
  final String userName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? participants;

  const Chat({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.agentName,
    required this.userName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.participants,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'] ?? '',
      agentName: data['agentName'] ?? '',
      userName: data['userName'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      unreadCount: data['unreadCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      participants:
          (data['participants'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'userName': userName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (participants != null) 'participants': participants,
    };
  }

  Chat copyWith({
    String? id,
    String? userId,
    String? agentId,
    String? agentName,
    String? userName,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? participants,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      userName: userName ?? this.userName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    agentId,
    agentName,
    userName,
    lastMessage,
    lastMessageTime,
    unreadCount,
    isActive,
    createdAt,
    updatedAt,
    participants,
  ];
}
