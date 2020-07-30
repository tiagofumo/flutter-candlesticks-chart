import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart' as intl;

class CandleStickChart extends StatefulWidget {
  CandleStickChart({
    Key key,
    @required this.data,
    this.lineWidth = 1.0,
    this.fallbackHeight = 100.0,
    this.fallbackWidth = 300.0,
    this.gridLineColor = Colors.grey,
    this.gridLineAmount = 5,
    this.gridLineWidth = 0.5,
    this.gridLineLabelColor = Colors.grey,
    this.labelPrefix = "\$",
    this.onSelect,
    @required this.enableGridLines,
    @required this.volumeProp,
    this.increaseColor = Colors.green,
    this.decreaseColor = Colors.red,
    this.showCursorCircle = true,
    this.showCursorInfoBox = true,
    this.cursorColor = Colors.black,
    this.cursorLabelBoxColor = Colors.black,
    this.cursorTextColor = Colors.white,
    this.cursorJumpToCandleCenter = false,
    this.cursorLineWidth = 0.5,
    this.cursorOffset = const Offset(0, 0),
    this.cursorLineDashed = false,
    this.volumeSectionOffset = 0,
    this.lines = const [],
    this.formatFn,
    this.formatValueLabelWithK = false,
    this.valueLabelBoxType = ValueLabelBoxType.roundedRect,
    this.xAxisLabelFormatFn,
    this.xAxisLabelCount = 3,
    this.fullscreenGridLine = false,
    this.showXAxisLabel = false,
    this.infoBoxLayout,
  }) : super(key: key) {
    assert(data != null);
    if (fullscreenGridLine) {
      assert(enableGridLines);
    }
    if (formatFn != null) {
      assert(!formatValueLabelWithK);
    }
    if (infoBoxLayout == null) {
      infoBoxLayout = ChartInfoBoxThemes.getDarkTheme();
    }
  }

  // final List data;
  final List<CandleStickChartData> data;

  final Function(dynamic) onSelect;

  /// All lines in chart are drawn with this width
  final double lineWidth;

  /// Enable or disable grid lines
  final bool enableGridLines;

  /// Color of grid lines and label text
  final Color gridLineColor;
  final Color gridLineLabelColor;

  /// Number of grid lines
  final int gridLineAmount;

  /// Width of grid lines
  final double gridLineWidth;

  /// Proportion of paint to be given to volume bar graph
  final double volumeProp;

  /// If graph is given unbounded space,
  /// it will default to given fallback height and width
  final double fallbackHeight;
  final double fallbackWidth;

  /// Symbol prefix for grid line labels
  final String labelPrefix;

  /// Increase color
  final Color increaseColor;

  /// Decrease color
  final Color decreaseColor;

  final bool showCursorCircle;
  final bool showCursorInfoBox;

  // CursorColor
  final Color cursorColor;

  final Color cursorTextColor;

  final Color cursorLabelBoxColor;

  final double cursorLineWidth;

  final bool cursorLineDashed;

  final bool cursorJumpToCandleCenter;

  final double volumeSectionOffset; 

  final ValueLabelBoxType valueLabelBoxType; 

  // draw lines on chart
  final List<LineValue> lines;

  /// formatFn is applyed to all values displyed on chart if provided
  final FormatFn formatFn;

  final XAxisLabelFormatFn xAxisLabelFormatFn;
  final int xAxisLabelCount;

  final bool fullscreenGridLine;

  final bool showXAxisLabel;

  final bool formatValueLabelWithK;

  // Offset to be used on the cursor on click
  final Offset cursorOffset;

  ChartInfoBoxLayout infoBoxLayout;

  @override
  _CandleStickChartState createState() => _CandleStickChartState();
}

class _CandleStickChartState extends State<CandleStickChart> {
  final List<_ChartPointMapping> pointsMappingX = List();
  final List<_ChartPointMapping> pointsMappingY = List();

  double _cursorX = -1;
  double _cursorY = -1;
  double _cursorYPrice = 0;
  int _cursorXTime = 0;

  CandleStickChartData _selectedData;

  double _min = double.infinity;
  double _max = -double.infinity;
  double _maxVolume = -double.infinity;

  final double valueLabelWidth = 60.0;
  final double valueLabelFontSize = 10.0;
  final double valueLabelHeight = 20.0; // this must be valueLabelFontSize*2

  final double xAxisLabelWidth = 60;
  final double xAxisLabelHeight = 20;


  void clearCursor() {
    setState(() {
      this._cursorX = -1;
      this._cursorY = -1;
    });
  }

  void _onUnselect() {
    if (this.widget.onSelect != null) {
      this.widget.onSelect(null);
    }
    clearCursor();
  }

  void _onPositionUpdate(Offset position) {
    // find candle index by coords
    var i = pointsMappingX.indexWhere(
        (el) => position.dx >= el.from && position.dx <= el.to);
    if (i == -1) {
      // candle is out of range or we are in candle padding
      i = pointsMappingX.indexWhere((el) => position.dx <= el.to);
      var i2 = pointsMappingX.indexWhere((el) => el.from >= position.dx);
      if (i == -1) {
        // out of range max, select the last candle
        i = pointsMappingX.length - 1;
      } else if (i2 <= 0) {
        // out of range min, select the first candle
        i = 0;
      } else {
        // find the nearest candle
        i2 -= 1; // il grande x minore di from
        var delta1 = (position.dx - pointsMappingX[i].from).abs();
        var delta2 = (position.dx - pointsMappingX[i2].to).abs();
        if (delta2 < delta1) {
          i = i2;
        }
      }
    }
    // update x cursor
    var el = pointsMappingX.elementAt(i);
    var widgetHeight = context.size.height;
    var cursorMaxX = context.size.width - valueLabelWidth;
    var myYPosition =
        (position.dy - widgetHeight + (widgetHeight * widget.volumeProp)) * -1;
    myYPosition += widget.cursorOffset.dy;

    // calc chartHeight without volume part
    final double chartHeight = context.size.height * (1 - widget.volumeProp);
    var positionPrice = (((_max - _min) * myYPosition) / chartHeight) + _min;

    if (position.dy - widget.cursorOffset.dy > chartHeight ||
          position.dy - widget.cursorOffset.dy < 0 ||
          position.dx - widget.cursorOffset.dx > cursorMaxX) {
      clearCursor();
      return;
    }

    setState(() {
      if (widget.cursorJumpToCandleCenter) {
        // set cursox at the middle of the candle
        this._cursorX = (el.from + el.to) / 2;
      } else {
        this._cursorX = position.dx;
      }

      this._cursorY = position.dy;
      widget.data[i].selectedPrice = positionPrice;

      this._cursorY -= widget.cursorOffset.dy;
      _cursorYPrice = widget.data[i].selectedPrice;
      _cursorXTime = widget.data[i].dateTime.millisecondsSinceEpoch;
      _selectedData = widget.data[i];
    });

    // invoke onSelect with new values
    if (widget.onSelect != null) {
      var val = widget.data[i];
      this.widget.onSelect(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;
    for (var i in widget.data) {
      if (i.high > _max) {
        _max = i.high.toDouble();
      }
      if (i.low < _min) {
        _min = i.low.toDouble();
      }
      if (i.volume > _maxVolume) {
        _maxVolume = i.volume.toDouble();
      }
    }
    for (var l in widget.lines) {
      if (l.value > _max) {
        _max = l.value;
      }
      if (l.value < _min) {
        _min = l.value;
      }
    }
    return new LimitedBox(
      maxHeight: widget.fallbackHeight,
      maxWidth: widget.fallbackWidth,
      child: GestureDetector(
        onTapUp: (detail) {
          _onUnselect();
        },
        onTapDown: (detail) {
          _onPositionUpdate(detail.localPosition);
        },
        onHorizontalDragEnd: (detail) {
          _onUnselect();
        },
        onHorizontalDragStart: (detail) {
          _onPositionUpdate(detail.localPosition);
        },
        onHorizontalDragUpdate: (detail) {
          _onPositionUpdate(detail.localPosition);
        },
        onVerticalDragStart: (detail) {
          _onPositionUpdate(detail.localPosition);
        },
        onVerticalDragUpdate: (detail) {
          _onPositionUpdate(detail.localPosition);
        },
        onVerticalDragEnd: (detail) {
          _onUnselect();
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: new _CandleStickChartPainter(
            widget.data,
            lineWidth: widget.lineWidth,
            gridLineColor: widget.gridLineColor,
            gridLineAmount: widget.gridLineAmount,
            gridLineWidth: widget.gridLineWidth,
            gridLineLabelColor: widget.gridLineLabelColor,
            enableGridLines: widget.enableGridLines,
            volumeProp: widget.volumeProp,
            labelPrefix: widget.labelPrefix,
            increaseColor: widget.increaseColor,
            decreaseColor: widget.decreaseColor,
            cursorColor: widget.cursorColor,
            showCursorCircle: widget.showCursorCircle,
            showCursorInfoBox: widget.showCursorInfoBox,
            cursorTextColor: widget.cursorTextColor,
            cursorLabelBoxColor: widget.cursorLabelBoxColor,
            volumeSectionOffset: widget.volumeSectionOffset,
            valueLabelBoxType: widget.valueLabelBoxType,
            cursorLineWidth: widget.cursorLineWidth,
            cursorLineDashed: widget.cursorLineDashed,
            xAxisLabelCount: widget.xAxisLabelCount,
            pointsMappingX: pointsMappingX,
            pointsMappingY: pointsMappingY,
            lines: widget.lines,
            formatFn: widget.formatFn,
            formatValueLabelWithK: widget.formatValueLabelWithK,
            cursorX: _cursorX,
            cursorY: _cursorY,
            cursorYPrice: _cursorYPrice,
            cursorXTime: _cursorXTime,
            fullscreenGridLine: widget.fullscreenGridLine,
            showXAxisLabels: widget.showXAxisLabel,
            xAxisLabelFormatFn: widget.xAxisLabelFormatFn,
            infoBoxLayout: widget.infoBoxLayout,
            selectedData: _selectedData,
            valueLabelWidth: valueLabelWidth,
            valueLabelHeight: valueLabelHeight,
            valueLabelFontSize: valueLabelFontSize,
            xAxisLabelWidth: xAxisLabelWidth,
            xAxisLabelHeight: xAxisLabelHeight,
          ),
        ),
      ),
    );
  }
}

typedef FormatFn = String Function(double val);

typedef XAxisLabelFormatFn = String Function(DateTime date);

class _CandleStickChartPainter extends CustomPainter {
  _CandleStickChartPainter(
    this.data, {
    @required this.lineWidth,
    @required this.enableGridLines,
    @required this.gridLineColor,
    @required this.gridLineAmount,
    @required this.gridLineWidth,
    @required this.gridLineLabelColor,
    @required this.volumeProp,
    @required this.labelPrefix,
    @required this.increaseColor,
    @required this.decreaseColor,
    @required this.cursorColor,
    @required this.showCursorCircle,
    @required this.showCursorInfoBox,
    @required this.cursorTextColor,
    @required this.cursorLabelBoxColor,
    @required this.volumeSectionOffset,
    @required this.valueLabelBoxType,
    @required this.cursorLineWidth,
    @required this.cursorLineDashed,
    @required this.pointsMappingX,
    @required this.pointsMappingY,
    @required this.xAxisLabelCount,
    @required this.lines,
    @required this.infoBoxLayout,
    this.formatValueLabelWithK,
    this.formatFn,
    this.xAxisLabelFormatFn,
    this.cursorX = -1,
    this.cursorY = -1,
    this.cursorYPrice = 0,
    this.cursorXTime = 0,
    this.selectedData,
    this.fullscreenGridLine = false,
    this.showXAxisLabels = false,
    @required this.valueLabelWidth,
    @required this.valueLabelFontSize,
    @required this.valueLabelHeight,
    @required this.xAxisLabelWidth,
    @required this.xAxisLabelHeight,
  });

  final List<CandleStickChartData> data;
  final double lineWidth;
  final bool enableGridLines;
  final Color gridLineColor;
  final int gridLineAmount;
  final double gridLineWidth;
  final Color gridLineLabelColor;
  final String labelPrefix;
  final double volumeProp;
  final Color increaseColor;
  final Color decreaseColor;

  final ValueLabelBoxType valueLabelBoxType;
  final bool showCursorCircle;
  final bool showCursorInfoBox;
  final Color cursorColor;
  final Color cursorTextColor;
  final Color cursorLabelBoxColor;
  final double cursorLineWidth;
  final List<_ChartPointMapping> pointsMappingX;
  final List<_ChartPointMapping> pointsMappingY;
  final List<LineValue> lines;
  final double cursorX;
  final double cursorY;
  final double cursorYPrice;
  final int cursorXTime;
  final double volumeSectionOffset;
  final bool cursorLineDashed;
  final bool formatValueLabelWithK;

  final double valueLabelWidth;
  final double valueLabelFontSize;
  final double valueLabelHeight;

  final double xAxisLabelWidth;
  final double xAxisLabelHeight;

  final FormatFn formatFn;
  final XAxisLabelFormatFn xAxisLabelFormatFn;
  final int xAxisLabelCount;

  final bool fullscreenGridLine;
  final bool showXAxisLabels;

  final CandleStickChartData selectedData;

  final ChartInfoBoxLayout infoBoxLayout;

  double _min;
  double _max;
  double _maxVolume;

  TextPainter maxVolumePainter;

  numCommaParse(double n) {
    if (this.formatFn != null) {
      return this.formatFn(n);
    }
    if (this.formatValueLabelWithK) {
      return CandleStickChartValueFormat.formatPricesWithK(n); 
    }
    return CandleStickChartValueFormat.formatPricesWithComma(n);
  }

  _timeParse(int time, bool onlyTime) {
    var date = DateTime.fromMillisecondsSinceEpoch(time);
    if (this.xAxisLabelFormatFn != null) {
      return this.xAxisLabelFormatFn(date);
    }
    if (onlyTime) {
      var hour = date.hour;
      var minute = date.minute;
      return "${hour < 10 ? "0" : ""}${hour.toString()}:${minute < 10 ? "0" : ""}${minute.toString()}";
    } else {
      var day = date.day;
      var month = date.month;
      return "${month < 10 ? "0" : ""}${month.toString()}/${day < 10 ? "0" : ""}${day.toString()}";
    }
  }

  update() {
    _min = double.infinity;
    _max = -double.infinity;
    _maxVolume = -double.infinity;
    for (var i in data) {
      if (i.high > _max) {
        _max = i.high.toDouble();
      }
      if (i.low < _min) {
        _min = i.low.toDouble();
      }
      if (i.volume > _maxVolume) {
        _maxVolume = i.volume.toDouble();
      }
    }

    for (var l in lines) {
      if (l.value > _max) {
        _max = l.value;
      }
      if (l.value < _min) {
        _min = l.value;
      }
    }

    if (enableGridLines) {
      // Label volume line
      maxVolumePainter = TextPainter(
        text: TextSpan(
          text: labelPrefix + numCommaParse(_maxVolume),
          style: TextStyle(
            color: gridLineLabelColor,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      maxVolumePainter.layout();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_min == null || _max == null || _maxVolume == null) {
      update();
    }
    final double volumeHeight = size.height * volumeProp;
    final double volumeNormalizer = (volumeHeight - volumeSectionOffset) / _maxVolume;

    double width = size.width;
    final double height = size.height * (1 - volumeProp);
    double volumeGridLineStartY = height + volumeSectionOffset;

    Paint gridLinePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = gridLineWidth;
    if (enableGridLines) {
      if (!fullscreenGridLine) {
        width = size.width - valueLabelWidth;
      }
      double gridLineDist = height / (gridLineAmount - 1);
      double gridLineY;

      double gridLineValue;
      // Draw grid lines
      for (int i = 0; i < gridLineAmount; i++) {
        gridLineY = (gridLineDist * i).round().toDouble();
        if (fullscreenGridLine) {
          // draw lines, text will be painted afterwards in order to put it over candles
          var gridLineY = (gridLineDist * i).round().toDouble();
          canvas.drawLine(
            Offset(0, gridLineY),
            Offset(size.width, gridLineY),
            gridLinePaint
          );
        } else {
          gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);
          _drawValueLabel(
            canvas: canvas,
            size: size,
            value: gridLineValue,
            lineColor: gridLineColor,
            boxColor: Colors.transparent,
            textColor: gridLineLabelColor,
            lineWidth: gridLineWidth,
            dashed: false,
          );
        }
      }
      
      double quoteBorderX = size.width - valueLabelWidth;
      canvas.drawLine(
        Offset(quoteBorderX, 0),
        Offset(quoteBorderX, gridLineY),
        gridLinePaint
      );

      // Label volume line
      if (volumeProp > 0) {
        // maxVolumePainter.paint(canvas, new Offset(8, gridLineY + 2.0));
        // TODO: GET STARTX
        double startX = 0;
        var lineYTop = gridLineY + volumeSectionOffset;
        var endX = size.width;
        _drawVolumeValueLabel(
          canvas: canvas,
          startX: startX,
          endX: endX,
          lineY: lineYTop,
          value: _maxVolume,
          lineColor: gridLineColor,
          textColor: gridLineLabelColor,
          lineWidth: gridLineWidth,
        );
        var lineYMiddle = size.height - (volumeHeight - volumeSectionOffset)/2;
        _drawVolumeValueLabel(
          canvas: canvas,
          startX: startX,
          endX: endX,
          lineY: lineYMiddle,
          value: _maxVolume/2,
          lineColor: gridLineColor,
          textColor: gridLineLabelColor,
          lineWidth: gridLineWidth,
        );
        var lineYBottom = size.height;
        _drawVolumeValueLabel(
          canvas: canvas,
          startX: startX,
          endX: endX,
          lineY: lineYBottom,
          value: 0,
          lineColor: gridLineColor,
          textColor: gridLineLabelColor,
          lineWidth: gridLineWidth,
        );
        endX -= valueLabelWidth;
        canvas.drawLine(
          Offset(endX, lineYTop), 
          Offset(endX, lineYBottom),
          gridLinePaint
        );
      }
    }

    final double heightNormalizer = height / (_max - _min);
    final double rectWidth = width / data.length;

    double rectLeft;
    double rectTop;
    double rectRight;
    double rectBottom;

    Paint rectPaint;
    Paint candleVerticalLinePaint = new Paint()..strokeWidth = 1;
    pointsMappingX.clear();
    pointsMappingY.clear();

    for (int i = 0; i < data.length; i++) {
      rectLeft = (i * rectWidth) + lineWidth / 2;
      rectRight = ((i + 1) * rectWidth) - lineWidth / 2;
      pointsMappingX.add(
        _ChartPointMapping(
          from: rectLeft,
          to: rectRight
        ),
      );
    }
    // draw x axis value labels
    if (this.showXAxisLabels) {
      var nLabels = this.xAxisLabelCount;
      if (data.length > nLabels) {
        var firstTime = data.first.dateTime.millisecondsSinceEpoch;
        var lastTime = data.last.dateTime.millisecondsSinceEpoch;

        var sameDay = (lastTime - firstTime) <= 8.64e+7;

        int indexDist = (data.length ~/ (1 + nLabels));
        var i = indexDist;
        var paragraphWidth = 40.0;
        double dx = 0;
        int n = 0;
        do {
          dx = pointsMappingX[i].from +
              ((pointsMappingX[i].from - pointsMappingX[i].to) / 2);
          // draw value paragraphs
          final Paragraph paragraph = _getParagraphBuilderFromString(
            value: _timeParse(data[i].dateTime.millisecondsSinceEpoch, sameDay),
            textColor: gridLineLabelColor
          ).build()..layout(
            ParagraphConstraints(
              width: paragraphWidth,
            ),
          );
          canvas.drawParagraph(
            paragraph,
            Offset(
              dx - paragraphWidth / 2 + rectWidth / 2 + lineWidth / 2,
              height + 6,
            ),
          );
          var lineX = dx + rectWidth / 2 + lineWidth;
          var gridLineLabelPaint = Paint()..color = gridLineLabelColor;
          canvas.drawLine(
            Offset(lineX, 0),
            Offset(lineX, height),
            gridLineLabelPaint
          );

          canvas.drawLine(
            Offset(lineX, volumeGridLineStartY),
            Offset(lineX, size.height),
            gridLineLabelPaint
          );
          i += indexDist;
          n++;
        } while (i < data.length - 1 &&
          dx < (size.width - valueLabelWidth - paragraphWidth / 2) &&
          n < nLabels);
      }
    }

    // Loop through all data
    for (int i = 0; i < data.length; i++) {
      rectLeft = pointsMappingX[i].from;
      rectRight = pointsMappingX[i].to;
      double volumeBarTop = (height + volumeHeight) -
        (data[i].volume * volumeNormalizer - lineWidth / 2);
      double volumeBarBottom = height + volumeHeight + lineWidth / 2;

      if (data[i].open > data[i].close) {
        // Draw candlestick if decrease
        rectTop = height - (data[i].open - _min) * heightNormalizer;
        rectBottom = height - (data[i].close - _min) * heightNormalizer;
        rectPaint = new Paint()
          ..color = decreaseColor
          ..strokeWidth = lineWidth;

        Rect ocRect =
            new Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom);
        canvas.drawRect(ocRect, rectPaint);

        // Draw volume bars if decrease
        Rect volumeRect = new Rect.fromLTRB(
            rectLeft, volumeBarTop, rectRight, volumeBarBottom);
        canvas.drawRect(volumeRect, rectPaint);

        candleVerticalLinePaint..color = decreaseColor;
      } else {
        // Draw candlestick if increase
        rectTop = (height - (data[i].close - _min) * heightNormalizer) +
            lineWidth / 2;
        rectBottom = (height - (data[i].open - _min) * heightNormalizer) -
            lineWidth / 2;
        rectPaint = new Paint()
          ..color = increaseColor
          ..strokeWidth = lineWidth;

        Rect ocRect =
          new Rect.fromLTRB(rectLeft, rectTop, rectRight, rectBottom);
        canvas.drawRect(ocRect, rectPaint);

        // Draw volume bars if increase
        Rect volumeRect = new Rect.fromLTRB(
          rectLeft,
          volumeBarTop,
          rectRight,
          volumeBarBottom
        );
        canvas.drawRect(volumeRect, rectPaint);

        candleVerticalLinePaint..color = increaseColor;
      }

      // Draw low/high candlestick wicks
      double low = height - (data[i].low - _min) * heightNormalizer;
      double high = height - (data[i].high - _min) * heightNormalizer;
      canvas.drawLine(
        new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectBottom),
        new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, low),
        candleVerticalLinePaint);
      canvas.drawLine(
        new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, rectTop),
        new Offset(rectLeft + rectWidth / 2 - lineWidth / 2, high),
        candleVerticalLinePaint);
      // add to pointsMapping
      pointsMappingY.add(
        _ChartPointMapping(
          from: low,
          to: height,
        ),
      );
    }

    if (enableGridLines && fullscreenGridLine) {
      for (int i = 0; i < gridLineAmount; i++) {
        double gridLineDist = height / (gridLineAmount - 1);
        var gridLineY = (gridLineDist * i).round().toDouble();
        var gridLineValue = _max - (((_max - _min) / (gridLineAmount - 1)) * i);
        // draw value paragraphs
        final Paragraph paragraph =
          _getParagraphBuilderFromDouble(gridLineValue, gridLineLabelColor)
            .build()
              ..layout(
                ParagraphConstraints(
                  width: valueLabelWidth,
                ),
              );
        canvas.drawParagraph(
          paragraph,
          Offset(
            size.width - valueLabelWidth,
            gridLineY - valueLabelFontSize - 4,
          ),
        );
      }
    }

    // draw custom lines
    for (var line in this.lines) {
      _drawValueLabel(
        canvas: canvas,
        size: size,
        value: line.value,
        lineColor: line.lineColor,
        boxColor: line.lineColor,
        textColor: line.textColor,
        lineWidth: line.lineWidth,
        dashed: line.dashed,
      );
    }

    var cursorPaint = Paint()
      ..color = this.cursorColor
      ..strokeWidth = this.cursorLineWidth;
    

    // draw cursor circle
    if (this.showCursorCircle && this.cursorX != -1 && this.cursorY != -1) {
      canvas.drawCircle(
        Offset(this.cursorX, this.cursorY),
        3,
        cursorPaint,
      );
    }

    // draw cursor vertical line
    if (this.cursorX != -1) {
      final max = size.height - volumeHeight; // size gets to width
      double dashWidth = 5;
      var dashSpace = 5;
      double startY = 0;
      final space = (dashSpace + dashWidth);
      if (cursorLineDashed) {
        while (startY < max) {
          canvas.drawLine(
            Offset(cursorX, startY),
            Offset(cursorX, startY + dashWidth),
            cursorPaint
          );
          startY += space;
        }
      } else {
        canvas.drawLine(
          Offset(cursorX, 0),
          Offset(cursorX, max),
          cursorPaint,
        );
      }
      // draw x axis cursor label
      var labelPath = Path();
      var halfLabelWidth = xAxisLabelWidth / 2; 
      var labelLeft = math.max(cursorX - halfLabelWidth, 0.0);
      labelPath.moveTo(labelLeft, max);
      labelPath.relativeLineTo(xAxisLabelWidth, 0);
      labelPath.relativeLineTo(0, xAxisLabelHeight);
      labelPath.relativeLineTo(-xAxisLabelWidth, 0);
      labelPath.relativeLineTo(0, -xAxisLabelHeight);
      canvas.drawPath(
        labelPath,
        Paint()..color = this.cursorLabelBoxColor
      );
      final Paragraph paragraph = _getParagraphBuilderFromString(
        value: _timeParse(this.cursorXTime, false),
        textColor: this.cursorTextColor
      ).build()
      ..layout(
        ParagraphConstraints(
          width: valueLabelWidth,
        )
      );
      canvas.drawParagraph(
        paragraph,
        Offset(
          labelLeft,
          max + valueLabelFontSize / 2
        )
      );
    }

    if (this.cursorY != -1) {
      // draw cursor horizontal line
      _drawValueLabel(
        canvas: canvas,
        size: size,
        value: this.cursorYPrice,
        lineColor: this.cursorColor,
        boxColor: this.cursorLabelBoxColor,
        textColor: this.cursorTextColor,
        lineWidth: this.cursorLineWidth,
        dashed: cursorLineDashed,
      );
      
      // TODO: Draw cursor info box
      double infoBoxMargin = 1;
      var infoBoxBackgroundColor = infoBoxLayout.backgroundColor
        .withOpacity(infoBoxLayout.backgroundOpacity);
      var open = infoBoxLayout.formatValuesFn(selectedData.open);
      var close = infoBoxLayout.formatValuesFn(selectedData.close);
      var high = infoBoxLayout.formatValuesFn(selectedData.high);
      var low = infoBoxLayout.formatValuesFn(selectedData.low);
      var volume = infoBoxLayout.formatValuesFn(selectedData.volume);
      var date = DateTime.fromMillisecondsSinceEpoch(this.cursorXTime);
      var dateStr = intl.DateFormat(infoBoxLayout.dateFormatStr).format(date);
      String infoBoxText = [
        dateStr,
        "Open: $open",
        "Close: $close",
        "High: $high",
        "Low: $low",
        "Volume: $volume",
      ].join('\n');
      var infoBoxTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: infoBoxText,
          style: TextStyle(
            color: infoBoxLayout.textColor,
            fontWeight: infoBoxLayout.fontWeight,
          ),
        ),
      )..layout(
        minWidth: valueLabelWidth,
        maxWidth: valueLabelWidth*2,
      );
      var infoBoxWidth = infoBoxTextPainter.width;
      var infoBoxHeight = infoBoxTextPainter.height;
      var infoBoxWidthAndMargin = infoBoxWidth + infoBoxMargin;
      var infoBoxHeightAndMargin = infoBoxHeight + infoBoxMargin;
      var infoBoxPath = Path();
      double infoBoxLeft, infoBoxTop;
      double infoBoxFingerOffset = infoBoxLayout.infoBoxFingerOffset;
      double fingerOffsetRatio = 
        10* (1 - this.cursorY/(infoBoxHeightAndMargin + infoBoxMargin));
      fingerOffsetRatio = math.max(0, fingerOffsetRatio); // not smaller than 0
      fingerOffsetRatio = math.min(1, fingerOffsetRatio); // not bigger than 1
      infoBoxFingerOffset *= fingerOffsetRatio; // get the proportional offset
      if (this.cursorX > infoBoxWidthAndMargin + infoBoxMargin + infoBoxFingerOffset) {
        infoBoxLeft = this.cursorX - infoBoxWidthAndMargin;
        infoBoxFingerOffset *= -1;
      } else {
        infoBoxLeft = this.cursorX + infoBoxMargin;
      }
      if (this.cursorY > infoBoxHeightAndMargin + infoBoxMargin) {
        infoBoxTop = this.cursorY - infoBoxHeightAndMargin;
      } else {
        infoBoxTop = infoBoxMargin;
        infoBoxLeft += infoBoxFingerOffset;
      }
      infoBoxPath.moveTo(infoBoxLeft, infoBoxTop);
      infoBoxPath.addRect(
        Rect.fromLTWH(
          infoBoxLeft,
          infoBoxTop,
          infoBoxWidth,
          infoBoxHeight
        )
      );
      canvas.drawPath(
        infoBoxPath,
        Paint()..color = infoBoxBackgroundColor
      );
      infoBoxTextPainter.paint(
        canvas,
        Offset(
          infoBoxLeft + infoBoxMargin,
          infoBoxTop + infoBoxMargin
        )
      );
    }
  }

  void _drawVolumeValueLabel({
    @required Canvas canvas,
    @required double startX,
    @required double endX,
    @required double lineY,
    @required double value,
    @required double lineWidth,
    Color lineColor = Colors.black,
    Color textColor = Colors.white,
  }) {
    canvas.drawLine(
      Offset(startX, lineY),
      Offset(endX - valueLabelWidth, lineY),
      Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth
    );
    final Paragraph paragraph =
      _getParagraphBuilderFromDouble(value, textColor).build()
        ..layout(ParagraphConstraints(
          width: valueLabelWidth,
        ));
    canvas.drawParagraph(paragraph,
      Offset(endX - valueLabelWidth, lineY - valueLabelFontSize / 2));
  }

  // draws line and value box over x-axis
  void _drawValueLabel({
    @required Canvas canvas,
    @required Size size,
    @required double value,
    @required double lineWidth,
    Color lineColor = Colors.black,
    Color boxColor = Colors.black,
    Color textColor = Colors.white,
    bool dashed = false,
  }) {
    final double chartHeight = size.height * (1 - volumeProp);
    var y = (chartHeight * (value - _min)) / (_max - _min);
    y = (y - chartHeight) * -1; // invert y value

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;
    // draw label line
    if (dashed) {
      var max = size.width;
      if (!fullscreenGridLine) {
        max -= valueLabelWidth;
      }
      double dashWidth = 5;
      var dashSpace = 5;
      double startX = 0;
      final space = (dashSpace + dashWidth);
      while (startX < max) {
        var endX = startX + dashWidth;
        endX = endX > max ? max : endX;
        canvas.drawLine(
          Offset(startX, y),
          Offset(endX, y),
          paint,
        );
        startX += space;
      }
    } else {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width - valueLabelWidth, y),
        paint,
      );
    }

    if (valueLabelBoxType == ValueLabelBoxType.roundedRect) {
      // draw rounded rect
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width - valueLabelWidth,
            y - valueLabelHeight / 2,
            valueLabelWidth,
            valueLabelHeight,
          ),
          Radius.circular(valueLabelHeight / 2),
        ),
        Paint()..color = boxColor,
      );
    } else if (valueLabelBoxType == ValueLabelBoxType.rect) {
      // draw rect
      canvas.drawRect(
        Rect.fromLTWH(
          size.width - valueLabelWidth,
          y - valueLabelHeight / 2,
          valueLabelWidth,
          valueLabelHeight,
        ),
        Paint()..color = boxColor,
      );
    } else if (valueLabelBoxType == ValueLabelBoxType.arrowTag) {
      var tagPath = Path();

      //     |---------- w -----------| 
      //     |-w1-|-------- w2 -------|  -> w = w2 + w1 
      //          b___________________c     w2 = w *0.85
      //         /                    |
      //        /                     |
      //      a/                      |
      //       \                      |
      //        \                     |
      //         \____________________|
      //         e                    d

      // move to point 'a'
      tagPath.moveTo(
        size.width - valueLabelWidth,
        y - valueLabelHeight / 2 + valueLabelHeight / 2
      );
      // line from point 'a' to point 'b'
      tagPath.relativeLineTo(valueLabelWidth*0.15, -valueLabelHeight / 2);
      // line from point 'b' to point 'c' 
      tagPath.relativeLineTo(valueLabelWidth*0.85, 0);
      // line from point 'c' to point 'd' 
      tagPath.relativeLineTo(0, valueLabelHeight);
      // line from point 'd' to point 'e' 
      tagPath.relativeLineTo(-valueLabelWidth*0.85, 0);
      // line from point 'e' to point 'a' 
      tagPath.lineTo(
        size.width - valueLabelWidth,
        y - valueLabelHeight / 2 + valueLabelHeight / 2
      );
      canvas.drawPath(tagPath, Paint()..color = boxColor);
    } else if (valueLabelBoxType == ValueLabelBoxType.noTag) {
    } else {
      throw('valueLabelBoxType code not defined');
    }

    // draw value text into rounded rect
    final Paragraph paragraph =
      _getParagraphBuilderFromDouble(value, textColor).build()
        ..layout(ParagraphConstraints(
          width: valueLabelWidth,
        ));
    canvas.drawParagraph(paragraph,
      Offset(size.width - valueLabelWidth, y - valueLabelFontSize / 2));
  }

  ParagraphBuilder _getParagraphBuilderFromDouble(
      double value, Color textColor) {
    return ParagraphBuilder(
      ParagraphStyle(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(TextStyle(
        color: textColor,
        fontSize: valueLabelFontSize,
        fontWeight: FontWeight.bold,
      ).getTextStyle())
      ..addText(
        labelPrefix + numCommaParse(value),
      );
  }

  ParagraphBuilder _getParagraphBuilderFromString({
    @required String value,
    @required Color textColor,
    TextDirection textDirection = TextDirection.ltr,
    TextAlign textAlign = TextAlign.center,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return ParagraphBuilder(
      ParagraphStyle(
        textDirection: textDirection,
        textAlign: textAlign,
      ),
    )
      ..pushStyle(TextStyle(
        color: textColor,
        fontSize: valueLabelFontSize,
        fontWeight: fontWeight,
      ).getTextStyle())
      ..addText(value);
  }

  Paragraph _getPragraphFromString({
    @required String text,
    @required Color color,
    TextDirection textDirection = TextDirection.ltr,
    TextAlign textAlign = TextAlign.center,
    FontWeight fontWeight = FontWeight.bold,
    ParagraphConstraints paragraphConstraints,
  }) {
    return _getParagraphBuilderFromString(
      value: text,
      textColor: color,
      textDirection: textDirection,
      textAlign: textAlign,
      fontWeight: fontWeight
    ).build()
    ..layout(
      paragraphConstraints
    );
  }

  @override
  bool shouldRepaint(_CandleStickChartPainter old) {
    return data != old.data ||
      lineWidth != old.lineWidth ||
      enableGridLines != old.enableGridLines ||
      gridLineColor != old.gridLineColor ||
      gridLineAmount != old.gridLineAmount ||
      gridLineWidth != old.gridLineWidth ||
      volumeProp != old.volumeProp ||
      gridLineLabelColor != old.gridLineLabelColor ||
      cursorColor != old.cursorColor ||
      cursorTextColor != old.cursorTextColor ||
      lines.hashCode != old.lines.hashCode ||
      cursorX != old.cursorX ||
      cursorY != old.cursorY ||
      cursorYPrice != old.cursorYPrice ||
      _max != old._max ||
      _min != old._min ||
      _maxVolume != old._maxVolume;
  }
}

class LineValue {
  final double value;
  final Color textColor;
  final Color lineColor;
  final bool dashed;
  final double lineWidth;

  LineValue({
    @required this.value,
    this.textColor = Colors.white,
    this.lineColor = Colors.black,
    this.dashed = false,
    this.lineWidth = 0.5,
  });
}

enum ValueLabelBoxType {
  roundedRect,
  rect,
  arrowTag,
  noTag
}

class CandleStickChartValueFormat {
  static FormatFn formatPricesWithK = (double val) {
    if (val > 999999) {
      return (val / 1000).floor().toString() + 'K';
    } else if (val < 1000) {
      return formatPricesWithComma(val);
    } else {
      return formatPricesWithCommaAndDots(val);
    }
  };
  
  static FormatFn formatPricesWithCommaAndDots = (double val) {
    var out = val.floor().toString();
    var commaIndex = out.length - 3;
    return out.substring(0, commaIndex) + ',' + out.substring(commaIndex);
  };

  static FormatFn formatPricesWithComma = (double n) {
    var decimals = 2;
    if (n < 1) {
      decimals = 4;
    }
    return n.toStringAsFixed(decimals);
  };
}

class CandleStickChartData {
  CandleStickChartData({
    @required this.open,
    @required this.high,
    @required this.low,
    @required this.close,
    this.dateTime,
    this.volume,
    this.selectedPrice,
  });
  double open;
  double high;
  double low;
  double close;
  DateTime dateTime;
  double volume;
  double selectedPrice;
}

class _ChartPointMapping {
  _ChartPointMapping({
    @required this.from,
    @required this.to,
  });

  final double from;
  final double to;
}

class ChartInfoBoxThemes {
  static ChartInfoBoxLayout getDarkTheme() {
    return ChartInfoBoxLayout(
      backgroundColor: Colors.black87,
      backgroundOpacity: 0.6,
      textColor: Colors.white,
      borderColor: Colors.black,
      borderWidth: 5,
      fontWeight: FontWeight.bold,
      formatValuesFn: (double val) {
        return CandleStickChartValueFormat.formatPricesWithK(val);
      },
      dateFormatStr: 'MM/dd/yyyy',
      infoBoxFingerOffset: 40,
    );
  }

  static ChartInfoBoxLayout getLightTheme() {
    var layout = getDarkTheme();
    layout
      ..backgroundColor = Colors.white
      ..textColor = Colors.black;
    return layout;
  }
}

class ChartInfoBoxLayout {
  ChartInfoBoxLayout({
    this.backgroundColor,
    this.backgroundOpacity,
    this.textColor,
    this.borderColor,
    // this.textFont,
    this.borderWidth,
    this.formatValuesFn,
    // this.formatDateFn,
    this.dateFormatStr,
    this.fontWeight,
    this.infoBoxFingerOffset,
  });
  Color backgroundColor;
  double backgroundOpacity;
  Color textColor;
  Color borderColor;
  // final Font textFont;
  double borderWidth;
  Function formatValuesFn;
  // final Function formatDateFn;
  String dateFormatStr;
  FontWeight fontWeight;
  double infoBoxFingerOffset;
}