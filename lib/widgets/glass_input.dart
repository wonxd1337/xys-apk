import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

/// Input gelap transparan (.bpi / .pi): border kaca, putih saat fokus.
class GlassInput extends StatelessWidget {
  const GlassInput({
    super.key,
    required this.controller,
    this.hint,
    this.number = false,
    this.obscure = false,
    this.onSubmitted,
    this.prefix,
    this.autofocus = false,
    this.action,
  });

  final TextEditingController controller;
  final String? hint;
  final bool number;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final bool autofocus;
  final TextInputAction? action;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscure,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: action,
      onSubmitted: onSubmitted,
      cursorColor: Colors.white,
      style: const TextStyle(fontSize: 15, color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0x59000000),
        hintText: hint,
        hintStyle: const TextStyle(color: C.muted),
        prefixIcon: prefix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: b(C.glassBorder),
        enabledBorder: b(C.glassBorder),
        focusedBorder: b(Colors.white),
      ),
    );
  }
}
