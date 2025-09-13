import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/effects.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final gradeCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    nameCtrl.text = prefs.getString('child_primary_name') ?? '';
    gradeCtrl.text = prefs.getString('child_primary_grade') ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_primary_name', nameCtrl.text.trim());
    await prefs.setString('child_primary_grade', gradeCtrl.text.trim());
    if (!mounted) return;
    showNiceSnack(context, 'Saved profile for ${nameCtrl.text.isEmpty ? "your child" : nameCtrl.text}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Primary child name',
                      hintText: 'e.g., Anvi / Arjun',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Grade/Class (optional)',
                      hintText: 'e.g., Grade 3',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: _load, child: const Text('Reset'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tip: This name personalizes messages such as “Take care of your child: <Name>”.'),
        ],
      ),
    );
  }
}
