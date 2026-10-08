import 'package:flutter/material.dart';

/// Halaman sementara untuk fitur yang dikerjakan di Sprint berikutnya.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.sprint});

  final String title;
  final int sprint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Halaman ini dikerjakan di Sprint $sprint.')),
    );
  }
}
