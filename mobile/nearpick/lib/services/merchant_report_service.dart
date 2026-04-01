import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../features/reservation/reservation_support.dart';
import 'csv_file_downloader_stub.dart'
    if (dart.library.html) 'csv_file_downloader_web.dart';

enum MerchantReportExportResult { downloaded, copiedToClipboard, empty }

class MerchantReportService {
  final FirebaseFirestore _db;

  MerchantReportService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<MerchantReportExportResult> exportReservationsCsv({
    required String merchantId,
  }) async {
    final reservations = await _db
        .collection('reservations')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .get();

    if (reservations.docs.isEmpty) {
      return MerchantReportExportResult.empty;
    }

    final csv = buildReservationsCsv(
      reservations.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false),
      generatedAt: DateTime.now(),
    );

    final now = DateTime.now();
    final filename =
        'nearpick-reservations-${_compactDate(now)}-${_compactTime(now)}.csv';
    final downloaded = await downloadTextFile(
      filename: filename,
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );

    if (downloaded) {
      return MerchantReportExportResult.downloaded;
    }

    await Clipboard.setData(ClipboardData(text: csv));
    return MerchantReportExportResult.copiedToClipboard;
  }
}

String buildReservationsCsv(
  List<Map<String, dynamic>> reservations, {
  required DateTime generatedAt,
}) {
  final lines = <String>[
    _csvRow(<String>[
      'reservation_id',
      'product_id',
      'product_name',
      'category',
      'buyer_id',
      'status',
      'discounted_price',
      'original_price',
      'qty',
      'created_at',
      'expires_at',
      'completed_at',
      'cancelled_at',
      'cancel_reason',
      'cancel_note',
      'refund_status',
      'refund_requested_at',
      'refund_reviewed_at',
      'refund_completed_at',
      'generated_at',
    ]),
  ];

  for (final reservation in reservations) {
    final snapshot = Map<String, dynamic>.from(
      reservation['productSnapshot'] as Map? ?? {},
    );
    lines.add(
      _csvRow(<Object?>[
        reservation['id'],
        reservation['productId'],
        snapshot['name'],
        snapshot['category'],
        reservation['buyerId'],
        _reservationStatusLabel(reservation['status'] as String?),
        snapshot['discountedPrice'],
        snapshot['originalPrice'],
        reservation['qty'],
        _isoOrEmpty(reservation['createdAt']),
        _isoOrEmpty(reservation['expiresAt']),
        _isoOrEmpty(reservation['completedAt']),
        _isoOrEmpty(reservation['cancelledAt']),
        cancellationReasonLabel(reservation['cancelReasonCode'] as String?),
        reservation['cancelReasonNote'],
        refundStatusLabel(reservation['refundStatus'] as String?),
        _isoOrEmpty(reservation['refundRequestedAt']),
        _isoOrEmpty(reservation['refundReviewedAt']),
        _isoOrEmpty(reservation['refundCompletedAt']),
        generatedAt.toIso8601String(),
      ]),
    );
  }

  return lines.join('\n');
}

String _csvRow(List<Object?> fields) {
  return fields.map(_escapeCsvField).join(',');
}

String _escapeCsvField(Object? value) {
  final raw = value?.toString() ?? '';
  final escaped = raw.replaceAll('"', '""');
  return '"$escaped"';
}

String _isoOrEmpty(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return '';
}

String _compactDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';
}

String _compactTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _reservationStatusLabel(String? status) {
  switch (status) {
    case 'completed':
      return 'Atadva';
    case 'cancelled':
      return 'Lemondva';
    case 'expired':
      return 'Lejart';
    default:
      return 'Foglalva';
  }
}
