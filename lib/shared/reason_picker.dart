import 'package:flutter/material.dart';

Future<String?> showReasonSheet({
  required BuildContext context,
  required String title,
  required List<String> reasons, // Do NOT include "Other" here
  String otherLabel = 'Other',
  String hint = 'Add a short note (optional)',
}) async {
  String? selected;
  final noteCtrl = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final selectedColor = theme.colorScheme.primary.withOpacity(.15);
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    for (final r in reasons)
                      ChoiceChip(
                        label: Text(r),
                        selected: selected == r,
                        selectedColor: selectedColor,
                        onSelected: (_) => setState(() => selected = r),
                      ),
                    ChoiceChip(
                      label: Text(otherLabel),
                      selected: selected == otherLabel,
                      selectedColor: selectedColor,
                      onSelected: (_) => setState(() => selected = otherLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add a short note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (selected == null && noteCtrl.text.trim().isEmpty) {
                            Navigator.pop(ctx, null);
                            return;
                          }
                          final note = noteCtrl.text.trim();
                          final base = selected ?? otherLabel;
                          Navigator.pop(ctx, note.isEmpty ? base : '$base – $note');
                        },
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
