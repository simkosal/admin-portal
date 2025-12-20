import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BaseInputTextField extends StatelessWidget {
  const BaseInputTextField({
    Key? key,
    this.icon,
    this.labelText,
    this.initialValue,
    this.labelHint,
    this.controller,
  }) : super(key: key);
  final IconData? icon;
  final String? labelText;
  final String? initialValue;
  final String? labelHint;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabelTitle(icon ?? Icons.info_rounded, labelText ?? ''),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: labelHint,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        )
      ],
    );
  }
}

Row buildLabelTitle(IconData icon, String labelText) {
  return Row(
    children: [
      Icon(icon, color: Colors.black54),
      SizedBox(width: 4),
      Text(
        labelText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    ],
  );
}
