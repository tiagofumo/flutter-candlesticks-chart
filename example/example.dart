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
  var endDate = DateTime.parse('20190802');
  // var endDate = DateTime.now();
  List<CandleStickChartData> generatedData = [
    CandleStickChartData(
      open: 1000000.0,
      high: 1010000.0,
      low: 990000.0,
      close: 1005000.0,
      volume: 300000000.0,
      dateTime: endDate.subtract(Duration(days: nGenerated)),
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
        volume: lastData.volume*(1+ rng.nextDouble()*0.4 - 0.2),
        dateTime: endDate.subtract(Duration(days: nGenerated - j + 1)),
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
  Offset _cursorPosition = Offset(-1, -1);

  void setCursorPosition(Offset newPosition) {
    setState(() {
      this._cursorPosition = newPosition;
    });
  }

  void clearCursor() {
    setState(() {
      this._cursorPosition = Offset(-1, -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    ChartInfoBoxStyle infoBoxStyle;
    Color backgroundColor, cursorColor;
    if (this._darkMode) {
      buttonText = "Light Mode";
      infoBoxStyle = ChartInfoBoxThemes.getDarkTheme();
      backgroundColor = Colors.black;
      cursorColor = Colors.white;
    } else {
      buttonText = "Dark Mode";
      infoBoxStyle = ChartInfoBoxThemes.getLightTheme();
      backgroundColor = Colors.white;
      cursorColor = Colors.black;
    }
    var lastData = widget.data.last;
    var lineColor = lastData.close >= lastData.open ? Colors.green : Colors.red;
    infoBoxStyle.dateFormatStr = 'dd/MM/yyyy';
    infoBoxStyle.chartI18N = CandleChartI18N(
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
                  child: GestureDetector(
                    onLongPressStart: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onLongPressMoveUpdate: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onTapDown: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onHorizontalDragStart: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onHorizontalDragUpdate: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onVerticalDragStart: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onVerticalDragUpdate: (detail) {
                      setCursorPosition(detail.localPosition);
                    },
                    onTapUp: (detail) {
                      clearCursor();
                    },
                    onVerticalDragEnd: (detail) {
                      clearCursor();
                    },
                    onHorizontalDragEnd: (detail) {
                      clearCursor();
                    },
                    onLongPressEnd: (detail) {
                      clearCursor();
                    },
                    child: CandleStickChart(
                      data: widget.data,
                      fallbackHeight: 400,
                      enableGridLines: true,
                      gridLineAmount: 4,
                      volumeProp: 0.2,
                      volumeSectionOffset: 22,
                      labelPrefix: ' R\$ ',
                      valueLabelBoxType: ValueLabelBoxType.arrowTag,
                      showXAxisLabel: true,
                      formatValueLabelWithK: true,
                      xAxisLabelCount: 4,
                      infoBoxStyle: infoBoxStyle,
                      cursorStyle: CandleChartCursorStyle(
                        cursorColor: cursorColor,
                        showCursorCircle: false,
                        cursorOffset: Offset(0, 50),
                        cursorLabelBoxColor: Colors.green,
                      ),
                      cursorPosition: this._cursorPosition,
                      lineValues: [
                        LineValue(
                          value: lastData.close,
                          lineColor: lineColor,
                          dashed: true,
                        ),
                      ],
                    ),
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