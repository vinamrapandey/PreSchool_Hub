import 'package:flutter/material.dart';

class FullReportsScreen extends StatelessWidget {
  final String schoolId;
  const FullReportsScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // TODO: Export to text
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting report...')));
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Full Reports - Phase 2 (Coming Soon)'),
      ),
    );
  }
}
