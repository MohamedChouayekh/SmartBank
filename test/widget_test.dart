import 'package:flutter_test/flutter_test.dart';

import 'package:banking_app/main.dart';

void main() {
  testWidgets('SmartBank application starts correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartBankApp());

    expect(find.text('SmartBank'), findsOneWidget);
    expect(find.text('Identifiant'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}