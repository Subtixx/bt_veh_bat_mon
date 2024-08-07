import 'package:flutter/material.dart';

class DoubleInputWidget extends StatefulWidget {
  final double initialValue;
  final String? placeholder;
  final Function(double) onCommit;

  const DoubleInputWidget(
      {this.placeholder,
      required this.initialValue,
      required this.onCommit,
      super.key})
      : super();

  @override
  _DoubleInputWidgetState createState() => _DoubleInputWidgetState();
}

class _DoubleInputWidgetState extends State<DoubleInputWidget> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_validateInput(_controller.text)) {
        return;
      }

      widget.onCommit(double.parse(_controller.text));
    });

    _controller.text = widget.initialValue.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _validateInput(String value) {
    final double? intValue = double.tryParse(value);
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
      child: TextField(
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
