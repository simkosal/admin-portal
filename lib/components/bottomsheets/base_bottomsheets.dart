import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/ui/fos/widgets/input_textfield.dart';
import 'package:invoiceninja_flutter/ui/fos/widgets/schedule_time.dart';
import 'package:textfield_tags/textfield_tags.dart';

class BaseBottomSheets {
  void addNew(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          // This allows for the rounded corners and the 'pull-up' effect
          // You can use a custom container for more complex layouts if needed
          // but CupertinoActionSheet provides a good base.
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(onPressed: () {}, child: Body()),
          ],
          cancelButton: Column(
            children: [
              CupertinoActionSheetAction(
                onPressed: () {
                  // Handle Add Visit action
                  Navigator.pop(context); // Close the bottom sheet
                },
                isDefaultAction: true,
                child: const Text(
                  'Add Visit',
                  style: TextStyle(
                      color: CupertinoColors.systemBlue, fontSize: 18),
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
                isDefaultAction: true,
                child: const Text(
                  'Cancel',
                  style:
                      TextStyle(color: CupertinoColors.systemRed, fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final StringTagController tagController = StringTagController();
  List<String> initialTags = [];
  final clientNameController = TextEditingController();
  final locationController = TextEditingController();
  final purposeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Visit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 16),
          BaseInputTextField(
              controller: clientNameController,
              icon: Icons.person_2_outlined,
              labelText: 'Client Name',
              initialValue: '',
              labelHint: 'Sophea'),
          const SizedBox(height: 16),
          BaseInputTextField(
              controller: locationController,
              icon: Icons.location_on_outlined,
              labelText: 'Location',
              initialValue: '',
              labelHint: 'Brown'),
          const SizedBox(height: 16),
          BaseInputTextField(
              controller: purposeController,
              icon: Icons.task_alt,
              labelText: 'Visit Purpose',
              initialValue: '',
              labelHint: 'Purpose'),
          const SizedBox(height: 16),
          VisitPurpose(
            options: [
              'Installation',
              'Routine Maintenance',
              'Sales Demo',
            ],
            initialSelected: '',
            onSelectionChanged: (value) {
              setState(() {
                purposeController.text = value;
              });
            },
          ),
          const SizedBox(height: 16),
          buildLabelTitle(Icons.calendar_month, 'Schedule time'),
          const SizedBox(height: 16),
          ScheduleTime()
        ],
      ),
    );
  }
}

class MultiSelectChips extends StatefulWidget {
  const MultiSelectChips({
    Key? key,
    required this.options,
    this.initialSelected = const [],
    required this.onSelectionChanged,
  }) : super(key: key);
  final List<String> options;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onSelectionChanged;

  @override
  _MultiSelectChipsState createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<MultiSelectChips> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: widget.options.map((option) {
          final isSelected = _selected.contains(option);
          return FilterChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (bool value) {
              setState(() {
                if (value) {
                  _selected.add(option);
                } else {
                  _selected.remove(option);
                }
                widget.onSelectionChanged(_selected);
              });
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.indigo,
            labelStyle:
                TextStyle(color: isSelected ? Colors.white : Colors.black),
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
