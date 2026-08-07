import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/version.dart';

void main() {
  test('la version affichée correspond à celle du pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declaree = RegExp(r'^version:\s*([\d.]+)\+(\d+)\s*$', multiLine: true)
        .firstMatch(pubspec);

    expect(declaree, isNotNull, reason: 'version absente du pubspec');

    // Sans ce test, oublier `python3 tool/build_version.py` afficherait un
    // numéro faux dans l'espace parents — et un parent croirait sa mise à
    // jour non installée, ou l'inverse.
    expect(
      appVersion,
      declaree!.group(1),
      reason: 'Relancez : python3 tool/build_version.py',
    );
    expect(
      appBuildNumber,
      declaree.group(2),
      reason: 'Relancez : python3 tool/build_version.py',
    );
  });

  test('la version est affichable', () {
    expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    expect(appBuildNumber, matches(RegExp(r'^\d+$')));
  });
}
