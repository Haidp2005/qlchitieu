import 'package:flutter_test/flutter_test.dart';

import 'package:qlchitieu/app.dart';

void main() {
  testWidgets('App shell renders three main tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseApp());

    expect(find.text('Tong quan'), findsOneWidget);
    expect(find.text('Giao dich'), findsOneWidget);
    expect(find.text('Thong ke'), findsOneWidget);
  });
}
