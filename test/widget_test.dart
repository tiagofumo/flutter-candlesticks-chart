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

List<DateTime> getDateList(DateTime startDate, DateTime endDate) {
  var dates = List<DateTime>();
  var differenceInDays = endDate.difference(startDate).inDays;
  for (var i = 0; i <= differenceInDays; i++) {
    dates.add(startDate.add(Duration(days: i)));
  }
  return dates;
}

void testGetVerticalLinesDates() {
  test('Test getVerticalLineDates different years', () {
    var endDate = DateTime.parse('20200809');
    var startDate = DateTime.parse('20180505');
    var dates = getDateList(startDate, endDate);
    var newDates = GridLineHelper.getVerticalLinesDates(
      dates: dates,
    );
    expect(newDates.length, 2);
    expect(newDates[0].dateTime.compareTo(DateTime.parse('20190101')), 0);
    expect(newDates[1].dateTime.compareTo(DateTime.parse('20200101')), 0);
  });

  test('Test getVerticalLineDates same year same month', () {
    var endDate = DateTime.parse('20200728');
    var startDate = DateTime.parse('20200710');
    var dates = getDateList(startDate, endDate);
    var nDates = 4;
    var newDates = GridLineHelper.getVerticalLinesDates(
      dates: dates,
      nDates: nDates,
    );
    expect(newDates.length, nDates);
  });

  test('Test getVerticalLineDates same year different month', () {
    var endDate = DateTime.parse('20200728');
    var startDate = DateTime.parse('20200110');
    var dates = getDateList(startDate, endDate);
    var newDates = GridLineHelper.getVerticalLinesDates(
      dates: dates,
    );
    expect(newDates.length, 6);
    expect(newDates[0].dateTime.compareTo(DateTime.parse('20200201')), 0);
    expect(newDates[1].dateTime.compareTo(DateTime.parse('20200301')), 0);
    expect(newDates[2].dateTime.compareTo(DateTime.parse('20200401')), 0);
    expect(newDates[3].dateTime.compareTo(DateTime.parse('20200501')), 0);
    expect(newDates[4].dateTime.compareTo(DateTime.parse('20200601')), 0);
    expect(newDates[5].dateTime.compareTo(DateTime.parse('20200701')), 0);
  });
}

void testGetVolumeGridLines() {
  test('Test getVolumeGridLinesTests', () {
    var expectedValues = [
      [1200000000, [1000000000, 500000000]],
      [800000000, [500000000]],
      [600000000, [500000000]],
      [500000000, [250000000]],
      [300000000, [200000000]],
      [150000000, [100000000]],
      [100000000, [50000000]],
      [60000000, [50000000]],
      [50000000, [25000000]],
      [40000000, [25000000]],
      [30000000, [20000000]],
      [20000000, [10000000]],
      [10000000, [5000000]],
      [10000000, [5000000]],
      [5000000, [2500000]],
    ];
    expectedValues.forEach((expectedArr) { 
      double input = (expectedArr[0] as int).toDouble();
      var outputList = expectedArr[1];
      expect(GridLineHelper.getVolumeGridLines([], max: input), outputList);
    });
  });
}


void testGetHorizontalGridLines() {
  test('Test getHorizontalGridLines', () {
    var lines = GridLineHelper.getHorizontalGridLines(
      max: 102000,
      min: 79000,
      minLineCount: 4,
    );
    expect(lines, [80000.0, 85000.0, 90000.0, 95000.0, 100000.0]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 10.50,
      min: 5,
      minLineCount: 4,
    );
    expect(lines, [6.0, 7.0, 8.0, 9.0, 10.0]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 3.70,
      min: 3.10,
      minLineCount: 4,
    );
    expect(lines, [3.2, 3.3, 3.4, 3.5, 3.6]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 1258049.494460039,
      min: 995157.6981393362,
      minLineCount: 4,
    );
    expect(lines, [1000000.0, 1050000.0, 1100000.0, 1150000.0, 1200000.0, 1250000.0]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 1144565.568979,
      min: 941157.6981393362,
      minLineCount: 4,
    );
    expect(lines, [950000.0, 1000000.0, 1050000.0, 1100000.0]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 1051565.568979,
      min: 882157.6981393362,
      minLineCount: 4,
    );
    expect(lines, [900000.0, 950000.0, 1000000.0, 1050000.0]);
    lines = GridLineHelper.getHorizontalGridLines(
      max: 1101931.568979,
      min: 970243.6981393362,
      minLineCount: 4,
    );
    expect(lines, [975000.0, 1000000.0, 1025000.0, 1050000.0, 1075000.0, 1100000.0]);
  });
}

void main() {
  testGetVerticalLinesDates();
  testGetVolumeGridLines();
  testGetHorizontalGridLines();
  // TODO: Add tests with matchesReferenceImage
}
