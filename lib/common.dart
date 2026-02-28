import 'dart:math';
import 'package:flutter/material.dart';

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final int? divisions;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;
  final String? hintText;

  const SeekBar({
    Key? key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.hintText,
  }) : super(key: key);

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(
      context,
    ).copyWith(tickMarkShape: SliderTickMarkShape.noTickMark, trackHeight: 2.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        children: [
          SliderTheme(
            data: _sliderThemeData.copyWith(
              overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
              thumbShape: HiddenThumbComponentShape(),
              activeTrackColor: Colors.blue.shade100,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            child: ExcludeSemantics(
              child: Slider(
                divisions: widget.divisions,
                min: 0.0,
                max: widget.duration.inMilliseconds.toDouble(),
                value: min(
                  widget.bufferedPosition.inMilliseconds.toDouble(),
                  widget.duration.inMilliseconds.toDouble(),
                ),
                onChanged: (value) {
                  setState(() {
                    _dragValue = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(Duration(milliseconds: value.round()));
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onChangeEnd != null) {
                    widget.onChangeEnd!(Duration(milliseconds: value.round()));
                  }
                  _dragValue = null;
                },
              ),
            ),
          ),
          SliderTheme(
            data: _sliderThemeData.copyWith(
              overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
              inactiveTrackColor: Colors.transparent,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              divisions: widget.divisions,
              min: 0.0,
              max: widget.duration.inMilliseconds.toDouble(),
              value: min(
                _dragValue ?? widget.position.inMilliseconds.toDouble(),
                widget.duration.inMilliseconds.toDouble(),
              ),
              label: widget.hintText,
              onChanged: (value) {
                setState(() {
                  _dragValue = value;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              },
              onChangeEnd: (value) {
                if (widget.onChangeEnd != null) {
                  widget.onChangeEnd!(Duration(milliseconds: value.round()));
                }
                _dragValue = null;
              },
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 0.0,
            child: Text(
              RegExp(
                    r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$',
                  ).firstMatch("$_duration")?.group(1) ??
                  '$_remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 0.0,
            child: Text(
              RegExp(
                    r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$',
                  ).firstMatch("$_remaining")?.group(1) ??
                  '$_remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Duration get _remaining => widget.duration - widget.position;
  Duration get _duration => widget.duration;
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  //PositionData(this.position, this.bufferedPosition, this.duration);

  PositionData(Duration pos, Duration buf, Duration dur)
    : position = pos < Duration.zero ? Duration.zero : pos,
      bufferedPosition = buf < Duration.zero ? Duration.zero : buf,
      duration = dur < Duration.zero ? Duration.zero : dur;
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  // TODO: Replace these two by ValueStream.
  required double value,
  required Stream<double> stream,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => SizedBox(
          height: 100.0,
          child: Column(
            children: [
              Text(
                '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                style: const TextStyle(
                  fontFamily: 'Fixed',
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              ),
              Slider(
                divisions: divisions,
                min: min,
                max: max,
                value: snapshot.data ?? value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

T? ambiguate<T>(T? value) => value;
