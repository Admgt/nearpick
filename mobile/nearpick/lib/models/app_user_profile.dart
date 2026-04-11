import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

class AppUserProfile {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String accountStatus;
  final String companyName;
  final GeoPoint? companyLocation;
  final DateTime? createdAt;

  const AppUserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.accountStatus,
    required this.companyName,
    required this.companyLocation,
    required this.createdAt,
  });

  factory AppUserProfile.fromMap(String id, Map<String, dynamic> data) {
    return AppUserProfile(
      id: id,
      email: (data['email'] as String? ?? '').trim(),
      displayName: (data['displayName'] as String? ?? '').trim(),
      role: (data['role'] as String? ?? 'consumer').trim(),
      accountStatus: (data['accountStatus'] as String? ?? 'active').trim(),
      companyName: (data['companyName'] as String? ?? '').trim(),
      companyLocation: data['companyLocation'] as GeoPoint?,
      createdAt: _asDate(data['createdAt']),
    );
  }

  factory AppUserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUserProfile.fromMap(
      doc.id,
      doc.data() ?? const <String, dynamic>{},
    );
  }

  String get primaryLabel {
    if (displayName.isNotEmpty) {
      return displayName;
    }
    if (companyName.isNotEmpty) {
      return companyName;
    }
    if (email.isNotEmpty) {
      return email;
    }
    return id;
  }

  bool get isAdmin => role == 'admin';

  bool get isMerchant => role == 'merchant';

  bool get isConsumer => role == 'consumer';

  bool get isActive => accountStatus == 'active';

  bool get isSuspended => accountStatus == 'suspended';

  bool get isBlocked => accountStatus == 'blocked';
}
