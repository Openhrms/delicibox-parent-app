import 'package:flutter/material.dart';

class ChildEditor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const ChildEditor({super.key, this.initial});

  @override
  State<ChildEditor> createState() => _ChildEditorState();
}

class _ChildEditorState extends State<ChildEditor> {
  final _name = TextEditingController();
  final _klass = TextEditingController();   // “class” is reserved in Dart
  final _section = TextEditingController();
  final _admission = TextEditingController();
  final _school = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial ?? {};
    _name.text      = (i['name'] ?? '').toString();
    _klass.text     = (i['class'] ?? '').toString();
    _section.text   = (i['section'] ?? '').toString();
    _admission.text = (i['admissionNo'] ?? '').toString();
    _school.text    = (i['schoolName'] ?? '').toString();
    _address.text   = (i['schoolAddress'] ?? '').toString();
  }

  @override
  void dispose() {
    _name.dispose(); _klass.dispose(); _section.dispose();
    _admission.dispose(); _school.dispose(); _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isEdit ? 'Edit child' : 'Add child',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name', prefixIcon: Icon(Icons.child_care_outlined)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(
              controller: _klass,
              decoration: const InputDecoration(
                labelText: 'Class', prefixIcon: Icon(Icons.class_outlined)),
            )),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _section,
              decoration: const InputDecoration(
                labelText: 'Section', prefixIcon: Icon(Icons.view_week_outlined)),
            )),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _admission,
            decoration: const InputDecoration(
              labelText: 'Admission No', prefixIcon: Icon(Icons.confirmation_number_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _school,
            decoration: const InputDecoration(
              labelText: 'School name', prefixIcon: Icon(Icons.school_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            minLines: 2, maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'School address', prefixIcon: Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: FilledButton(
              onPressed: _name.text.trim().isEmpty ? null : () {
                Navigator.pop<Map<String, dynamic>>(context, {
                  'name': _name.text.trim(),
                  'class': _klass.text.trim(),
                  'section': _section.text.trim(),
                  'admissionNo': _admission.text.trim(),
                  'schoolName': _school.text.trim(),
                  'schoolAddress': _address.text.trim(),
                });
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ),
        ],
      ),
    );
  }
}
