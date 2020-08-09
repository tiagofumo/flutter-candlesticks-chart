import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_candlesticks_chart/flutter_candlesticks_chart.dart';

void main() {
  runApp(MyApp(
    data: generateData()
  ));
}

List<CandleStickChartData> generateData() {
  var nGenerated = 70;
  List<CandleStickChartData> generatedData = [
    CandleStickChartData(
      open: 1000000.0,
      high: 1010000.0,
      low: 990000.0,
      close: 1005000.0,
      volume: 1.0,
      dateTime: DateTime.now().subtract(Duration(days: 70)),
    ),
  ];
  var rng = Random();
  for (var j = 0; j < nGenerated; j++) {
    var lastData = generatedData.last;
    var open = lastData.close;
    var close = open*(1+ rng.nextDouble()*0.05 - 0.025);
    generatedData.add(
      CandleStickChartData(
        open: open,
        close: close,
        high: close*(1 + rng.nextDouble()*0.015),
        low: open*(1 - rng.nextDouble()*0.01),
        volume: 0.1+rng.nextDouble()*2,
        dateTime: DateTime.now().subtract(Duration(days: nGenerated - j + 1)),
      )
    );
  }
  generatedData.removeAt(0);
  return generatedData;
}

class MyApp extends StatefulWidget {
  MyApp({
    @required this.data,
  });
  final List<CandleStickChartData> data;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = true;
  @override
  Widget build(BuildContext context) {
    String buttonText;
    ChartInfoBoxLayout infoBoxLayout;
    Color backgroundColor, cursorColor;
    if (this._darkMode) {
      buttonText = "Light Mode";
      infoBoxLayout = ChartInfoBoxThemes.getDarkTheme();
      backgroundColor = Colors.black;
      cursorColor = Colors.white;
    } else {
      buttonText = "Dark Mode";
      infoBoxLayout = ChartInfoBoxThemes.getLightTheme();
      backgroundColor = Colors.white;
      cursorColor = Colors.black;
    }
    var lastData = widget.data.last;
    var lineColor = lastData.close >= lastData.open ? Colors.green : Colors.red;
    infoBoxLayout.dateFormatStr = 'dd/MM/yyyy';
    var candleChartI18N = CandleChartI18N(
      open: "Abertura",
      close: "Fecha",
      high: "Máxima",
      low: "Mínima",
    );
    return (
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey,
            title: Text('Flutter candlestick chart'),
          ),
          body: Container(
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 200.0,
                  child: RaisedButton(
                    child: Center(
                      child: Text(
                        buttonText,
                      ),
                    ),
                    onPressed: () {
                      this.setState(() {
                        this._darkMode = !this._darkMode;
                      });
                    }
                  ),
                ),
                Container(
                  height: 400.0,
                  child: CandleStickChart(
                    data: widget.data,
                    enableGridLines: true,
                    gridLineAmount: 5,
                    volumeProp: 0.2,
                    volumeSectionOffset: 22,
                    labelPrefix: ' R\$ ',
                    showCursorCircle: false,
                    cursorOffset: Offset(0, 50),
                    valueLabelBoxType: ValueLabelBoxType.arrowTag,
                    cursorLabelBoxColor: Colors.green,
                    showXAxisLabel: true,
                    formatValueLabelWithK: true,
                    xAxisLabelCount: 4,
                    cursorColor: cursorColor,
                    infoBoxLayout: infoBoxLayout,
                    chartI18N: candleChartI18N,
                    lines: [
                      LineValue(
                        value: lastData.close,
                        lineColor: lineColor,
                        dashed: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      )
    );
  }
}