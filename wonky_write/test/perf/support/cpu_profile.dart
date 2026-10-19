import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate' as iso;

import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:vm_service/vm_service.dart';
// ignore: depend_on_referenced_packages
import 'package:vm_service/vm_service_io.dart';

/// Optional CPU profile of a perf scenario: with `WONKY_PROFILE=1` and
/// `flutter test --enable-vmservice -t perf --run-skipped`, [run] prints the
/// functions with the most inclusive samples (top-down hot spots) while
/// [body] ran. Without the variable it just runs [body].
class CpuProfile {
  static bool get enabled => Platform.environment['WONKY_PROFILE'] == '1';

  static Future<void> run(
    WidgetTester tester,
    String name,
    Future<void> Function() body, {
    int top = 150,
  }) async {
    if (!enabled) return body();
    final info = await tester.runAsync(developer.Service.getInfo);
    final uri = info?.serverWebSocketUri;
    if (uri == null) {
      // ignore: avoid_print
      print('[profile] no VM service (run with --enable-vmservice)');
      return body();
    }
    final service = (await tester.runAsync(
      () => vmServiceConnectUri(uri.toString()),
    ))!;
    final isolateId = developer.Service.getIsolateId(iso.Isolate.current)!;
    await tester.runAsync(() => service.clearCpuSamples(isolateId));
    final start = (await tester.runAsync(service.getVMTimelineMicros))!;
    await body();
    final end = (await tester.runAsync(service.getVMTimelineMicros))!;
    final samples = (await tester.runAsync(
      () => service.getCpuSamples(
        isolateId,
        start.timestamp!,
        end.timestamp! - start.timestamp!,
      ),
    ))!;
    final functions = samples.functions ?? const <ProfileFunction>[];
    final inclusive = <int, int>{};
    final exclusive = <int, int>{};
    final all = samples.samples ?? const <CpuSample>[];
    for (final s in all) {
      final stack = s.stack ?? const <int>[];
      if (stack.isEmpty) continue;
      exclusive[stack.first] = (exclusive[stack.first] ?? 0) + 1;
      for (final f in stack.toSet()) {
        inclusive[f] = (inclusive[f] ?? 0) + 1;
      }
    }
    String nameOf(int i) {
      final f = functions[i].function;
      final owner = f is FuncRef ? f.owner : null;
      final ownerName = owner is ClassRef
          ? '${owner.name}.'
          : (owner is FuncRef ? '${owner.name}.' : '');
      final fname = f is FuncRef
          ? f.name
          : (f is NativeFunction ? f.name : '$f');
      final url = functions[i].resolvedUrl ?? '';
      return '$ownerName$fname (${url.split('/').last})';
    }

    void dump(String title, Map<int, int> counts) {
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      // ignore: avoid_print
      print('[profile] $name — $title (${all.length} samples)');
      for (final e in sorted.take(top)) {
        // ignore: avoid_print
        print(
          '[profile]   ${(e.value * 100 / all.length).toStringAsFixed(1)}% '
          '${nameOf(e.key)}',
        );
      }
    }

    dump('inclusive', inclusive);
    // Our code and the editor's, without the framework frames above it.
    dump('inclusive, app and super_editor', {
      for (final e in inclusive.entries)
        if (RegExp(
          r'wonky|super_editor|super_text|attributed_text',
        ).hasMatch(functions[e.key].resolvedUrl ?? ''))
          e.key: e.value,
    });
    dump('exclusive', exclusive);
    await tester.runAsync(service.dispose);
  }
}
