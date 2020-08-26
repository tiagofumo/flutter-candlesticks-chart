import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart' as intl;

class CandleStickChart extends StatelessWidget {
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
    @required this.enableGridLines,
    @required this.volumeProp,
    this.increaseColor = Colors.green,
    this.decreaseColor = Colors.red,
    this.volumeSectionOffset = 0,
    this.lines = const [],
    this.formatValueLabelFn,
    this.formatValueLabelWithK = false,
    this.valueLabelBoxType = ValueLabelBoxType.roundedRect,
    this.xAxisLabelCount = 3,
    this.fullscreenGridLine = false,
    this.showXAxisLabel = false,
    this.cursorPosition,
    this.infoBoxStyle,
    this.cursorStyle = const CandleChartCursorStyle(),
  }) : super(key: key) {
    assert(data != null);
    if (fullscreenGridLine) {
      assert(enableGridLines);
    }
    if (formatValueLabelFn != null) {
      assert(!formatValueLabelWithK);
    }
    if (infoBoxStyle == null) {
      infoBoxStyle = ChartInfoBoxThemes.getLightTheme();
    }
  }

  // final List data;
  final List<CandleStickChartData> data;

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

  final double volumeSectionOffset; 

  final ValueLabelBoxType valueLabelBoxType; 

  // draw lines on chart
  final List<LineValue> lines;

  /// formatFn is applyed to all values displyed on chart if provided
  final FormatFn formatValueLabelFn;

  final int xAxisLabelCount;

  final bool fullscreenGridLine;

  final bool showXAxisLabel;

  final bool formatValueLabelWithK;

  ChartInfoBoxStyle infoBoxStyle;

  Offset cursorPosition;

  final CandleChartCursorStyle cursorStyle;

  final List<_ChartPointMapping> pointsMappingX = List();
  final List<_ChartPointMapping> pointsMappingY = List();

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
      maxHeight: fallbackHeight,
      maxWidth: fallbackWidth,
      child: CustomPaint(
        size: Size.infinite,
        painter: new _CandleStickChartPainter(
          data,
          lineWidth: lineWidth,
          gridLineColor: gridLineColor,
          gridLineAmount: gridLineAmount,
          gridLineWidth: gridLineWidth,
          gridLineLabelColor: gridLineLabelColor,
          enableGridLines: enableGridLines,
          volumeProp: volumeProp,
          labelPrefix: labelPrefix,
          increaseColor: increaseColor,
          decreaseColor: decreaseColor,
          volumeSectionOffset: volumeSectionOffset,
          valueLabelBoxType: valueLabelBoxType,
          xAxisLabelCount: xAxisLabelCount,
          lines: lines,
          formatValueLabelFn: formatValueLabelFn,
          formatValueLabelWithK: formatValueLabelWithK,
          fullscreenGridLine: fullscreenGridLine,
          showXAxisLabels: showXAxisLabel,
          infoBoxStyle: infoBoxStyle,
          cursorPosition: cursorPosition,
          pointsMappingX: pointsMappingX,
          pointsMappingY: pointsMappingY,
          cursorStyle: cursorStyle,
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
    @required this.volumeSectionOffset,
    @required this.valueLabelBoxType,
    @required this.pointsMappingX,
    @required this.pointsMappingY,
    @required this.xAxisLabelCount,
    @required this.lines,
    @required this.infoBoxStyle,
    @required this.formatValueLabelWithK,
    @required this.formatValueLabelFn,
    @required this.fullscreenGridLine,
    @required this.showXAxisLabels,
    @required this.cursorPosition,
    @required this.cursorStyle,
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
  final List<_ChartPointMapping> pointsMappingX;
  final List<_ChartPointMapping> pointsMappingY;
  final List<LineValue> lines;
  final double volumeSectionOffset;
  final bool formatValueLabelWithK;

  final FormatFn formatValueLabelFn;
  final int xAxisLabelCount;

  final bool fullscreenGridLine;
  final bool showXAxisLabels;

  final ChartInfoBoxStyle infoBoxStyle;

  final Offset cursorPosition;

  final CandleChartCursorStyle cursorStyle;

  double _min;
  double _max;
  double _maxVolume;

  double _cursorX = -1;
  double _cursorY = -1;
  double _cursorYPrice = 0;
  int _cursorXTime = 0;

  CandleStickChartData _selectedData;

  final double valueLabelWidth = 60.0;
  final double valueLabelFontSize = 10.0;
  final double valueLabelHeight = 20.0; // this must be valueLabelFontSize*2

  final double xAxisLabelWidth = 60;
  final double xAxisLabelHeight = 20;

  void clearCursor() {
    _cursorX = -1;
    _cursorY = -1;
  }

  void _onPositionUpdate(Offset position, Size size) {
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
    var widgetHeight = size.height;
    var cursorMaxX = size.width - valueLabelWidth;
    var cursorOffset = cursorStyle.cursorOffset;
    var myYPosition =
        (position.dy - widgetHeight + (widgetHeight * volumeProp)) * -1;
    myYPosition += cursorOffset.dy;

    // calc chartHeight without volume part
    final double chartHeight = size.height * (1 - volumeProp);
    var positionPrice = (((_max - _min) * myYPosition) / chartHeight) + _min;

    if (position.dy - cursorOffset.dy > chartHeight ||
          position.dy - cursorOffset.dy < 0 ||
          position.dx - cursorOffset.dx > cursorMaxX) {
      clearCursor();
      return;
    }

    if (cursorStyle.cursorJumpToCandleCenter) {
      // set cursorx at the middle of the candle
      _cursorX = (el.from + el.to) / 2;
    } else {
      _cursorX = position.dx;
    }

    _cursorY = position.dy;
    data[i].selectedPrice = positionPrice;

    _cursorY -= cursorOffset.dy;
    _cursorYPrice = data[i].selectedPrice;
    _cursorXTime = data[i].dateTime.millisecondsSinceEpoch;
    _selectedData = data[i];
  }

  numCommaParse(double n) {
    if (this.formatValueLabelFn != null) {
      return this.formatValueLabelFn(n);
    }
    if (this.formatValueLabelWithK) {
      return CandleStickChartValueFormat.formatPricesWithK(n); 
    }
    return CandleStickChartValueFormat.formatPricesWithComma(n);
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
      double gridLineY = height;

      var gridLinesValues = GridLineHelper.getHorizontalGridLines(
        max: _max,
        min: _min,
        minLineCount: gridLineAmount,
      ); 
      // Draw grid lines
      gridLinesValues.forEach((e) {
        _drawValueLabel(
          canvas: canvas,
          size: size,
          value: e,
          lineColor: gridLineColor,
          boxColor: Colors.transparent,
          textColor: gridLineLabelColor,
          lineWidth: gridLineWidth,
          dashed: false,
          gridLineExtraWidth: 5,
        );
      });
      
      double quoteBorderX = size.width - valueLabelWidth;
      canvas.drawLine(
        Offset(0, 0),
        Offset(quoteBorderX, 0),
        gridLinePaint
      );
      canvas.drawLine(
        Offset(0, gridLineY),
        Offset(quoteBorderX, gridLineY),
        gridLinePaint
      );
      canvas.drawLine(
        Offset(quoteBorderX, 0),
        Offset(quoteBorderX, gridLineY),
        gridLinePaint
      );

      // Label volume line
      if (volumeProp > 0) {
        // TODO: GET STARTX
        double startX = 0;
        var lineYTop = gridLineY + volumeSectionOffset;
        var endX = size.width;
        var volumeGridLinesList = GridLineHelper.getVolumeGridLines([], max: _maxVolume);
        volumeGridLinesList.forEach((volumeGridLineValue) {
          var lineY = size.height - (volumeGridLineValue / _maxVolume) * (size.height - lineYTop);
          _drawVolumeValueLabel(
            canvas: canvas,
            startX: startX,
            endX: endX,
            lineY: lineY,
            value: volumeGridLineValue,
            lineColor: gridLineColor,
            textColor: gridLineLabelColor,
            lineWidth: gridLineWidth,
          );
        });
        endX -= valueLabelWidth;
        canvas.drawLine(
          Offset(startX, lineYTop), 
          Offset(endX, lineYTop),
          gridLinePaint
        );
        canvas.drawLine(
          Offset(startX, size.height), 
          Offset(endX, size.height),
          gridLinePaint
        );
        canvas.drawLine(
          Offset(endX, lineYTop), 
          Offset(endX, size.height),
          gridLinePaint
        );
        var zeroVolumeTextPainter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: "  " + 0.0.toString(),
            style: TextStyle(
              color: gridLineLabelColor,
              fontSize: valueLabelFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        )..layout(
          minWidth: valueLabelWidth,
          maxWidth: valueLabelWidth,
        );
        zeroVolumeTextPainter.paint(
          canvas,
          Offset(endX, size.height - zeroVolumeTextPainter.height + 1)
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
        var dates = data.map((d) => d.dateTime).toList();
        var lineDates = GridLineHelper.getVerticalLinesDates(
          dates: dates,
        );

        var paragraphWidth = 40.0;
        lineDates.forEach((lineDate) { 
          var i = lineDate.index;
          var lineX = pointsMappingX[i].from +
              ((pointsMappingX[i].to - pointsMappingX[i].from) / 2);
          var gridLineLabelPaint = Paint()..color = gridLineLabelColor;
          canvas.drawLine(
            Offset(lineX, 0),
            Offset(lineX, height),
            gridLineLabelPaint
          );

          final Paragraph paragraph = _getParagraphBuilderFromString(
            value: lineDate.label,
            textColor: gridLineLabelColor
          ).build()..layout(
            ParagraphConstraints(
              width: paragraphWidth,
            ),
          );
          canvas.drawParagraph(
            paragraph,
            Offset(
              lineX - paragraphWidth / 2,
              height + 6,
            ),
          );

          canvas.drawLine(
            Offset(lineX, volumeGridLineStartY),
            Offset(lineX, size.height),
            gridLineLabelPaint
          );
        });
      }
    }

    if (cursorPosition == null
        || cursorPosition.dx == -1
        || cursorPosition.dy == -1) {
      clearCursor();
    } else {
      _onPositionUpdate(cursorPosition, size);
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
      ..color = cursorStyle.cursorColor
      ..strokeWidth = cursorStyle.cursorLineWidth;
    

    // draw cursor circle
    if (cursorStyle.showCursorCircle && _cursorX != -1 && _cursorY != -1) {
      canvas.drawCircle(
        Offset(_cursorX, _cursorY),
        3,
        cursorPaint,
      );
    }

    // draw cursor vertical line
    if (_cursorX != -1) {
      final max = size.height - volumeHeight; // size gets to width
      double dashWidth = 5;
      var dashSpace = 5;
      double startY = 0;
      final space = (dashSpace + dashWidth);
      if (cursorStyle.cursorLineDashed) {
        while (startY < max) {
          canvas.drawLine(
            Offset(_cursorX, startY),
            Offset(_cursorX, startY + dashWidth),
            cursorPaint
          );
          startY += space;
        }
      } else {
        canvas.drawLine(
          Offset(_cursorX, 0),
          Offset(_cursorX, max),
          cursorPaint,
        );
      }
      // draw x axis cursor label
      var labelPath = Path();
      var halfLabelWidth = xAxisLabelWidth / 2; 
      var labelLeft = math.max(_cursorX - halfLabelWidth, 0.0);
      labelPath.moveTo(labelLeft, max);
      labelPath.relativeLineTo(xAxisLabelWidth, 0);
      labelPath.relativeLineTo(0, xAxisLabelHeight);
      labelPath.relativeLineTo(-xAxisLabelWidth, 0);
      labelPath.relativeLineTo(0, -xAxisLabelHeight);
      canvas.drawPath(
        labelPath,
        Paint()..color = cursorStyle.cursorLabelBoxColor
      );
      var cursorDateTime = DateTime.fromMillisecondsSinceEpoch(_cursorXTime);
      final Paragraph paragraph = _getParagraphBuilderFromString(
        value: intl.DateFormat(cursorStyle.cursorXAxisFormatString).format(cursorDateTime),
        textColor: cursorStyle.cursorTextColor
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

    if (_cursorY != -1) {
      // draw cursor horizontal line
      _drawValueLabel(
        canvas: canvas,
        size: size,
        value: _cursorYPrice,
        lineColor: cursorStyle.cursorColor,
        boxColor: cursorStyle.cursorLabelBoxColor,
        textColor: cursorStyle.cursorTextColor,
        lineWidth: cursorStyle.cursorLineWidth,
        dashed: cursorStyle.cursorLineDashed,
      );
      
      var infoBoxBackgroundColor = infoBoxStyle.backgroundColor
        .withOpacity(infoBoxStyle.backgroundOpacity);
      var open = infoBoxStyle.formatValuesFn(_selectedData.open);
      var close = infoBoxStyle.formatValuesFn(_selectedData.close);
      var high = infoBoxStyle.formatValuesFn(_selectedData.high);
      var low = infoBoxStyle.formatValuesFn(_selectedData.low);
      var volume = CandleStickChartValueFormat.formatPricesWithAllLetters(_selectedData.volume);
      var date = DateTime.fromMillisecondsSinceEpoch(_cursorXTime);
      var dateStr = intl.DateFormat(infoBoxStyle.dateFormatStr).format(date);
      String infoBoxText = [
        dateStr,
        "${infoBoxStyle.chartI18N.open}: $open",
        "${infoBoxStyle.chartI18N.close}: $close",
        "${infoBoxStyle.chartI18N.high}: $high",
        "${infoBoxStyle.chartI18N.low}: $low",
        "${infoBoxStyle.chartI18N.volume}: $volume",
      ].join('\n');
      var infoBoxTextPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: infoBoxText,
          style: TextStyle(
            color: infoBoxStyle.textColor,
            fontWeight: infoBoxStyle.fontWeight,
            fontSize: infoBoxStyle.textFontSize,
          ),
        ),
      )..layout(
        minWidth: valueLabelWidth * 1.5,
        maxWidth: valueLabelWidth * 2,
      );
      double infoBoxBorderWidth = infoBoxStyle.borderWidth;
      double infoBoxMargin = infoBoxStyle.margin;
      double infoBoxPadding = infoBoxStyle.padding;
      var infoBoxWidth = infoBoxTextPainter.width + (infoBoxBorderWidth + infoBoxPadding) * 2;
      var infoBoxHeight = infoBoxTextPainter.height + (infoBoxBorderWidth + infoBoxPadding) * 2;
      var infoBoxWidthAndMargin = infoBoxWidth + infoBoxMargin;
      var infoBoxHeightAndMargin = infoBoxHeight + infoBoxMargin;
      var infoBoxPath = Path();
      double infoBoxLeft, infoBoxTop;
      double infoBoxFingerOffset = infoBoxStyle.infoBoxFingerOffset;
      double fingerOffsetRatio = 
        10* (1 - _cursorY/(infoBoxHeightAndMargin + infoBoxMargin));
      fingerOffsetRatio = math.max(0, fingerOffsetRatio); // not smaller than 0
      fingerOffsetRatio = math.min(1, fingerOffsetRatio); // not bigger than 1
      infoBoxFingerOffset *= fingerOffsetRatio; // get the proportional offset
      if (_cursorX > infoBoxWidthAndMargin + infoBoxMargin + infoBoxFingerOffset) {
        infoBoxLeft = _cursorX - infoBoxWidthAndMargin - infoBoxMargin;
        infoBoxFingerOffset *= -1;
      } else {
        infoBoxLeft = _cursorX + infoBoxMargin * 2;
      }
      if (_cursorY > infoBoxHeightAndMargin + infoBoxMargin) {
        infoBoxTop = _cursorY - infoBoxHeightAndMargin - infoBoxMargin;
      } else {
        infoBoxTop = infoBoxMargin;
        infoBoxLeft += infoBoxFingerOffset;
      }
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
        Paint()
          ..color = infoBoxBackgroundColor
      );
      canvas.drawPath(
        infoBoxPath,
        Paint()
          ..color = infoBoxStyle.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = infoBoxBorderWidth
      );
      infoBoxTextPainter.paint(
        canvas,
        Offset(
          infoBoxLeft + infoBoxMargin + infoBoxBorderWidth + infoBoxPadding,
          infoBoxTop + infoBoxMargin + infoBoxBorderWidth + infoBoxPadding,
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
    var label = CandleStickChartValueFormat.formatPricesWithAllLetters(value);
    var textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: "  " + label,
        style: TextStyle(
          color: textColor,
          fontSize: valueLabelFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..layout(
      minWidth: valueLabelWidth,
      maxWidth: valueLabelWidth,
    );
    canvas.drawLine(
      Offset(startX, lineY),
      Offset(endX - valueLabelWidth, lineY),
      Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth
    );
    textPainter.paint(
      canvas,
      Offset(endX - valueLabelWidth, lineY - valueLabelFontSize / 2)
    );
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
    double gridLineExtraWidth = 0,
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
        Offset(size.width - valueLabelWidth + gridLineExtraWidth, y),
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
      !cursorStyle.equalTo(old.cursorStyle) ||
      lines.hashCode != old.lines.hashCode ||
      cursorPosition.dx != old.cursorPosition.dx ||
      cursorPosition.dy != old.cursorPosition.dy;
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
  static String _formatDigits(double val) {
    if (val >= 100) {
      return val.floor().toString();
    } else {
      return val.toStringAsFixed(2);
    }
  }

  static FormatFn formatPricesWithAllLetters = (double val) {
    var trillion = math.pow(10, 12);
    var billion = math.pow(10, 9);
    var million = math.pow(10, 6);
    if (val >= trillion) {
      return _formatDigits(val / trillion) + 'T';
    } else if (val >= billion) {
      return _formatDigits(val / billion) + 'B';
    } if (val > million) {
      return _formatDigits(val / million) + 'M';
    } else if (val >= 1000) {
      return _formatDigits(val / 1000) + 'K';
    } else {
      return formatPricesWithComma(val);
    }
  };
  
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

class CandleChartCursorStyle {
  const CandleChartCursorStyle({
    this.showCursorCircle = true,
    this.cursorColor = Colors.black,
    this.cursorLabelBoxColor = Colors.black,
    this.cursorTextColor = Colors.white,
    this.cursorJumpToCandleCenter = false,
    this.cursorLineWidth = 0.5,
    this.cursorOffset = const Offset(0, 0),
    this.cursorLineDashed = false,
    this.cursorXAxisFormatString = 'MM/dd/yyyy',
  });

  final bool showCursorCircle;

  // CursorColor
  final Color cursorColor;

  final Color cursorTextColor;

  final Color cursorLabelBoxColor;

  final double cursorLineWidth;

  final bool cursorLineDashed;

  final bool cursorJumpToCandleCenter;

  final String cursorXAxisFormatString;
  final Offset cursorOffset;

  bool equalTo(CandleChartCursorStyle compared) {
    return showCursorCircle == compared.showCursorCircle &&
      cursorColor == compared.cursorColor &&
      cursorLabelBoxColor == compared.cursorLabelBoxColor &&
      cursorTextColor == compared.cursorTextColor &&
      cursorJumpToCandleCenter == compared.cursorJumpToCandleCenter &&
      cursorLineWidth == compared.cursorLineWidth &&
      cursorOffset == compared.cursorOffset &&
      cursorLineDashed == compared.cursorLineDashed &&
      cursorXAxisFormatString == compared.cursorXAxisFormatString;
  }
}

class ChartInfoBoxThemes {
  static ChartInfoBoxStyle getDarkTheme() {
    return ChartInfoBoxStyle(
      backgroundColor: Colors.black87,
      backgroundOpacity: 0.8,
      textColor: Colors.white,
      borderColor: Colors.white,
      textFontSize: 14,
      borderWidth: 2.5,
      fontWeight: FontWeight.normal,
      formatValuesFn: (double val) {
        return CandleStickChartValueFormat.formatPricesWithK(val);
      },
      dateFormatStr: 'MM/dd/yyyy',
      infoBoxFingerOffset: 40,
      margin: 1.25,
      padding: 3,
      chartI18N: CandleChartI18N(),
    );
  }

  static ChartInfoBoxStyle getLightTheme() {
    var layout = getDarkTheme();
    layout
      ..backgroundColor = Colors.white70
      ..backgroundOpacity = 0.92
      ..borderColor = Colors.black
      ..textFontSize = 12
      ..textColor = Colors.black;
    return layout;
  }
}

class ChartInfoBoxStyle {
  ChartInfoBoxStyle({
    this.backgroundColor,
    this.backgroundOpacity,
    this.textColor,
    this.borderColor,
    // this.textFont,
    this.textFontSize,
    this.borderWidth,
    this.formatValuesFn,
    this.dateFormatStr,
    this.fontWeight,
    this.infoBoxFingerOffset,
    this.padding,
    this.margin,
    this.chartI18N,
  });
  Color backgroundColor;
  double backgroundOpacity;
  Color textColor;
  Color borderColor;
  // final Font textFont;
  double textFontSize;
  double borderWidth;
  Function formatValuesFn;
  String dateFormatStr;
  FontWeight fontWeight;
  double infoBoxFingerOffset;
  double padding;
  double margin;
  CandleChartI18N chartI18N;
}

class CandleChartI18N {
  const CandleChartI18N({
    this.open = 'Open',
    this.close = 'Close',
    this.high = 'High',
    this.low = 'Low',
    this.volume = 'Volume',
  });

  final String open;
  final String close;
  final String high;
  final String low;
  final String volume;
}

class ChartVerticalLineDate {
  DateTime dateTime;
  String label;
  int index;
  ChartVerticalLineDate({this.dateTime, this.label, this.index});
}

class _GridLineValueScore {
  final double value;
  final double score;
  _GridLineValueScore({
    this.value,
    this.score,
  });
}

class GridLineHelper {
  static List<double> getHorizontalGridLines({
    @required double max,
    @required double min,
    @required int minLineCount,
    int maxLineCount,
  }) {
    max = (max * 100).floorToDouble() / 100;
    min = (min * 100).floorToDouble() / 100;
    var diff = max - min;
    double increment = 1;
    int multiplier = 1;
    var newMin = min;
    if (diff <= 3) {
      increment = 0.10;
    } else if (diff > 100) {
      multiplier = math.pow(10, diff.floor().toString().length - 2);
      newMin = (min / multiplier).floorToDouble() * multiplier;
    }
    List<_GridLineValueScore> values = [];
    for (double i = 0; i * multiplier + newMin < max; i += increment) {
      var value = i * multiplier + newMin;
      var characters = value.toStringAsFixed(2).characters.toList();
      int score = 0;
      for (var j = 0; j < characters.length; j++) {
        var c = characters[j];
        // var scoreMultiplier = math.pow(10, characters.length - j);
        var scoreMultiplier = characters.length - j;
        switch (c) {
          case '0':
            score += 9 * scoreMultiplier;
            break;
          case '5':
            score += 6 * scoreMultiplier;
            break;
          // case '2':
          // case '7':
          //   score += 1 * scoreMultiplier;
          //   break;
          default:
            if (c != '.' && score > 0) {
              score -= 9 * scoreMultiplier;
            }
            break;
        }
      }
      values.add(
        _GridLineValueScore(
          value: value,
          score: score.toDouble()
        )
      );
    }
    values.sort((_GridLineValueScore a, _GridLineValueScore b) {
      return a.score.compareTo(b.score) * -1;
    });
    var minScore = values[minLineCount - 1].score;
    List<_GridLineValueScore> filteredValues = [];
    for (var i = 0; i < values.length && values[i].score >= minScore; i++) {
      filteredValues.add(values[i]);
    }
    var orderedValues = filteredValues.map((a) => (a.value * 100).floorToDouble() / 100).toList();
    orderedValues.sort((double a, double b) => a.compareTo(b));
    double minStep = double.infinity;
    for (var i = 1; i < orderedValues.length; i++) {
      var step = orderedValues[i] - orderedValues[i - 1];
      if (step < minStep) {
        minStep = step;
      }
    }
    List<double> output = [];
    double highestNumber = orderedValues.last;
    for (var i = highestNumber; i < max ; i += minStep) {
      highestNumber = i;
    }
    for (var i = highestNumber; i >= newMin && i >= min; i -= minStep) {
      output.add((i * 100).floorToDouble() / 100);
    }
    return output.reversed.toList();
  }

  static List<ChartVerticalLineDate> getVerticalLinesDates({
    List<DateTime> dates,
    int nDates = 4,
    bool monthDayYear = true,
  }) {
    var firstDate = dates.first;
    var lastDate = dates.last;
    int minDateDistance = 3;
    if (dates.length < minDateDistance * nDates + minDateDistance) {
      nDates = ((dates.length - minDateDistance) / minDateDistance).floor();
    }
    if (nDates == 0) {
      return [];
    }

    List<ChartVerticalLineDate> list = [];
    if (lastDate.year == firstDate.year && lastDate.month == firstDate.month) {
      // same year same month
      var dateDistance = dates.length ~/ nDates;
      for (var i = 1; i <= nDates; i++) {
        var dateIndex = i*dateDistance;
        var dateTime = dates[dateIndex];
        list.add(
          ChartVerticalLineDate(
            dateTime: dateTime,
            label: intl.DateFormat('dd').format(dateTime), 
            index: dateIndex,
          )
        );
      }
    } else if (lastDate.year > firstDate.year) {
      // different years
      for (var i = firstDate.year + 1; i <= lastDate.year; i++) {
        var dateIndex = dates.indexWhere((d) => d.year == i);
        var dateTime = dates[dateIndex];
          list.add(
            ChartVerticalLineDate(
              dateTime: dateTime,
              label: dateTime.year.toString(), 
              index: dateIndex, 
            )
          );
        }
    } else {
      // same year not same month
      var firstMonth = firstDate.month;
      var lastMonth = lastDate.month;
      for (var i = firstMonth + 1; i <= lastMonth; i++) {
        var dateIndex = dates.indexWhere((d) => d.month == i);
        var dateTime = dates[dateIndex];
        list.add(
          ChartVerticalLineDate(
            dateTime: dateTime,
            label: intl.DateFormat('MMM').format(dateTime),
            index: dateIndex, 
          )
        );
      }
    }
    return list;
  }

  static List<double> getVolumeGridLines(
    List<double> volumeList,
    {
      double max
    }
  ) {
    if (max == null) {
      max = volumeList.first;
      for (var i = 0; i < volumeList.length; i++) {
        if (volumeList[i] > max) {
          max = volumeList[i];
        }
      }
    }
    var string = max.floor().toString();
    var firstNum = double.parse(string.characters.toList().first);
    var times10 = string.length - 1;
    var pow10 = math.pow(10, times10).toDouble();
    if (firstNum > 5 || firstNum == 5 && max >= firstNum * pow10 * 1.2) {
      return [5.0 * pow10];
    } else if(firstNum == 5 || firstNum == 4) {
      return [2.5 * pow10];
    } else if(firstNum == 3 || firstNum == 2 && max >= 2 * pow10 * 1.15) {
      return [2.0 * pow10];
    } else if(firstNum == 1 && max >= 1000000000 && max <= 1500000000) {
      return [1000000000.0, 500000000.0];
    } else if(firstNum == 2 || firstNum == 1 && max >= pow10 *1.2) {
      return [pow10];
    } else {
      string = (max / 2).floor().toString();
      firstNum = double.parse(string.characters.toList().first);
      times10 = string.length - 1;
      pow10 = math.pow(10, times10).toDouble();
      return [firstNum * pow10];
    }
  }
}