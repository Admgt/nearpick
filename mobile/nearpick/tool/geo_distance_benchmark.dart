import 'dart:io';
import 'dart:math' as math;

import 'package:nearpick/utils/geo_utils.dart';

class BenchmarkResult {
  final String name;
  final int iterations;
  final int elapsedMicroseconds;
  final double checksum;

  const BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.elapsedMicroseconds,
    required this.checksum,
  });

  double get perCallMicroseconds => elapsedMicroseconds / iterations;
}

BenchmarkResult runBenchmark({
  required String name,
  required int iterations,
  required double Function() body,
}) {
  var checksum = 0.0;

  for (var i = 0; i < math.min(10000, iterations); i++) {
    checksum += body();
  }

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    checksum += body();
  }
  stopwatch.stop();

  return BenchmarkResult(
    name: name,
    iterations: iterations,
    elapsedMicroseconds: stopwatch.elapsedMicroseconds,
    checksum: checksum,
  );
}

void printResult(BenchmarkResult result) {
  stdout.writeln(
    '${result.name}: '
    '${result.elapsedMicroseconds} us total, '
    '${result.perCallMicroseconds.toStringAsFixed(4)} us/call, '
    'checksum=${result.checksum.toStringAsFixed(2)}',
  );
}

void main() {
  stdout.writeln('Geo distance performance smoke benchmark');
  stdout.writeln('Scenario focus: recommendation distance scoring helper');

  final identical = runBenchmark(
    name: 'identical_points',
    iterations: 2000000,
    body: () => GeoUtils.haversineKm(47.4979, 19.0402, 47.4979, 19.0402),
  );

  final nearby = runBenchmark(
    name: 'nearby_points',
    iterations: 500000,
    body: () => GeoUtils.haversineKm(47.4979, 19.0402, 47.5000, 19.0500),
  );

  printResult(identical);
  printResult(nearby);
}
