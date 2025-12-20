import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleTime extends StatefulWidget {
  @override
  _ScheduleTimeState createState() => _ScheduleTimeState();
}

class _ScheduleTimeState extends State<ScheduleTime> {
  DateTime _selectedDateTime = DateTime.now();

  String? _selectedSlot;

  final Map<String, DateTime Function()> _slots = {
    'Today Lunch': () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 12, 0); // 12:00
    },
    'Tomorrow Lunch': () {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
    },
    'Today 14:00': () {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 14, 0);
    },
    'Tomorrow 14:00': () {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);
    },
  };

  /// Format the datetime into readable string
  String _formatDateTime(DateTime dt) {
    final date = DateFormat('dd MMM yyyy').format(dt);
    final time = DateFormat('hh:mm a').format(dt);
    return '$date at $time';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo, // header background & selected day
              onPrimary: Colors.white, // header text & selected day text
              onSurface: Colors.black, // body text color
            ),
            dialogBackgroundColor: Colors.grey.shade100,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo, // CANCEL & OK button color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.indigo, // header background, active dial color
                onPrimary: Colors.white, // header text, selected dial text
                onSurface: Colors.black, // body text color
              ),
              dialogBackgroundColor: Colors.grey.shade100, // dialog background
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo, // OK & CANCEL button color
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _selectedSlot = null; // clear chip selection
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected DateTime
          GestureDetector(
            onTap: () {
              _pickDateTime();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatDateTime(_selectedDateTime),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          SizedBox(height: 12),
          // Filter Chips (single select behavior)
          Wrap(
            spacing: 8,
            children: _slots.keys.map((slot) {
              return FilterChip(
                label: Text(slot),
                selected: _selectedSlot == slot,
                onSelected: (selected) {
                  setState(() {
                    _selectedSlot = selected ? slot : null;
                    if (selected) {
                      _selectedDateTime = _slots[slot]!();
                    }
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.indigo,
                labelStyle: TextStyle(
                    color: _selectedSlot == slot ? Colors.white : Colors.black),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class VisitPurpose extends StatefulWidget {
  const VisitPurpose({
    Key? key,
    required this.options,
    required this.initialSelected,
    required this.onSelectionChanged,
  }) : super(key: key);
  final List<String> options;
  final String initialSelected;
  final ValueChanged<String> onSelectionChanged;

  @override
  _VisitPurposeState createState() => _VisitPurposeState();
}

class _VisitPurposeState extends State<VisitPurpose> {
  String? _selectedSlot;
  @override
  void initState() {
    updateSelected(value: widget.initialSelected);
    super.initState();
  }

  void updateSelected({String? value}) {
    setState(() {
      _selectedSlot = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Wrap(
        spacing: 8,
        children: widget.options.map((slot) {
          return FilterChip(
            label: Text(slot),
            selected: _selectedSlot == slot,
            onSelected: (selected) {
              widget.onSelectionChanged(slot);
              updateSelected(value: slot);
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.indigo,
            labelStyle: TextStyle(
                color: _selectedSlot == slot ? Colors.white : Colors.black),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(12),
          );
        }).toList(),
      ),
    );
  }
}
