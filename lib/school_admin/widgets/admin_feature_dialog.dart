import 'package:flutter/material.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const _adminBlue = Color(0xFF023471);
const _adminGreen = Color(0xFF5AB04B);

class AdminFeatureDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final VoidCallback? onClose;

  const AdminFeatureDialog({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 460,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _adminBlue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose ?? () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded, color: _adminBlue),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> showAdminFeatureConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.info_outline_rounded,
  Color confirmColor = _adminGreen,
}) => showDialog<bool>(
  context: context,
  barrierColor: Colors.black38,
  builder: (dialogContext) => AdminFeatureDialog(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _adminBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(height: 1.4, color: _adminBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: confirmColor,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
