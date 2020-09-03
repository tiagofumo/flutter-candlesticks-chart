import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_candlesticks_chart/flutter_candlesticks_chart.dart';
import 'package:intl/intl.dart' as intl;

void main() {
  var data = generateData();
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey,
          title: Text('Flutter candlestick chart'),
        ),
        body: MyApp(
          data: data,
          assetEventCollections: generateEvents(data)
        ),
      ),
    ),
  );
}

List<AssetEventCollection> generateEvents(List<CandleStickChartData> data) {
  return [
    AssetEventCollection(
      dateTime: data[(data.length/3).floor()].dateTime,
      assetEvents: [
        AssetEvent(
          type: AssetEventType.ernings,
          description: 'Earnings for quarter',
          link: 'LINK_TO_FILE',
        ),
        AssetEvent(
          type: AssetEventType.notice,
          description: 'Notice to the market',
          link: 'LINK_TO_FILE',
        ),
      ],
    ),
    AssetEventCollection(
      dateTime: data[(data.length/2).floor()].dateTime,
      assetEvents: [
        AssetEvent(
          type: AssetEventType.dividends,
          description: 'Dividends',
          link: 'LINK_TO_FILE',
        ),
      ],
    ),
    AssetEventCollection(
      dateTime: data[(2*data.length/3).floor()].dateTime,
      assetEvents: [
        AssetEvent(
          type: AssetEventType.split,
          description: 'Stock Split 1:4',
          link: 'LINK_TO_FILE',
        ),
      ],
    )
  ];
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
    this.assetEventCollections = const [],
  });
  final List<CandleStickChartData> data;
  final List<AssetEventCollection> assetEventCollections;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = true;
  Offset _cursorPosition = Offset(-1, -1);
  var assetEventCollectionsMap = HashMap<DateTime, AssetEventCollection>();

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

  Function(ChartEvent) buildDialog(BuildContext buildContext) {
    return (ChartEvent chartEvent) async {
      var assetEventCollection = assetEventCollectionsMap[chartEvent.dateTime];
      var assetEvents = assetEventCollection.assetEvents;
      var modalTextFontSize = 14.0;
      var bodyTextStyle = TextStyle(
        color: Colors.white, 
        fontSize: modalTextFontSize,
        fontWeight: FontWeight.normal,
      );
      var titleTextStyle = TextStyle(
        color: Colors.white,
        fontSize: modalTextFontSize,
        fontWeight: FontWeight.bold,
      );
      List<Widget> widgetList = [];
      // var padding = assetEvents.length == 1 ? 10 : 8;
      var padding = 20;
      for (var i = 0; i < assetEvents.length; i++) {
        var assetEvent = assetEvents[i];
        String eventTitle;
        switch(assetEvent.type) {
          case AssetEventType.ernings:
            eventTitle = 'Earnings';
            break;
          case AssetEventType.dividends:
            eventTitle = 'Dividends';
            break;
          case AssetEventType.split:
            eventTitle = 'Split';
            break;
          case AssetEventType.notice:
            eventTitle = 'Notice to the market';
            break;
        }
        eventTitle += ' - ' + intl.DateFormat('dd/MM/yyyy').format(assetEventCollection.dateTime);
        widgetList.add(
          Container(
            padding: EdgeInsets.all(padding.toDouble()),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eventTitle, style: titleTextStyle),
                Container(height: 2, width: double.infinity,),
                Text(assetEvent.description, style: bodyTextStyle),
              ],
            ),
          )
        );
        widgetList.add(
          Container(
            color: Colors.black,
            height: 1,
            width: double.infinity
          )
        );
      }
      widgetList.removeLast();
      var modalContainer = Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: widgetList,
        ),
      );
      await showDialog(
        context: buildContext,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            contentPadding: EdgeInsets.all(0),
            content: modalContainer,
          );
        },
      ).then((_) {
        // must clear cursor to avoid bugs
        clearCursor();
      });
    };
  }

  String getCircleLetter(AssetEventType type) {
    switch(type) {
      case AssetEventType.ernings:
        return 'E';
        break;
      case AssetEventType.dividends:
        return 'D';
        break;
      case AssetEventType.split:
        return 'S';
        break;
      case AssetEventType.notice:
        return 'N';
        break;
      default:
        throw Exception('Unnadentified type');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.data;
    var assetEventCollections = widget.assetEventCollections;
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

    var chartEvents = List<ChartEvent>();
    for (var assetEventCollection in assetEventCollections) {
      var dateTime = assetEventCollection.dateTime;
      assetEventCollectionsMap[dateTime] = assetEventCollection;
      var assetEvents = assetEventCollection.assetEvents;
      String circleText;
      var eventType = assetEvents.first.type;
      if (assetEvents.length > 1 && !assetEvents.every((e) => e.type == eventType)) {
        circleText = assetEvents.length.toString();
      } else {
        circleText = getCircleLetter(eventType);
      }
      chartEvents.add(
        ChartEvent(
          dateTime: dateTime,
          circleText: circleText, 
          fn: this.buildDialog(context),
        )
      );
    }
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(bottom: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
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
          Expanded(
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
                data: data,
                enableGridLines: true,
                gridLineStyle: ChartGridLineStyle(
                  gridLineAmount: 4,
                  showXAxisLabels: true,
                  xAxisLabelCount: 4,
                ),
                candleSticksStyle: CandleSticksStyle(
                  labelPrefix: ' R\$ ',
                  valueLabelBoxType: ValueLabelBoxType.arrowTag,
                  volumeSectionOffset: 22,
                ),
                volumeProp: 0.2,
                formatValueLabelWithK: true,
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
                chartEvents: chartEvents,
                chartEventStyle: ChartEventStyle(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  circleRadius: 13,
                  circlePaint: Paint()
                    ..color = Colors.orange
                    ..style = PaintingStyle.fill,
                  circleBorderPaint: Paint()
                    ..color = Colors.orange[50]
                    ..style = PaintingStyle.stroke,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AssetEventCollection {
  AssetEventCollection({
    @required this.dateTime,
    @required this.assetEvents,
  });
  final DateTime dateTime;
  final List<AssetEvent> assetEvents;
}

class AssetEvent {
  AssetEvent({
    @required this.type,
    @required this.description,
    this.link,
  });
  final AssetEventType type;
  final String description;
  final String link;
}

enum AssetEventType {
  ernings,
  dividends,
  split,
  notice,
}