import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import 'onboarding_router.dart';

class SchoolOnboarding extends ConsumerStatefulWidget {
  final AppUser user;
  const SchoolOnboarding({super.key, required this.user});

  @override
  ConsumerState<SchoolOnboarding> createState() => _SchoolOnboardingState();
}

class _SchoolOnboardingState extends ConsumerState<SchoolOnboarding> {
  final schoolName = TextEditingController();
  final adminName = TextEditingController();
  final adminPhone = TextEditingController();
  final address = TextEditingController();
  final List<_ClassRow> classes = [_ClassRow()];

  void addClass() => setState(() => classes.add(_ClassRow()));
  void removeClass(int i) => setState(() => classes.removeAt(i));

  Future<void> save() async {
    final data = {
      'schoolName': schoolName.text.trim(),
      'adminName': adminName.text.trim(),
      'adminPhone': adminPhone.text.trim(),
      'address': address.text.trim(),
      'classes': [
        for (final c in classes)
          {
            'class': c.className.text.trim(),
            'section': c.section.text.trim(),
            'studentsApprox': c.students.text.trim().isEmpty
                ? null
                : int.tryParse(c.students.text.trim()),
          }
      ],
    };
    await ref.read(profileServiceProvider).updateProfile(widget.user.uid, data);
    await OnboardingRouter.complete(context, ref, widget.user);
  }

  @override
  void dispose() {
    schoolName
      ..dispose();
    adminName
      ..dispose();
    adminPhone
      ..dispose();
    address
      ..dispose();
    for (final c in classes) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: schoolName,
              decoration: const InputDecoration(labelText: 'School name')),
          const SizedBox(height: 8),
          TextField(
              controller: adminName,
              decoration:
                  const InputDecoration(labelText: 'Admin/Coordinator name')),
          const SizedBox(height: 8),
          TextField(
              controller: adminPhone,
              decoration: const InputDecoration(labelText: 'Admin phone')),
          const SizedBox(height: 8),
          TextField(
              controller: address,
              decoration:
                  const InputDecoration(labelText: 'Address (optional)')),
          const SizedBox(height: 16),
          Text('Classes & Sections',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (int i = 0; i < classes.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: classes[i].className,
                      decoration: const InputDecoration(
                          labelText: 'Class (e.g., Grade 1)'),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      controller: classes[i].section,
                      decoration:
                          const InputDecoration(labelText: 'Section (e.g., A)'),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: TextField(
                      controller: classes[i].students,
                      decoration: const InputDecoration(
                          labelText: 'Students (approx)'),
                      keyboardType: TextInputType.number,
                    )),
                    if (classes.length > 1)
                      IconButton(
                          onPressed: () => removeClass(i),
                          icon: const Icon(Icons.delete_outline)),
                  ]),
                ]),
              ),
            ),
          TextButton.icon(
              onPressed: addClass,
              icon: const Icon(Icons.add),
              label: const Text('Add class/section')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: save, child: const Text('Save & Continue')),
          const SizedBox(height: 8),
          const Text(
            'Tip: You can import students via CSV later from School Admin.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ClassRow {
  final TextEditingController className = TextEditingController();
  final TextEditingController section = TextEditingController();
  final TextEditingController students = TextEditingController();
  void dispose() {
    className.dispose();
    section.dispose();
    students.dispose();
  }
}
