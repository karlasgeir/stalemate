import 'package:example/widgets/app_page_button.dart';
import 'package:example/widgets/app_page_title.dart';
import 'package:example/widgets/bullet_points.dart';
import 'package:flutter/widgets.dart';

class InitializationRefreshLoadingState extends StatelessWidget {
  final VoidCallback initializeLoader;
  final bool initializing;

  const InitializationRefreshLoadingState({
    Key? key,
    required this.initializeLoader,
    required this.initializing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppPageTitle(title: 'No data yet'),
        const SizedBox(height: 24),
        const BulletPoints(
          points: [
            BulletPoint(
              text: 'Loader is not initialized yet',
            ),
            BulletPoint(
              level: 2,
              text: 'Loaders are not initialized automatically',
            ),
            BulletPoint(
              level: 2,
              text: 'To initialize the loader, call the initialize() method',
            ),
          ],
        ),
        const Spacer(),
        AppPageButton(
          text: 'Initialize Loader',
          onPressed: initializeLoader,
          isLoading: initializing,
        ),
      ],
    );
  }
}
