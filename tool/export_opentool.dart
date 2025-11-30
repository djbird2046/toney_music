import 'dart:convert';
import 'dart:io';

import 'package:toney_music/core/agent/app_tool_spec.dart';

Future<void> main() async {
  final spec = buildAppToolSpecification();
  final encoder = const JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(spec.toJson());
  final outputFile = File('example/example.json');
  await outputFile.create(recursive: true);
  await outputFile.writeAsString(jsonString);
  stdout.writeln('Wrote OpenTool spec to ${outputFile.path}');
}
