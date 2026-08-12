import 'package:flutter/material.dart';

class MobilePdfActions extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final String previewLabel;
  final String saveLabel;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const MobilePdfActions({
    super.key,
    required this.enabled,
    required this.busy,
    required this.previewLabel,
    required this.saveLabel,
    required this.onPreview,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: enabled ? onPreview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023471),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.preview_rounded),
            label: Text(previewLabel),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: enabled ? onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AB04B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.save_alt_rounded),
            label: Text(saveLabel),
          ),
        ),
        TextButton(
          onPressed: busy ? null : onCancel,
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
