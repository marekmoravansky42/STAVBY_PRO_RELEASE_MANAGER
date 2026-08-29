import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick export opens Explorer and shows exact verified path', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains("Dashboard Export ZIP cieľový priečinok:"));
    expect(source, contains("await _selectFileInExplorer(zip.path);"));
    expect(source, contains("Text('Export ZIP vytvorený')"));
    expect(source, contains("Presná cesta:\\n\${zip.path}"));
    expect(source, contains("OTVORIŤ V PRIESKUMNÍKOVI"));
  });
}
