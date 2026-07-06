import 'package:flutter/material.dart';

class DispenseConfirmButton extends StatelessWidget {
  final VoidCallback onConfirmed;
  final bool isEnabled;

  const DispenseConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F52BA),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isEnabled ? onConfirmed : null,
      child: const Text(
        'Confirm & Commit Dispensation',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
