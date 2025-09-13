import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_type.dart';
import 'register_screen.dart';

class UserTypePickerScreen extends ConsumerWidget {
  const UserTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Responsive grid: 1 col on very narrow, 2 on phones, 3 on tablets+
    final cols = w < 360 ? 1 : (w < 700 ? 2 : 3);

    // Compact screens → shorter tiles
    final compactH = h < 700 || w < 380;
    final tileHeight = compactH ? 172.0 : 188.0;

    final items = UserType.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: tileHeight, // <-- prevents overflow
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final t = items[i];
            return _TypeCard(
              title: userTypeLabel(t),
              subtitle: userTypeDesc(t),
              icon: userTypeIcon(t),
              color: userTypeColor(t),
              compact: compactH,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RegisterScreen(type: t),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}

class _TypeCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;
  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.color.withOpacity(.75);
    final fill = Colors.white;

    final subtitleMax = widget.compact ? 2 : 3;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(.08),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: widget.compact ? 18 : 20,
                backgroundColor: widget.color.withOpacity(.12),
                child: Icon(widget.icon, color: widget.color, size: widget.compact ? 18 : 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: subtitleMax,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54, height: 1.25),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomLeft,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor, width: 2),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36), // keep compact
                    foregroundColor: widget.color,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: widget.onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
