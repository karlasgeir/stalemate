import 'package:example/widgets/app_page_button.dart';
import 'package:example/widgets/app_page_buttons.dart';
import 'package:example/widgets/app_page_title.dart';
import 'package:example/widgets/bullet_points.dart';
import 'package:flutter/material.dart';

class InitializationRefreshDataState extends StatelessWidget {
  final VoidCallback refreshLoader;
  final VoidCallback refreshLoaderWithError;
  final VoidCallback resetLoader;
  final bool initializing;
  final bool refreshing;
  final bool errorRefreshing;
  final bool isLoading;
  final String data;

  const InitializationRefreshDataState({
    Key? key,
    required this.refreshLoader,
    required this.refreshLoaderWithError,
    required this.resetLoader,
    required this.initializing,
    required this.refreshing,
    required this.errorRefreshing,
    required this.isLoading,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppPageTitle(title: 'We have data!'),
        const SizedBox(height: 12),
        if (initializing) ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader is initializing',
              ),
              BulletPoint(
                level: 2,
                text: 'Local data is present while the remote data is loading',
              ),
              BulletPoint(
                level: 2,
                text: 'The remote data will take 5 seconds to load',
              )
            ],
          ),
        ] else if (refreshing) ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader is refreshing',
              ),
              BulletPoint(
                level: 2,
                text:
                    'Old data is shown while the new remote data is being fetched',
              ),
              BulletPoint(
                level: 2,
                text:
                    'When new data is received, the loader updates the data stream',
              ),
              BulletPoint(
                level: 2,
                text:
                    'The refresh call also returns the result of the refresh, which can be used to show the user whether the refresh was successful or not',
              ),
              BulletPoint(
                level: 2,
                text: 'The remote data will take 5 seconds to load',
              ),
            ],
          ),
        ] else if (errorRefreshing) ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader will refresh with an error',
              ),
              BulletPoint(
                level: 2,
                text:
                    'Old data is shown while the new remote data is being fetched',
              ),
              BulletPoint(
                level: 2,
                text:
                    'Since the loader has the showLocalDataOnError parameter set to true, the error will not show up in the stream',
              ),
              BulletPoint(
                level: 2,
                text:
                    'The result of the refresh call can be used to show the user whether the refresh was successful or not',
              ),
              BulletPoint(
                level: 2,
                text:
                    'To see the error in the stream, reset the loader before refreshing with error',
              ),
              BulletPoint(
                level: 2,
                text: 'The remote data will take 5 seconds to throw the error',
              ),
            ],
          ),
        ] else ...[
          const BulletPoints(
            points: [
              BulletPoint(
                text: 'The loader has received the remote data',
              ),
              BulletPoint(
                level: 2,
                text:
                    'You can try to refresh the loader to see the refresh flow',
              ),
              BulletPoint(
                level: 2,
                text:
                    'If you refresh with error without resetting the loader, the error will not show up in the stream because the loader has the showLocalDataOnError parameter set to true',
              ),
              BulletPoint(
                level: 2,
                text: 'You can also reset the loader to see the reset flow',
              ),
            ],
          ),
        ],
        const Spacer(),
        if (isLoading) const Center(child: CircularProgressIndicator()),
        const Spacer(),
        Text(
          'Current data is: $data',
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
              text: 'Refresh Loader with error',
              onPressed: refreshLoaderWithError,
              isDisabled: isLoading,
              isLoading: errorRefreshing,
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
