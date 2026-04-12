import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

class AppException implements Exception {
  final String code;
  final String message;
  final String? contextId;
  final bool retryable;

  const AppException({
    required this.code,
    required this.message,
    this.contextId,
    this.retryable = false,
  });

  factory AppException.fromFunctions(
    FirebaseFunctionsException error, {
    required String fallback,
  }) {
    return AppException(
      code: error.code,
      message: _nonEmpty(error.message) ?? fallback,
      contextId: contextIdFromDetails(error.details),
      retryable: _retryableFunctionCodes.contains(error.code),
    );
  }

  @override
  String toString() => message;
}

final Random _contextRandom = Random.secure();

const Set<String> _retryableFunctionCodes = {
  'aborted',
  'deadline-exceeded',
  'internal',
  'resource-exhausted',
  'unavailable',
  'unknown',
};

Map<String, dynamic> withClientContextId(Map<String, dynamic> data) {
  return <String, dynamic>{...data, 'contextId': newClientContextId()};
}

String newClientContextId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final random = List.generate(
    4,
    (_) => _contextRandom.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
  ).join();
  return 'app-$timestamp-$random';
}

String? contextIdFromDetails(Object? details) {
  if (details is Map) {
    final value = details['contextId'];
    if (value is String) {
      return _nonEmpty(value);
    }
  }
  return null;
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
