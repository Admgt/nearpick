import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

class AdminMessage {
  final String id;
  final String recipientUserId;
  final String subject;
  final String body;
  final String topic;
  final String createdBy;
  final String createdByLabel;
  final DateTime? createdAt;
  final DateTime? readAt;

  const AdminMessage({
    required this.id,
    required this.recipientUserId,
    required this.subject,
    required this.body,
    required this.topic,
    required this.createdBy,
    required this.createdByLabel,
    required this.createdAt,
    required this.readAt,
  });

  factory AdminMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AdminMessage(
      id: doc.id,
      recipientUserId: data['recipientUserId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      topic: data['topic'] as String? ?? 'general',
      createdBy: data['createdBy'] as String? ?? '',
      createdByLabel: data['createdByLabel'] as String? ?? 'Admin',
      createdAt: _asDate(data['createdAt']),
      readAt: _asDate(data['readAt']),
    );
  }

  bool get isRead => readAt != null;
}
