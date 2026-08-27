import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/app.dart';
import 'package:watchmark/app/bootstrap.dart';

void main() async {
  await bootstrap();
  runApp(
    const ProviderScope(
      child: WatchMarkApp(),
    ),
  );
}
