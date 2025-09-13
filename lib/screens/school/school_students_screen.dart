import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../shared/effects.dart';

class SchoolStudentsScreen extends ConsumerStatefulWidget {
  const SchoolStudentsScreen({super.key});
  @override
  ConsumerState<SchoolStudentsScreen> createState() => _SchoolStudentsScreenState();
}

class _SchoolStudentsScreenState extends ConsumerState<SchoolStudentsScreen> {
  Map<String, dynamic> data = {};
  bool loading = true;

  Future<void> _load(AppUser user) async {
    final svc = ref.read(profileServiceProvider);
    data = await svc.getProfile(user.uid);
    setState(()=> loading = false);
  }

  Future<void> _addClass(AppUser user) async {
    final cls = TextEditingController();
    final sec = TextEditingController();
    final cnt = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx){
      return AlertDialog(
        title: const Text('Add class/section'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cls, decoration: const InputDecoration(labelText: 'Class (e.g., Grade 1)')),
          const SizedBox(height:8),
          TextField(controller: sec, decoration: const InputDecoration(labelText: 'Section (e.g., A)')),
          const SizedBox(height:8),
          TextField(controller: cnt, decoration: const InputDecoration(labelText: 'Students (approx)'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Cancel')),
          ElevatedButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Add')),
        ],
      );
    });
    if (ok==true) {
      final list = (data['classes'] as List? ?? []).toList();
      list.add({'class':cls.text.trim(), 'section':sec.text.trim(), 'studentsApprox': int.tryParse(cnt.text.trim())});
      data['classes'] = list;
      await ref.read(profileServiceProvider).saveProfile(user.uid, data);
      if (!mounted) return;
      showNiceSnack(context, 'Added ${cls.text} ${sec.text}');
      setState((){});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionUserProvider);
    return session.when(
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e,_)=> Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('Not signed in'));
        if (loading) { _load(user); return const Center(child: CircularProgressIndicator()); }

        final classes = (data['classes'] as List?) ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('School Admin')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: ()=>_addClass(user), icon: const Icon(Icons.add), label: const Text('Add class')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data['schoolName'] != null)
                ListTile(
                  title: Text(data['schoolName']),
                  subtitle: Text('Admin: ${(data['adminName'] ?? '')}  •  ${(data['adminPhone'] ?? '')}'),
                ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Upload students (CSV)'),
                  subtitle: const Text('Coming soon – map columns: Name, Class, Section, Parent phone'),
                  trailing: TextButton(onPressed: (){}, child: const Text('Soon')),
                ),
              ),
              const SizedBox(height: 8),
              Text('Classes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              if (classes.isEmpty) const ListTile(title: Text('No classes yet')),
              for (final c in classes)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.class_),
                    title: Text('${c['class'] ?? ''}  ${c['section'] ?? ''}'),
                    subtitle: Text('Students: ${c['studentsApprox'] ?? '-'}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
