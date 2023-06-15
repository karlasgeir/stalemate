import 'package:example/pages/home_page/widgets/home_page_list_item.dart';
import 'package:example/widgets/base_app_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseAppPage(
      title: 'StaleMate example',
      body: ListView(
        children: const [
          HomePageListItem(
            title: 'Initialization and Refresh',
            path: '/initialization_refresh',
          ),
          HomePageListItem(
            title: 'Paginated Loader',
            path: 'paginated_loader',
          ),
        ],
      ),
    );
  }
}
