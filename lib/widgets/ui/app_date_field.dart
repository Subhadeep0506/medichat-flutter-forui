import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../utils/date_formatter.dart';

/// AppDateField: small wrapper for Forui's FDateField.calendar used in patient forms.
class AppDateField extends StatelessWidget {
  final FDateFieldController controller;
  final ValueChanged<String?>? onIsoChanged;

  const AppDateField({super.key, required this.controller, this.onIsoChanged});

  @override
  Widget build(BuildContext context) {
    return FDateField.calendar(
      controller: controller,
      label: const Text('Date of Birth'),
      prefixBuilder: (context, styles, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(FIcons.calendar1),
      ),
      clearable: true,
      onChange: (date) {
        if (onIsoChanged != null) {
          onIsoChanged!(
            date != null ? DateFormatter.formatDateForApi(date) : null,
          );
        }
      },
    );
  }
}
