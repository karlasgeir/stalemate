import 'package:example/pages/initialization_refresh/initalization_refresh.dart';
import 'package:flutter/material.dart';

import 'pages/home_page/home_page.dart';
import 'pages/paginated_loader_page/paginated_loader_page.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter StaleMate example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(), // becomes the route named '/'
      routes: <String, WidgetBuilder>{
        '/initialization_refresh': (BuildContext context) =>
            const InitializationRefresh(),
        'paginated_loader': (context) => const PaginatedLoaderPage(),
      },
    ),
  );
}
