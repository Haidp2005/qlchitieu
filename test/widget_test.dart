import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:qlchitieu/app.dart';

void main() {
  testWidgets('App shell renders three main tabs', (WidgetTester tester) async {
    await initializeDateFormatting('vi_VN', null);
    await initializeDateFormatting('vi', null);

    await tester.pumpWidget(const ExpenseApp());

    expect(find.text('Tong quan'), findsOneWidget);
    expect(find.text('Giao dich'), findsOneWidget);
    expect(find.text('Thong ke'), findsOneWidget);
  });
}
