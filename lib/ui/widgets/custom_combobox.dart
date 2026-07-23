import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomComboBox extends StatefulWidget {
  final int initialValue;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const CustomComboBox({
    super.key,
    required this.initialValue,
    this.options = const [5, 10, 25, 50, 100, 250],
    required this.onChanged,
  });

  @override
  State<CustomComboBox> createState() => _CustomComboBoxState();
}

class _CustomComboBoxState extends State<CustomComboBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void didUpdateWidget(covariant CustomComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue(int val) {
    if (val > 0) {
      _controller.text = val.toString();
      widget.onChanged(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed > 0) {
                  widget.onChanged(parsed);
                }
              },
              onSubmitted: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed > 0) {
                  _updateValue(parsed);
                }
              },
            ),
          ),
          PopupMenuButton<int>(
            icon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textMuted,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            color: AppColors.bgCard,
            onSelected: _updateValue,
            itemBuilder: (context) => widget.options
                .map(
                  (opt) => PopupMenuItem<int>(
                    value: opt,
                    height: 32,
                    child: Text(
                      '$opt items',
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
