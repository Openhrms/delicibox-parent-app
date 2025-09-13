import 'package:flutter/material.dart';

class ReasonVisuals {
  final List<Color> confetti;
  final Color snackColor;
  final IconData icon;      // large icon / snack
  final IconData smallIcon; // tiny cell badge
  final String emoji;
  const ReasonVisuals({
    required this.confetti,
    required this.snackColor,
    required this.icon,
    required this.smallIcon,
    required this.emoji,
  });
}

ReasonVisuals visualsFor(String reasonRaw, BuildContext context) {
  final s = reasonRaw.toLowerCase();
  List<Color> pal(List<int> hexes) => hexes.map((h) => Color(0xFF000000 | h)).toList();

  if (s.contains('not feeling') || s.contains('sick') || s.contains('ill')) {
    return ReasonVisuals(
      confetti: const [], // no confetti for this reason
      snackColor: const Color(0xFF26A69A),
      icon: Icons.volunteer_activism,
      smallIcon: Icons.healing, // tiny badge in cell
      emoji: '🩺',
    );
  }
  if (s.contains('travel') || s.contains('vacation') || s.contains('trip')) {
    return ReasonVisuals(
      confetti: pal([0x42A5F5, 0x29B6F6, 0x26C6DA, 0x90CAF9]),
      snackColor: const Color(0xFF29B6F6),
      icon: Icons.flight_takeoff,
      smallIcon: Icons.flight,
      emoji: '✈️',
    );
  }
  if (s.contains('celebration') || s.contains('party')) {
    return ReasonVisuals(
      confetti: pal([0xE91E63, 0xFF9800, 0x7C4DFF, 0xF06292]),
      snackColor: const Color(0xFFE91E63),
      icon: Icons.celebration,
      smallIcon: Icons.celebration,
      emoji: '🎉',
    );
  }
  if (s.contains('festival')) {
    return ReasonVisuals(
      confetti: pal([0xFF7043, 0xFFB300, 0x2E7D32, 0xF57F17]),
      snackColor: const Color(0xFFF57F17),
      icon: Icons.local_fire_department_outlined,
      smallIcon: Icons.emoji_objects_outlined,
      emoji: '🪔',
    );
  }
  if (s.contains('exam') || s.contains('study')) {
    return ReasonVisuals(
      confetti: pal([0xFFD54F, 0xFFEE58, 0x42A5F5, 0x7E57C2]),
      snackColor: const Color(0xFF7E57C2),
      icon: Icons.menu_book_outlined,
      smallIcon: Icons.menu_book,
      emoji: '📚',
    );
  }
  if (s.contains('family')) {
    return ReasonVisuals(
      confetti: pal([0xEF5350, 0xEC407A, 0xFF8A80, 0xF48FB1]),
      snackColor: const Color(0xFFEC407A),
      icon: Icons.favorite,
      smallIcon: Icons.favorite,
      emoji: '💖',
    );
  }
  // Default / Other
  return ReasonVisuals(
    confetti: pal([0x6C63FF, 0xFF6584, 0xFFB74D, 0x29B6F6, 0x66BB6A]),
    snackColor: const Color(0xFF6C63FF),
    icon: Icons.check_circle,
    smallIcon: Icons.check_circle,
    emoji: '✨',
  );
}
