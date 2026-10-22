import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/sfx.dart';
import '../core/theme.dart';

class DropOpt {
  const DropOpt(this.value, this.label);
  final String value;
  final String label;
}

/// Dropdown kaca (pengganti <select> / .dd).
class GlassDropdown extends StatelessWidget {
  const GlassDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  final String value;
  final List<DropOpt> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cur = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.isNotEmpty ? options.first : const DropOpt('', ''),
    );
    return PopupMenuButton<String>(
      onOpened: Sfx.click,
      onSelected: onChanged,
      color: const Color(0xF7121214),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: C.glassBorder),
      ),
      offset: const Offset(0, 48),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 340),
      itemBuilder: (_) => options
          .map((o) => PopupMenuItem<String>(
                value: o.value,
                child: Row(children: [
                  Expanded(
                    child: Text(o.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: o.value == cur.value ? FontWeight.w800 : FontWeight.w500)),
                  ),
                  if (o.value == cur.value) const Icon(FontAwesomeIcons.check, size: 12),
                ]),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x59000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.glassBorder),
        ),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 14, color: C.muted), const SizedBox(width: 10)],
          Expanded(
            child: Text(cur.label,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5)),
          ),
          const SizedBox(width: 8),
          const Icon(FontAwesomeIcons.chevronDown, size: 11, color: C.muted),
        ]),
      ),
    );
  }
}
