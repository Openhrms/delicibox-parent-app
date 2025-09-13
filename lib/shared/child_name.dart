import 'package:shared_preferences/shared_preferences.dart';

/// Returns the primary child's name if saved; else a friendly fallback.
Future<String> primaryChildName() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getString('child_primary_name');
  if (v == null || v.trim().isEmpty) return 'your child';
  return v.trim();
}
