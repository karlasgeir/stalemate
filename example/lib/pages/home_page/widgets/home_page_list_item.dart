import 'package:flutter/material.dart';

class HomePageListItem extends StatelessWidget {
  final String title;
  final String path;

  const HomePageListItem({
    Key? key,
    required this.title,
    required this.path,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          textAlign: TextAlign.center,
        ),
        onTap: () => Navigator.pushNamed(context, path),
      ),
    );
  }
}
