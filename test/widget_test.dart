import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamera_pro/app.dart';

void main() {
  testWidgets('KameraProApp builds without error', (tester) async {
    await tester.pumpWidget(const KameraProApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
