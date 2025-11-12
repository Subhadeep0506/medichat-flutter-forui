import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AppSelect extends StatelessWidget {
  final Map<String, String>? itemsMap;
  final List<String>? itemsList;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final Widget? label;
  final String? hint;
  final bool clearable;
  final Widget? prefixIcon;

  const AppSelect({
    super.key,
    this.itemsMap,
    this.itemsList,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.clearable = true,
    this.prefixIcon,
  }) : assert(
         itemsMap != null || itemsList != null,
         'Either itemsMap or itemsList must be provided',
       );

  Map<String, String> _normalizeItems() {
    if (itemsMap != null) return itemsMap!;
    // convert list to map where display and value are the same
    return {for (final it in itemsList!) it: it};
  }

  @override
  Widget build(BuildContext context) {
    final items = _normalizeItems();

    return FSelect<String>(
      label: label,
      hint: hint,
      initialValue: value,
      items: items,
      onChange: onChanged,
      prefixBuilder: prefixIcon != null
          ? (context, styles, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: prefixIcon,
            )
          : null,
      clearable: clearable,
    );
  }
}
