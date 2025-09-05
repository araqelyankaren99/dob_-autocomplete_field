import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DobAutocompleteField extends StatefulWidget {
  const DobAutocompleteField({
    super.key,
    required this.dobFormatter,
    this.hintText = 'Date of Birth*',
    this.textColor = Colors.black,
    this.onFilledChanged,
    this.onChanged,
    this.onFullyDeleted,
  });

  final String hintText;
  final String dobFormatter;
  final ValueChanged<bool>? onFilledChanged;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFullyDeleted;
  final Color textColor;

  @override
  State<DobAutocompleteField> createState() => DobAutocompleteFieldState();
}

class DobAutocompleteFieldState extends State<DobAutocompleteField> {
  final _controller = TextEditingController();
  late DOBTextInputFormatter _formatter;
  final _focusNode = FocusNode();

  String? _hintText;

  @override
  void initState() {
    super.initState();
    _formatter = DOBTextInputFormatter(
      format : widget.dobFormatter,
      onFilledChanged: widget.onFilledChanged,
      onFullyDeleted: widget.onFullyDeleted,
      focusNode: _focusNode,
    );
    _focusNode.addListener(_focusNodeListener);
    _updateHintText();
  }

  void _focusNodeListener() {
    if (_focusNode.hasFocus && !_formatter.hasDigits) {
      _controller.text = _formatter.formatDisplay();
      _controller.selection = const TextSelection.collapsed(offset: 0);
    } else if (!_focusNode.hasFocus && !_formatter.hasDigits) {
      _controller.text = '';
    }
    _updateHintText();
  }

  void _updateHintText() {
    setState(() {
      _hintText = _focusNode.hasFocus || _formatter.hasDigits ? null : widget.hintText;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusNodeListener);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _formatter,
      ],
      focusNode: _focusNode,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: _hintText,
        hintStyle: TextStyle(color: widget.textColor),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: TextStyle(
        fontSize: 18,
        color: widget.textColor,
      ),
    );
  }

  void _onChanged(String value){
    widget.onChanged?.call(value);
    _updateHintText();
  }
}

class DOBTextInputFormatter extends TextInputFormatter {
  DOBTextInputFormatter({
    required this.format,
    required this.focusNode,
    this.onFilledChanged, this.onFullyDeleted,
  }): _placeholders = format.split(''),
        _separatorPositions = [],
        _maxDigits = format.split('').where((c) => c == 'M' || c == 'D' || c == 'Y').length {
    for (int i = 0; i < format.length; i++) {
      if (!['M', 'D', 'Y'].contains(format[i])) {
        _separatorPositions.add(i);
      }
    }
  }

  final FocusNode focusNode;
  final String format;
  final ValueChanged<bool>? onFilledChanged;
  final VoidCallback? onFullyDeleted;

  bool get hasDigits => _digits.isNotEmpty;

  final List<String> _digits = [];
  final List<String> _placeholders;
  final List<int> _separatorPositions;
  final int _maxDigits;
  bool _isFilled = false;


  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newInput = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newInput.length < _digits.length) {
      _digits.removeLast();
      if (_digits.isEmpty) {
        onFullyDeleted?.call();
        return TextEditingValue(
          text: focusNode.hasFocus ? formatDisplay() : '',
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else if (newInput.length > _digits.length && newInput.length <= _maxDigits) {
      _digits.add(newInput.characters.last);
    }

    final newIsFilled = _digits.length == _maxDigits;
    if (newIsFilled != _isFilled) {
      _isFilled = newIsFilled;
      onFilledChanged?.call(_isFilled);
    }

    final formattedText = formatDisplay();
    final cursorOffset = calculateCursorPosition(_digits.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  String formatDisplay() {
    final result = List.from(_placeholders);
    int digitIndex = 0;
    for (int i = 0; i < result.length && digitIndex < _digits.length; i++) {
      if (['M', 'D', 'Y'].contains(result[i])) {
        result[i] = _digits[digitIndex];
        digitIndex++;
      }
    }
    return result.join('');
  }

  int calculateCursorPosition(int digitCount) {
    if (digitCount == 0) {
      return 0;
    }

    int cursorPos = 0;
    int digitsPlaced = 0;

    for (int i = 0; i < format.length && digitsPlaced < digitCount; i++) {
      if (['M', 'D', 'Y'].contains(format[i])) {
        digitsPlaced++;
        cursorPos = i + 1;
      }
    }
    return cursorPos;
  }
}