// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_candlesticks_chart/flutter_candlesticks_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/example.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    var data = generateData();
    await tester.pumpWidget(MyApp(
      data: data,
    ));

    var prefixSymbol = 'R\$';
    // expect(find.text(prefixSymbol), findsOneWidget);
    // expect(find.widgetWithText(Canvas, prefixSymbol), findsOneWidget);

    var tagText = CandleStickChartValueFormat.formatPricesWithK(data.last.close);
    // expect(find.text(tagText), findsOneWidget);
    // expect(find.widgetWithText(Canvas, tagText), findsOneWidget);
  });
}
