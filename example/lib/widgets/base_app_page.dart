import 'package:flutter/material.dart';

class BaseAppPage extends StatelessWidget {
  final String title;
  final Widget body;

  const BaseAppPage({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: body,
        ),
      ),
    );
  }
}
