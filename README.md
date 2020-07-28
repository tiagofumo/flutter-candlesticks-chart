# flutter_candlesticks_chart

Flutter candlesticks chart widget based on [trentpiercy's flutter-candlesticks](https://github.com/trentpiercy/flutter-candlesticks) which uses a MIT license. As I had a lot of changes to add code and the original repository seemed unchanged for a long while, I thought it would be better to just create a new repository.

## Usage

TODO: Add to pub and copy link here

Install for Flutter [with pub](https://pub.dartlang.org/packages/flutter_candlesticks#-installing-tab-).

| Property                 | Default Value                   | Description                                                                 |
|--------------------------|---------------------------------|-----------------------------------------------------------------------------|
| data                     | Required Field                  | List of CandleStickChartData                                                |
| enableGridLines          | Required Field                  | Enable or disable grid lines                                                |
| volumeProp               | Required Field                  | Proportion of container to be given to volume bars                          |
| lineWidth                | `1.0`                           | Width of most lines                                                         |
| fallbackHeight           | `100.0`                         | If graph is given unbounded space, it will default to given fallback height |
| fallbackWidth            | `300.0`                         | If graph is given unbounded space, it will default to given fallback width  |
| gridLineColor            | `Colors.grey`                   | Color of grid lines                                                         |
| gridLineAmount           | `5`                             | Number of grid lines to draw. Labels automatically assigned                 |
| gridLineWidth            | `0.5`                           | Width of grid lines                                                         |
| gridLineLabelColor       | `Colors.grey`                   | Color of grid line labels                                                   |
| labelPrefix              | `"$"`                           | Prefix before grid line labels.                                             |
| onSelect                 | No default                      | Invoked when a new candle is selected                                       |
| increaseColor            | `Colors.green`                  | Color of increasing candles.                                                |
| decreaseColor            | `Colors.red`                    | Color of decreasing candles.                                                |
| showCursorCircle         | `true`                          | Show cursor dot in the middle of the cursor arrow                           |
| showCursorInfoBox        | `true`                          | Show a box with information about the data point at cursor position         |
| cursorColor              | `Colors.black`                  | The color used for the cursor lines                                         |
| cursorLabelBoxColor      | `Colors.black`                  | The color used for the cursor value and time label boxes                    |
| cursorTextColor          | `Colors.white`                  | The color used for the cursor value and time text                           |
| cursorJumpToCandleCenter | `false`                         | Cursor always stays on candles' center position                             |
| cursorLineWidth          |  `0.5`                          | Width of the lines of the cursor cross                                      |
| cursorOffset             | `Offset(0, 0)`                  | Offset used by the cursor position relative to the user's touch             |
| cursorLineDashed         | `false`                         | Cursor has dashed lines                                                     |
| volumeSectionOffset      |  `0.0`                          | Extra offset distance between the quote candle chart and volume section     |
| lines                    | `[]`                            | List of LineValue to be added to the chart                                  |
| formatFn                 | No default                      | formatFn is applied to all values displayed on chart if provided            |
| formatValueLabelWithK    | `false`                         | Format values with a "K" letter in the end if >= 1,000,000                  |
| valueLabelBoxType        | `ValueLabelBoxType.roundedRect` | Tag type used on value label boxes                                          |
| xAxisLabelFormatFn       | No default                      | Format function used to format x axis labels                                |
| xAxisLabelCount          | `3`                             | Number of labels on the x axis                                              |
| fullscreenGridLine       | `false`                         | Show grid lines on full screen                                              |
| showXAxisLabel           | `false`                         | Shows labels on the x axis with vertical grid lines                         |

## Example

```dart
var last = data.last;
var lineColor = last.close >= last.open ? Colors.green : Colors.red;
CandleStickChart(
    data: data,
    enableGridLines: true,
    gridLineAmount: 5,
    volumeProp: 0.2,
    volumeSectionOffset: 22,
    showCursorCircle: false,
    cursorOffset: Offset(0, 50),
    valueLabelBoxType: ValueLabelBoxType.arrowTag,
    cursorLabelBoxColor: Colors.green,
    showXAxisLabel: true,
    formatValueLabelWithK: true,
    lines: [
        LineValue(
            value: lastData.close,
            lineColor: lineColor,
            dashed: true,
        ),
    ],
),
```

TODO: add screenshot with 70 data points

> Candle size dynamically changes by amount of data

TODO: add screneshort with 35 data points

### Full App Example
```dart
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

class MyApp extends StatelessWidget {
  MyApp({
    @required this.data,
  });
  final List<CandleStickChartData> data;
  @override
  Widget build(BuildContext context) {
    var lastData = data.last;
    var lineColor = lastData.close >= lastData.open ? Colors.green : Colors.red;
    return (
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              height: 400.0,
              child: CandleStickChart(
                data: data,
                enableGridLines: true,
                gridLineAmount: 5,
                volumeProp: 0.2,
                volumeSectionOffset: 22,
                showCursorCircle: false,
                cursorOffset: Offset(0, 50),
                valueLabelBoxType: ValueLabelBoxType.arrowTag,
                cursorLabelBoxColor: Colors.green,
                showXAxisLabel: true,
                formatValueLabelWithK: true,
                lines: [
                  LineValue(
                    value: lastData.close,
                    lineColor: lineColor,
                    dashed: true,
                  ),
                ],
              ),
            ),
          ),
        )
      )
    );
  }
}
```