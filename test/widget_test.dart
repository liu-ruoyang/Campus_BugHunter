import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_project/components/button.dart';

void main() {
  testWidgets('CustomButton shows its label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'SUBMIT',
            isLoading: false,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('SUBMIT'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
