import 'package:flutter/material.dart';

class WatchlistView extends StatelessWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          'Watchlist Placeholder',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
