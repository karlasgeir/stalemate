import 'package:example/widgets/app_page_button.dart';
import 'package:example/widgets/app_page_buttons.dart';
import 'package:example/widgets/app_page_title.dart';
import 'package:example/widgets/bullet_points.dart';
import 'package:flutter/material.dart';

class SimpleUsageEmptyState extends StatelessWidget {
  final VoidCallback refreshLoader;
  final VoidCallback refreshLoaderWithError;
  final bool refreshing;
  final bool errorRefreshing;
  final bool isLoading;

  const SimpleUsageEmptyState({
    Key? key,
    required this.refreshLoader,
    required this.refreshLoaderWithError,
    required this.refreshing,
    required this.errorRefreshing,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppPageTitle(title: 'Empty data'),
        const SizedBox(height: 12),
        if (refreshing) ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader is refreshing',
              ),
              BulletPoint(
                level: 2,
                text:
                    'There is no old data to show while the new remote data is being fetched since the loader was reset',
              ),
              BulletPoint(
                level: 2,
                text:
                    'When new data is received, the loader updates the data stream',
              ),
            ],
          ),
        ] else if (errorRefreshing) ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader is refreshing with error',
              ),
              BulletPoint(
                level: 2,
                text:
                    'There is no old data to show while the new remote data is being fetched since the loader was reset',
              ),
              BulletPoint(
                level: 2,
                text:
                    'When the error is received, the loader updates the data stream with the error',
              ),
            ],
          ),
        ] else ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader is empty',
              ),
              BulletPoint(
                level: 2,
                text:
                    'The loader is empty, meaning that it has no data but is not loading',
              ),
              BulletPoint(
                level: 2,
                text:
                    'This happens when the loader is reset or when the local and remote data are both empty',
              ),
            ],
          ),
        ],
        const Spacer(),
        if (isLoading) const Center(child: CircularProgressIndicator()),
        const Spacer(),
        AppPageButtons(
          buttons: [
            AppPageButton(
              text: 'Refresh Loader',
              onPressed: refreshLoader,
              isDisabled: isLoading,
              isLoading: refreshing,
            ),
            AppPageButton(
              text: 'Refresh Loader with error',
              onPressed: refreshLoaderWithError,
              isDisabled: isLoading,
              isLoading: errorRefreshing,
            ),
          ],
        )
      ],
    );
  }
}
