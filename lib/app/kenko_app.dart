import 'package:flutter/material.dart';
import 'package:kenko_shop/app/theme.dart';

class KenkoApp extends StatelessWidget {
  const KenkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kenko Fresh',
      theme: buildKenkoTheme(),
      home: const Scaffold(
        body: Center(child: Text('Kenko Fresh')),
      ),
    );
  }
}
