import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../registry/calculator_definition.dart';

/// Styled numeric text field driven by a [FieldDefinition].
///
/// The widget owns its [TextEditingController] to support lifecycle management.
/// It exposes only a string via [onChanged] — parsing lives in
/// [CalculatorController], not here.
class CalculatorInputField extends StatefulWidget {
  const CalculatorInputField({
    super.key,
    required this.field,
    required this.onChanged,
    this.errorText,
  });

  final FieldDefinition field;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<CalculatorInputField> createState() => _CalculatorInputFieldState();
}

class _CalculatorInputFieldState extends State<CalculatorInputField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [
        // Allow digits, dot, and comma (comma normalised to dot in controller).
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: widget.field.label,
        hintText: widget.field.hint,
        errorText: widget.errorText,
        errorMaxLines: 2,
        suffixText: widget.field.unit,
        suffixStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}
