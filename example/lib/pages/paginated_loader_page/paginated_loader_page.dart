import 'package:example/pages/paginated_loader_page/widgets/paginated_loader_example_widget.dart';
import 'package:example/widgets/base_app_page.dart';
import 'package:flutter/material.dart';
import 'package:stalemate/stalemate.dart';

class PaginatedLoaderPage extends StatelessWidget {
  const PaginatedLoaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseAppPage(
      title: 'Paginated Loader example',
      body: PaginatedLoaderExampleWidget(
        paginationConfig: StaleMatePagePagination(
          pageSize: 10,
          zeroBasedIndexing: false,
        ),
      ),
    );
  }
}
