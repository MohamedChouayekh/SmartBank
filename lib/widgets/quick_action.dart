import 'package:flutter/material.dart';

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}