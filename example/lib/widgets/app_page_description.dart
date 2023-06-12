import 'package:flutter/material.dart';

class AppPageDescription extends StatelessWidget {
  final String description;

  const AppPageDescription({
    Key? key,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(
        description,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      );
}
