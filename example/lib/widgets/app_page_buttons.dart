import 'package:example/widgets/app_page_button.dart';
import 'package:flutter/material.dart';

class AppPageButtons extends StatelessWidget {
  final List<AppPageButton> buttons;

  const AppPageButtons({
    Key? key,
    required this.buttons,
  }) : super(key: key);

  List<Widget> get spacedButtons => buttons
      .expand(
        (button) => [
          button,
          const SizedBox(
            height: 12,
          )
        ],
      )
      .toList();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: spacedButtons,
      );
}
