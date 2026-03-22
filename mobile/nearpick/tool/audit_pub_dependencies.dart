import 'dart:convert';
import 'dart:io';

const _defaultChunkSize = 100;
final _osvBatchUri = Uri.parse('https://api.osv.dev/v1/querybatch');

class LockedPubPackage {
  LockedPubPackage({
    required this.name,
    required this.version,
    required this.dependencyType,
    required this.source,
    required this.registryUrl,
  });

  final String name;
  final String version;
  final String dependencyType;
  final String source;
  final String? registryUrl;

  Map<String, Object?> toJson() => {
    'name': name,
    'version': version,
    'dependencyType': dependencyType,
    'source': source,
    'registryUrl': registryUrl,
  };
}

class AuditOptions {
  AuditOptions({required this.lockfilePath, required this.reportDirPath});

  final String lockfilePath;
  final String reportDirPath;
}

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final reportDir = Directory(options.reportDirPath);
  await reportDir.create(recursive: true);

  final jsonReportPath =
      '${reportDir.path}${Platform.pathSeparator}pub-audit-osv.json';
  final summaryReportPath =
      '${reportDir.path}${Platform.pathSeparator}pub-audit-summary.txt';

  try {
    final lockfileContent = await File(options.lockfilePath).readAsString();
    final packages = parseHostedPackages(lockfileContent);
    if (packages.isEmpty) {
      final summary =
          'Nem talalhato audit-olhato hosted pub csomag a pubspec.lock fajlban.';
      await _writeOutputs(
        jsonReportPath: jsonReportPath,
        summaryReportPath: summaryReportPath,
        payload: {
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'lockfilePath': options.lockfilePath,
          'packageCount': 0,
          'packages': const <Object?>[],
          'findings': const <Object?>[],
          'status': 'empty',
        },
        summary: summary,
      );
      stdout.writeln(summary);
      exitCode = 0;
      return;
    }

    final findings = await queryOsv(packages);
    final payload = {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'lockfilePath': options.lockfilePath,
      'packageCount': packages.length,
      'packages': packages.map((package) => package.toJson()).toList(),
      'findings': findings,
      'status': findings.isEmpty ? 'pass' : 'fail',
    };
    final summary = _buildSummary(packages.length, findings);

    await _writeOutputs(
      jsonReportPath: jsonReportPath,
      summaryReportPath: summaryReportPath,
      payload: payload,
      summary: summary,
    );

    if (findings.isEmpty) {
      stdout.writeln(summary);
      exitCode = 0;
      return;
    }

    stderr.writeln(summary);
    exitCode = 1;
  } on Object catch (error, stackTrace) {
    final summary = 'Flutter dependency audit failed: $error';
    await _writeOutputs(
      jsonReportPath: jsonReportPath,
      summaryReportPath: summaryReportPath,
      payload: {
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'lockfilePath': options.lockfilePath,
        'status': 'error',
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      },
      summary: summary,
    );
    stderr.writeln(summary);
    exitCode = 2;
  }
}

AuditOptions _parseArgs(List<String> args) {
  final currentDir = Directory.current.path;
  var lockfilePath = '$currentDir${Platform.pathSeparator}pubspec.lock';
  var reportDirPath = '$currentDir${Platform.pathSeparator}reports';

  for (final arg in args) {
    if (arg.startsWith('--lockfile=')) {
      lockfilePath = arg.substring('--lockfile='.length);
      continue;
    }
    if (arg.startsWith('--report-dir=')) {
      reportDirPath = arg.substring('--report-dir='.length);
      continue;
    }
    throw ArgumentError('Unsupported argument: $arg');
  }

  return AuditOptions(lockfilePath: lockfilePath, reportDirPath: reportDirPath);
}

List<LockedPubPackage> parseHostedPackages(String lockfileContent) {
  final packages = <LockedPubPackage>[];
  final lines = const LineSplitter().convert(lockfileContent);

  var inPackagesSection = false;
  String? currentPackageName;
  String? dependencyType;
  String? source;
  String? version;
  String? registryUrl;

  void flushCurrentPackage() {
    if (currentPackageName == null || source != 'hosted' || version == null) {
      return;
    }

    if (registryUrl != null && registryUrl != 'https://pub.dev') {
      return;
    }

    packages.add(
      LockedPubPackage(
        name: currentPackageName,
        version: version,
        dependencyType: dependencyType ?? 'unknown',
        source: source!,
        registryUrl: registryUrl,
      ),
    );
  }

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\r', '');
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) {
      continue;
    }

    if (!inPackagesSection) {
      if (line == 'packages:') {
        inPackagesSection = true;
      }
      continue;
    }

    if (!line.startsWith('  ')) {
      flushCurrentPackage();
      break;
    }

    final packageMatch = RegExp(r'^  ([^:\s][^:]*):\s*$').firstMatch(line);
    if (packageMatch != null) {
      flushCurrentPackage();
      currentPackageName = packageMatch.group(1);
      dependencyType = null;
      source = null;
      version = null;
      registryUrl = null;
      continue;
    }

    if (currentPackageName == null) {
      continue;
    }

    final dependencyMatch = RegExp(
      r'^    dependency:\s*(.+)$',
    ).firstMatch(line);
    if (dependencyMatch != null) {
      dependencyType = _cleanYamlScalar(dependencyMatch.group(1)!);
      continue;
    }

    final sourceMatch = RegExp(r'^    source:\s*(.+)$').firstMatch(line);
    if (sourceMatch != null) {
      source = _cleanYamlScalar(sourceMatch.group(1)!);
      continue;
    }

    final versionMatch = RegExp(r'^    version:\s*(.+)$').firstMatch(line);
    if (versionMatch != null) {
      version = _cleanYamlScalar(versionMatch.group(1)!);
      continue;
    }

    final urlMatch = RegExp(r'^      url:\s*(.+)$').firstMatch(line);
    if (urlMatch != null) {
      registryUrl = _cleanYamlScalar(urlMatch.group(1)!);
    }
  }

  return packages;
}

Future<List<Map<String, Object?>>> queryOsv(
  List<LockedPubPackage> packages,
) async {
  final client = HttpClient();
  final findings = <Map<String, Object?>>[];

  try {
    for (final chunk in _chunk(packages, _defaultChunkSize)) {
      final request = await client.postUrl(_osvBatchUri);
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'queries': chunk
                .map(
                  (package) => {
                    'package': {'name': package.name, 'ecosystem': 'Pub'},
                    'version': package.version,
                  },
                )
                .toList(),
          }),
        ),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'OSV API status ${response.statusCode}: $responseBody',
          uri: _osvBatchUri,
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, Object?>;
      final results = decoded['results'];
      if (results is! List) {
        throw const FormatException(
          'OSV API response does not contain a valid results list.',
        );
      }

      for (var index = 0; index < chunk.length; index++) {
        final package = chunk[index];
        final result = results[index];
        if (result is! Map<String, Object?>) {
          continue;
        }

        final vulns = result['vulns'];
        if (vulns is! List || vulns.isEmpty) {
          continue;
        }

        for (final vuln in vulns) {
          if (vuln is! Map<String, Object?>) {
            continue;
          }

          findings.add({
            'package': package.toJson(),
            'id': vuln['id'],
            'summary': vuln['summary'],
            'details': vuln['details'],
            'aliases': vuln['aliases'],
            'modified': vuln['modified'],
            'published': vuln['published'],
            'withdrawn': vuln['withdrawn'],
            'severity': vuln['severity'],
            'references': vuln['references'],
          });
        }
      }
    }
  } finally {
    client.close(force: true);
  }

  findings.sort((left, right) {
    final leftPackage =
        ((left['package'] as Map<String, Object?>?)?['name'] as String?) ?? '';
    final rightPackage =
        ((right['package'] as Map<String, Object?>?)?['name'] as String?) ?? '';
    final packageCompare = leftPackage.compareTo(rightPackage);
    if (packageCompare != 0) {
      return packageCompare;
    }

    final leftId = left['id']?.toString() ?? '';
    final rightId = right['id']?.toString() ?? '';
    return leftId.compareTo(rightId);
  });

  return findings;
}

String _buildSummary(int packageCount, List<Map<String, Object?>> findings) {
  if (findings.isEmpty) {
    return 'Flutter dependency audit pass: nincs OSV advisory a $packageCount lockolt pub csomagra.';
  }

  final lines = <String>[
    'Flutter dependency audit fail: ${findings.length} advisory erinti a lockolt pub csomagokat.',
  ];

  for (final finding in findings) {
    final package = finding['package'] as Map<String, Object?>?;
    final packageName = package?['name']?.toString() ?? 'unknown';
    final version = package?['version']?.toString() ?? 'unknown';
    final advisoryId = finding['id']?.toString() ?? 'unknown';
    final summary = finding['summary']?.toString().trim();
    final suffix = (summary == null || summary.isEmpty) ? '' : ' - $summary';
    lines.add('- $packageName@$version [$advisoryId]$suffix');
  }

  return lines.join('\n');
}

Future<void> _writeOutputs({
  required String jsonReportPath,
  required String summaryReportPath,
  required Map<String, Object?> payload,
  required String summary,
}) async {
  final encoder = const JsonEncoder.withIndent('  ');
  await File(jsonReportPath).writeAsString('${encoder.convert(payload)}\n');
  await File(summaryReportPath).writeAsString('$summary\n');
}

String _cleanYamlScalar(String value) {
  final trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

Iterable<List<T>> _chunk<T>(List<T> values, int chunkSize) sync* {
  for (var index = 0; index < values.length; index += chunkSize) {
    final end = (index + chunkSize < values.length)
        ? index + chunkSize
        : values.length;
    yield values.sublist(index, end);
  }
}
