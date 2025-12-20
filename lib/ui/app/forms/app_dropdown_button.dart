// // Flutter imports:
// import 'package:flutter/material.dart';

// class AppDropdownButton<T> extends StatelessWidget {
//   const AppDropdownButton({
//     Key? key,
//     required this.value,
//     required this.onChanged,
//     required this.items,
//     this.selectedItemBuilder,
//     this.labelText,
//     this.showBlank =false = false,
//     this.blankValue = '',
//     this.blankLabel,
//     this.enabled = true,
//     this.autofocus = false,
//   }) : super(key: key);

//   final String? labelText;
//   final dynamic value;
//   final Function(dynamic)? onChanged;
//   final List<DropdownMenuItem<T>> items;
//   final bool showBlank;
//   final bool enabled;
//   final bool autofocus;
//   final dynamic blankValue;
//   final String? blankLabel;
//   final DropdownButtonBuilder? selectedItemBuilder;

//   @override
//   Widget build(BuildContext context) {
//     dynamic checkedValue = value;
//     final values = items.toList().map((option) => option.value).toList();
//     if (!values.contains(value)) {
//       checkedValue = blankValue;
//     }
//     final bool isEmpty = checkedValue == null || checkedValue == '';

//     return DropdownButtonFormField<T>(
//       decoration: labelText != null
//           ? InputDecoration(label: Text(labelText!))
//           : InputDecoration.collapsed(hintText: ''),
//       value: checkedValue == blankValue ? null : checkedValue,
//       isExpanded: true,
//       autofocus: autofocus,
//       isDense: labelText != null,
//       onChanged: enabled ? onChanged : null,
//       selectedItemBuilder: selectedItemBuilder,
//       items: [
//         if (showBlank || isEmpty)
//           DropdownMenuItem<T>(
//             value: blankValue,
//             child: blankLabel == null ? SizedBox() : Text(blankLabel!),
//           ),
//         ...items
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';

class AppDropdownButton<T> extends StatelessWidget {
  const AppDropdownButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.selectedItemBuilder,
    this.blankLabel,
    this.blankValue,
    this.showBlank = false,
    this.enabled = true,
    this.autofocus = false,
    this.labelText,
  });

  /// Current selected value.
  final T? value;

  /// Callback when value changes.
  final ValueChanged<T?>? onChanged;

  /// Dropdown items.
  final List<DropdownMenuItem<T>> items;

  /// Optional custom selected item builder.
  final DropdownButtonBuilder? selectedItemBuilder;

  /// Label for blank item if shown.
  final String? blankLabel;

  /// Value for blank option.
  final T? blankValue;

  /// Whether to show the blank option.
  final bool showBlank;

  /// Whether the dropdown is enabled.
  final bool enabled;

  /// Whether to autofocus.
  final bool autofocus;

  /// Optional label for input decoration.
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    // Extract all available values.
    final validValues = items.map((e) => e.value).toList();

    // Check if the current value is valid.
    final T? resolvedValue = validValues.contains(value) ? value : blankValue;

    // Should we insert a blank option?
    final bool insertBlank = showBlank || !validValues.contains(value);

    final List<DropdownMenuItem<T>> finalItems = [
      if (insertBlank && blankValue != null)
        DropdownMenuItem<T>(
          value: blankValue,
          child:
              blankLabel == null ? const SizedBox.shrink() : Text(blankLabel!),
        ),
      ...items,
    ];

    return DropdownButtonFormField<T>(
      value: resolvedValue == blankValue ? null : resolvedValue,
      items: finalItems,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      autofocus: autofocus,
      decoration: labelText != null
          ? InputDecoration(labelText: labelText)
          : const InputDecoration.collapsed(hintText: ''),
      selectedItemBuilder: selectedItemBuilder,
    );
  }
}
