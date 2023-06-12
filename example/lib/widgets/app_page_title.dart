import 'package:flutter/material.dart';

class AppPageTitle extends StatelessWidget {
  final String title;

  const AppPageTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      );
}
