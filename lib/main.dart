import 'package:flutter/material.dart';
import 'pages/opening_page.dart';

void main() {
  runApp(const SafeScanQrApp());
}

class SafeScanQrApp extends StatelessWidget {
  const SafeScanQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Scan QR',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Arial',
      ),
      home: const OpeningPage(),
    );
  }
}