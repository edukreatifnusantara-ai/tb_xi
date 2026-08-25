import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tb_xi/main.dart';

void main() {
  testWidgets('halaman registrasi TB XI tampil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.text('TB XI'), findsOneWidget);
    expect(find.text('Buat akun TB XI'), findsOneWidget);
    expect(find.text('Nama panggilan'), findsOneWidget);
    expect(find.text('Nomor HP'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('LANJUTKAN'), findsOneWidget);
  });

  testWidgets('registrasi menolak formulir kosong', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    await tester.tap(find.text('LANJUTKAN'));
    await tester.pump();

    expect(
      find.text('Lengkapi nama, nomor HP, dan email.'),
      findsOneWidget,
    );
  });
}
