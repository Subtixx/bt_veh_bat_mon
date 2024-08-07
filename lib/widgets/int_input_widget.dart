import 'package:flutter/material.dart';

class IntInputWidget extends StatefulWidget {
  final int initialValue;
  final String? label;
  final String placeholder;
  final Function(int) onCommit;

  const IntInputWidget(
      {required this.placeholder,
      this.label,
      required this.initialValue,
      required this.onCommit,
      super.key})
      : super();

  @override
  _IntInputWidgetState createState() => _IntInputWidgetState();
}

class _IntInputWidgetState extends State<IntInputWidget> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_validateInput(_controller.text)) {
        return;
      }

      widget.onCommit(int.parse(_controller.text));
    });

    _controller.text = widget.initialValue.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateInput(String value) {
    final int? intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 20) {
      setState(() {
        _errorText = 'Please enter a value between 0 and 20';
      });

      return true;
    } else {
      setState(() {
        _errorText = '';
      });

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: widget.label != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label!),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.placeholder,
                    errorText: _errorText.isEmpty ? null : _errorText,
                  ),
                  onChanged: _validateInput,
                ),
              ],
            )
          : TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.placeholder,
                errorText: _errorText.isEmpty ? null : _errorText,
              ),
              onChanged: _validateInput,
            ),
    );
  }
}
