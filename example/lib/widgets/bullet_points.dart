import 'package:flutter/material.dart';

class BulletPoint extends StatelessWidget {
  static double spacingBetweenIconAndText = 6;

  static final levelIcon = {
    1: Icons.circle,
    2: Icons.circle_outlined,
  };

  static final levelFontSize = {
    1: 16,
    2: 14,
  };

  final String text;

  final int level;

  const BulletPoint({
    Key? key,
    required this.text,
    this.level = 1,
  })  : assert(
          level == 1 || level == 2,
          'Only level 1 or 2 is supported.',
        ),
        super(key: key);

  double get fontSize => levelFontSize[level]!.toDouble();

  double get leftSpacing =>
      level == 1 ? 0 : fontSize + spacingBetweenIconAndText;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: leftSpacing,
          ),
          Icon(
            levelIcon[level],
            size: fontSize,
          ),
          const SizedBox(
            width: 6,
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
              ),
            ),
          ),
        ],
      );
}

class BulletPoints extends StatelessWidget {
  final List<BulletPoint> points;

  const BulletPoints({
    Key? key,
    required this.points,
  }) : super(key: key);

  List<Widget> get spacedBulletPoints => points
      .expand(
        (bulletPoint) => [
          bulletPoint,
          const SizedBox(
            height: 12,
          )
        ],
      )
      .toList();

  @override
  Widget build(BuildContext context) => Column(
        children: spacedBulletPoints,
      );
}
