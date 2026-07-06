import 'package:flutter/material.dart';

class OverrideReasonSheet extends StatefulWidget {
  final Function(String) onConfirmed;

  const OverrideReasonSheet({super.key, required this.onConfirmed});

  @override
  State<OverrideReasonSheet> createState() => _OverrideReasonSheetState();
}

class _OverrideReasonSheetState extends State<OverrideReasonSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF141A2A),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'State Reason for Clinical Override',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter clinician reasoning...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onConfirmed(_controller.text);
              Navigator.pop(context);
            },
            child: const Text('Confirm & Sign'),
          ),
        ],
      ),
    );
  }
}
