import 'package:flutter/material.dart';
import 'app_icon.dart';

class ReaderTextSizeControl extends StatefulWidget {
  const ReaderTextSizeControl({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.onPreviewChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onPreviewChanged;

  @override
  State<ReaderTextSizeControl> createState() => _ReaderTextSizeControlState();
}

class _ReaderTextSizeControlState extends State<ReaderTextSizeControl> {
  late double _value = widget.value;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant ReaderTextSizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _value = widget.value;
  }

  void _commit(double value) {
    final next = value.clamp(0.82, 1.42).toDouble();
    setState(() => _value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${(_value * 100).round()}%'),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease text size',
                onPressed: _value <= 0.82 ? null : () => _commit(_value - 0.05),
                icon: const AppIcon(Icons.remove_rounded),
              ),
              Expanded(
                child: Slider(
                  value: _value.clamp(0.82, 1.42).toDouble(),
                  min: 0.82,
                  max: 1.42,
                  divisions: 12,
                  onChangeStart: (_) => _dragging = true,
                  onChanged: (value) {
                    setState(() => _value = value);
                    widget.onPreviewChanged?.call(value);
                  },
                  onChangeEnd: (value) {
                    _dragging = false;
                    _commit(value);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Increase text size',
                onPressed: _value >= 1.42 ? null : () => _commit(_value + 0.05),
                icon: const AppIcon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
