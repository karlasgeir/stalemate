import 'package:example/widgets/app_page_button.dart';
import 'package:example/widgets/app_page_buttons.dart';
import 'package:example/widgets/app_page_title.dart';
import 'package:example/widgets/bullet_points.dart';
import 'package:flutter/material.dart';

class SimpleUsageErrorState extends StatelessWidget {
  final VoidCallback refreshLoader;
  final VoidCallback resetLoader;
  final bool refreshing;
  final bool errorRefreshing;
  final bool isLoading;
  final Object error;

  const SimpleUsageErrorState({
    Key? key,
    required this.refreshLoader,
    required this.resetLoader,
    required this.refreshing,
    required this.errorRefreshing,
    required this.isLoading,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppPageTitle(title: 'Error!'),
        const SizedBox(height: 12),
        const BulletPoints(
          points: [
            BulletPoint(
              text: 'The loader has encountered an error',
            ),
            BulletPoint(
              level: 2,
              text: 'Error was thrown while fetching the remote data',
            ),
            BulletPoint(
              level: 2,
              text:
                  'The error is only reported in the data stream if the loader has the showLocalDataOnError parameter set to false or there is no local data to show',
            ),
            BulletPoint(
              level: 2,
              text:
                  'The error will be resolved when the loader is reset or when the remote data is successfully fetched',
            ),
          ],
        ),
        const Spacer(),
        if (isLoading) const Center(child: CircularProgressIndicator()),
        const Spacer(),
        Text(
          'The error is: $error',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        AppPageButtons(
          buttons: [
            AppPageButton(
              text: 'Refresh Loader',
              onPressed: refreshLoader,
              isDisabled: isLoading,
              isLoading: refreshing,
            ),
            AppPageButton(
              text: 'Reset Loader',
              isDisabled: isLoading,
              onPressed: resetLoader,
            ),
          ],
        )
      ],
    );
  }
}
