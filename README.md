<a href="https://github.com/karlasgeir/stalemate/actions"><img src="https://github.com/karlasgeir/stalemate/workflows/test-stalemate/badge.svg" alt="Build Status"></a>

**StaleMate** is a data synchronization library for Flutter applications. Its primary purpose is to simplify the process of keeping remote and local data in sync while offering a flexible and agnostic approach to data storage and retrieval. With StaleMate, you are free to utilize any data storage or fetching method that suits your needs, be it **Hive**, **Isar**, **secure storage**, **shared preferences**, or any **HTTP client** for remote data retrieval.

# Key Features

## Flexible Data Management

StaleMate offers flexibility in terms of how you fetch or store your data. This means you can integrate StaleMate seamlessly with your preferred methods for data fetching from remote servers or local data storage.

StaleMate primarily serves as a tool to synchronize your data from a server with your local cache. However, it's important to note that StaleMate itself does not provide built-in caching functionality. The responsibility of how and where to cache data is entirely up to you, giving you complete control and flexibility over your application's data management strategies.

## Automatic Data Refresh

StaleMate provides two mechanisms to automatically synchronize your data:

1. **Stale Period**: This feature allows you to set a configurable duration after which your data will be automatically considered as stale and refreshed accordingly. This built-in mechanism ensures that your data never exceeds a specific age, thereby maintaining its relevance.
2. **Time-of-Day Refresh**: This feature enables you to specify a precise time each day at which your data should be automatically refreshed. This is particularly useful for daily updates, such as fetching a new daily offer from a server.

StaleMate respects the lifecycle of your app: no updates occur while your app is in the background. Nevertheless, if the data is identified as stale upon the resumption of your app, StaleMate will promptly fetch the new data. This ensures the immediate availability of the most current data for your users.

> It's important to note that even with these automatic refresh strategies in place, you retain the ability to manually refresh your loader at any given time.

## Pagination Support

StaleMate provides a **StaleMatePaginatedLoader** that extends the core functionality of the **StaleMateLoader** with pagination support. This feature enables you to manage large data sets with ease by fetching data in manageable 'pages'.

The StaleMatePaginatedLoader is designed for versatility, supporting three common pagination strategies out of the box: page-based, offset/limit-based, and cursor-based pagination. Moreover, if these strategies do not meet your needs, StaleMate provides the flexibility to implement custom pagination configurations by extending the base PaginationConfig class.

## State Management Agnostic

StaleMate is designed to seamlessly integrate with state management solutions, not as a replacement for comprehensive state management libraries. It provides a data stream and actions such as refresh and reset for the loader, complementing your existing state management setup.

For simpler use cases, StaleMate can function independently.

StaleMate comes with a handy **StaleMateBuilder** widget. This utility widget simplifies handling different data states. Alternatively, you may utilize a **StreamBuilder** to react to changes in the data stream or manually subscribe to the data stream. This gives you the versatility to handle data updates in a way that best suits your specific project requirements.

With StaleMate, managing and synchronizing your local and remote data has never been easier!

# Getting started

## Step 1: Adding Dependency

First, you need to add StaleMate as a dependency in your Flutter project. In your pubspec.yaml file, add the following line under dependencies:

```yaml
dependencies:
  stalemate: ^[latest_version]
```

## Step 2: Importing the package

Import StaleMate in the Dart file where you want to use it.

```dart
import 'package:stalemate/stalemate.dart';
```

# Usage

## Create a StaleMateHandler

**StaleMateLoaders** utilize **StaleMateHandlers** for storing and retrieving data. To create a handler, extend the **StaleMateHandler** class and implement the **emptyValue** getter, as well as the **getLocalData**, **getRemoteData**, **storeLocalData**, and **removeLocalData** methods.

Here's an example of a simple ToDo handler implementation:

```dart
class TodosHandler extends StaleMateHandler<List<ToDo>> {
  final TodoRemoteDatasource remoteDataSource;
  final TodoLocalDatasource localDataSource;

  TodosLoader({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Override the empty value. This is usually just the empty
  /// representation of your data type. It is used to indicate
  /// that the loader is empty and provides a value when the loader is reset.
  @override
  List<ToDo> get emptyValue => [];

  /// Retrieve the local data.
  @override
  Future<List<ToDo>> getLocalData() async {
    return localDataSource.getTodos();
  }

  /// Retrieve the remote data.
  @override
  Future<List<ToDo>> getRemoteData() async {
    return remoteDataSource.getTodos();
  }

  /// Store the local data.
  @override
  Future<void> storeLocalData(List<ToDo> data) async {
    localDataSource.storeTodos(data);
  }

  /// Remove the local data.
  @override
  Future<void> removeLocalData() async {
    localDataSource.removeTodos();
  }
}
```

### LocalOnlyStaleMateHandler

For data that is not stored server side, extend the **LocalOnlyStaleMateHandler** instead of the **StaleMateHandler**. The main difference is that you won't override the getRemoteData method.

> You can update the data by calling **addData(updatedTodos)** on the loader, see [Manually refreshing the data](#manually-refreshing-the-data)

Here's an example of a local-only ToDo handler implementation:

```dart
class TodosLocalOnlyHandler extends LocalOnlyStaleMateHandler<List<ToDo>> {
  final TodoLocalDatasource localDataSource;

  TodosLocalOnlyHandler({
    required this.localDataSource,
  });

  @override
  List<ToDo> get emptyValue => [];

  @override
  Future<List<ToDo>> getLocalData() async {
    return localDataSource.getTodos();
  }

  @override
  Future<void> storeLocalData(List<ToDo> data) async {
    localDataSource.storeTodos(data);
  }

  @override
  Future<void> removeLocalData() async {
    localDataSource.removeTodos();
  }
}
```

### RemoteOnlyStaleMateHandler

If you prefer not to store data locally but still want to use the loaders, extend the **RemoteOnlyStaleMateHandler** instead of the **StaleMateHandler**. In this case, you only need to override the emptyValue getter and the getRemoteData method.

Here's an example of a remote only ToDo handler implementation:

```dart
class TodosRemoteOnlyHandler extends RemoteOnlyStaleMateHandler<List<ToDo>> {
  final TodoRemoteDatasource remoteDataSource;

  TodosRemoteOnlyHandler({
    required this.remoteDataSource,
  });

  @override
  List<ToDo> get emptyValue => [];

  @override
  Future<List<ToDo>> getRemoteData() async {
    return remoteDataSource.getTodos();
  }
}
```

## Simple usage

### Managing a StaleMateLoader

The **StaleMateLoader** can be placed wherever it fits best within your application's architecture. It could be used as a singleton, injected via dependency injection, used within a state management system or placed within a repository where it interfaces with both local and remote data sources. This is entirely up to your preference and the specific needs of your application.

For the purpose of this example, we'll keep things simple by placing the loader directly within a StatefulWidget. This example makes use of the Todos handler that we created above.

Creating the loader is very simple, in its simplest case, you would only need to provide the StaleMateHandler instance.

```dart
// Widget part
// ...
class _TodosStatefulState extends State<TodosStateful> {
    final StaleMateLoader<String, TodosHandler> todosLoader = StaleMateLoader(
        // The handler is required and dictates where to
        // store and retrieve data from
        handler: TodosHandler(
          localDataSource: TodoLocalDatasource(),
          remoteDataSource: TodoRemoteDatasource(),
        ),
        // `updateOnInit` specifies whether the loader should
        // fetch data from the remote source at initialization or if
        // a refresh is needed. Defaults to true.
        updateOnInit: true,
        // `showLocalDataOnError` specifies whether the loader
        // should maintain local data in the data stream if an error
        // occurs while fetching remote data. Defaults to true.
        showLocalDataOnError: true,
       // `refreshConfig` allows the loader to automatically
        // refresh itself based on the refresh configuration.
        // If not provided, only manual refresh is supported.
        // Default is null.
        refreshConfig: null
        // `logLevel` configures the log level of individual loaders.
        // Defaults to StaleMateLogLevel.none.
        // Change to StaleMateLogLevel.debug to enable all logging.
        logLevel: StaleMateLogLevel.none,
    );
}
```

The loader needs to be initialized to start fetching data. It won't start automatically when you create it. This design caters to applications that have dependencies which must be met before data fetching can occur. The loader should also be closed when it's no longer needed, thus freeing up any resources.

In the context of a StatefulWidget, initialization and closure of the loader would occur in the initState and dispose methods respectively.

```dart
@override
void initState() {
    super.initState();
    // Initialize the loader.
    todosLoader.initialize();
}

@override
void dispose() {
    // Close the loader.
    todosLoader.close();
    super.dispose();
  }
```

### Logging

StaleMate loaders offer detailed logging that provides insight into their internal operations and aids in debugging.

You can configure logging in the following ways:

- Set the log level for individual loaders during creation.
- Adjust the log level on a per-loader basis using the setLogLevel method.
- Modify the default global log level with StaleMate.setLogLevel.

The last option changes the log level for all existing loaders and overrides any log levels set earlier. It also sets a new default for any loaders created in the future. However, if a specific log level is provided while creating a new loader, this will supersede the global default.

```dart
// Specify it when creating an instance of the loader
final loader = StaleMateLoader(
    //...
    logLevel: StaleMateLogLevel.debug
    //...
)

// Use the 'setLogLevel' method on the loaders
loader.setLogLevel(StaleMateLogLevel.info);

// Set it globally
StaleMate.setLogLevel(StaleMateLogLevel.error);
```

> The library is using the awesome [Logger](https://pub.dev/packages/logger/) library and their DevelopmentFilter behind the scenes. The filter makes sure nothing is logged in release builds.

### Displaying data

The most straightforward way to display data is to use the **StaleMateBuilder** widget:

```dart
@override
  Widget build(BuildContext context) {
    return StaleMateBuilder(
      loader: todosLoader,
      builder: (context, data) {
        return data.when(
            // When initialize has not been called
            // or we are waiting for the initial data
            loading: () => const Center(
                child: CircularProgressIndicator(),
            ),
            // When the loader has data to show
            data: (todos) => ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                    final todo = todos[index];
                    return CheckboxListTile(
                        title: Text(todo.title),
                        value: todo.completed,
                        onChanged: (value) {
                            // Update the todo.
                        },
                    );
                },
            ),
            // When the loader has an error
            // The loader will show data instead of error
            // depending on the showLocalDataOnError parameter
            error: (error) => Center(
                child: Text(error.toString()),
            ),
            // When the loader has data, but it is empty
            // This is the state after you call restart on the loader
            // It can also happen if you have no local data and the
            // remote data is empty.
            empty: () => const Center(
                child: Text('No todos found'),
            ),
        );
      },
    );
  }
```

Alternatively, you can achieve the same result by using a **StreamBuilder**:

```dart
@override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: todosLoader.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (snapshot.hasData && snapshot.data == _todosLoader.emptyValue) {
          return const Center(
            child: Text('No todos'),
          );
        }

        if (snapshot.hasData) {
          final todos = snapshot.data as List<ToDo>;
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return CheckboxListTile(
                title: Text(todo.title),
                value: todo.completed,
                onChanged: (value) {
                 /// Update the todo.
                },
              );
            },
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
```

### Manually refreshing the data

You can manually refresh data by calling the **refresh** method on the loader. This method returns a **StaleMateRefreshResult** object that indicates the success or failure of the refresh:

```dart
final result = await todosLoader.refresh();
if (result.isSuccess) {
    // You may want to get the updated data
    // Although the loader has already been updated with the data,
    // you can use this if you want to display something to the user after the refresh
    final updatedData = result.requireData;
} else if (result.isFailure) {
    // You can use the error here if you need to display different error messages to the user
    final error = result.requireError;
}
```

The StaleMateRefreshResult object also contains a convenient **on** method:

```dart
(await _todosLoader.refresh()).on(
    success: (data) {
        // do something on succesful refresh
    },
    failure: (error) {
        // do something on refresh failure
    },
);
```

### Reset

You can reset the loader to its initial empty state and remove any local data by calling the **reset** method:

```dart
_todosLoader.reset();
```

### Manually adding data

StaleMate offers the flexibility to manually add data to the loader. Once added, this data is stored locally (if the Handler stores data locally).

This feature is particularly beneficial in scenarios where you update or create new server side data, and these changes need to be reflected in the client-side loader without requiring a full refresh operation. Furthermore, it proves helpful to alter the data of local-only loaders.

Here's an example:

```dart
addTodo(ToDo todo) {
    // Make an API call or a server request to add a 'todo' item
    final addedTodo = await todosRepository.addTodo(todo);
    // Make a copy of the current todos to maintain immutability
    final updatedTodos = List<ToDo>.from(todosLoader.value);

    // Add the newly created 'todo' to the list of existing todos
    updatedTodos.add(addedTodo);
    // Add the todos to the loader
    // This will also store the new todos locally if the handler stores data locally
    todosLoader.addData(updatedTodos);
}
```

## Automatic Refreshing

StaleMate provides a feature for automatic data refreshing, which can be activated by configuring the refresh settings when creating the loader:

```dart
StaleMateLoader(
  // ...
  // other config
  // ...
  refreshConfig: StalePeriodRefreshConfig(
    stalePeriod: const Duration(
      hours: 1,
    ),
  ),
);
```

> Please note: The loader will not initiate a data fetch operation when the app is in the background. However, should the data become stale while the app is inactive, a fetch operation will be triggered upon the app's resumption.

StaleMate incorporates two built-in refresh strategies: **StalePeriodRefreshConfig** and **TimeOfDayRefreshConfig**.

### Stale Period

The 'Stale Period' strategy sets a predefined duration after which the data in your application is marked as "stale" or outdated. Once this period has been reached, StaleMate will automatically refresh the data, ensuring it remains current. This duration is fully customizable, permitting you to adjust the refresh frequency to best suit your application's requirements.

```dart
StalePeriodRefreshConfig(
    // Refresh every hour
    stalePeriod: const Duration(
        hours: 1,
    ),
),
```

### Time-of-Day Refresh

The Time-of-Day Refresh enables you to determine a specific time each day for your data to be refreshed. This strategy is particularly useful for applications handling data that updates daily, such as a news feed or daily promotions.

```dart
TimeOfDayRefreshConfig(
    // Refresh at 08:00 every day
    refreshTime: const TimeOfDay(
        hour: 8,
        minute: 0,
    ),
),
```

### Advanced usage

While StaleMate currently provides two automatic refetch strategies, you also have the freedom to create your own custom refresh strategy. This can be achieved by extending the StaleMateRefreshConfig class and overriding the getNextRefreshDelay method.

Below is an example of a custom StalePeriodRefreshConfig:

```dart
class StalePeriodRefreshConfig extends StaleMateRefreshConfig {
  /// The duration after which data is considered stale
  final Duration stalePeriod;

  StalePeriodRefreshConfig({required this.stalePeriod});

  @override
  Duration getNextRefreshDelay(DateTime lastRefreshTime) {
    return stalePeriod - DateTime.now().difference(lastRefreshTime);
  }
}
```

## Paginating data

StaleMate facilitates effortless data pagination through the use of its loaders. This feature is particularly beneficial when dealing with large datasets that can't (or shouldn't) be loaded all at once due to memory and performance considerations.

For implementing pagination, you need to:

- Use the **StaleMatePaginatedHandlerMixin** with your **StaleMateHandler**
- Use a **StaleMatePaginatedLoader** instead of **StaleMateLoader**
- Provide **StaleMatePaginationConfig** to the **StaleMatePaginatedLoader**

### Using the StaleMatePaginatedHandlerMixin

The usage of **StaleMatePaginatedHandlerMixin** is similar to regular handlers, the only exception being the need to override **getRemotePaginatedData** instead of **getRemoteData**. This overridden method receives the necessary information to fetch the next page of data.

Here is an example impelementation of paginating ToDos:

```dart
class PaginatedTodosHandler extends StaleMateHandler<List<ToDo>> with StaleMatePaginatedHandlerMixin<ToDo> {
  final TodoRemoteDatasource remoteDataSource;
  final TodoLocalDatasource localDataSource;

  TodosLoader({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // ...
  // Same process for local data
  // ...

  /// Instead of getRemoteData, you now override getRemotePaginatedData
  @override
  Future<List<ToDo>> getRemotePaginatedData( Map<String, dynamic> paginationParams) async {
    // If the pagination config on the loader is StaleMatePagePagination, the
    // pagination params could be retrieved like this
    final page = paginationParams['page'] as int;
    final pageSize = paginationParams['pageSize'] as int;
    return remoteDataSource.getTodos(page: page, pageSize: pageSize);
  }
}
```

### Using the StaleMatePaginatedLoader

The paginated loader can be used in a similar way to the standard **StaleMateLoader**. The key distinction is the capability to call **fetchMore** on the paginated loader, which retrieves the next page of data. When fetchMore is invoked (like when calling refresh), you receive a **StaleMateFetchMoreResult** object. This object indicates the fetch more call's status, any fetched data, any errors (if occurred), and if there's more data to be fetched.

> Note: Calling refresh on a paginated loader resets the pagination and only fetches the first page again.

```dart
final todosPaginatedLoader = StaleMatePaginatedLoader(
  handler: PaginatedTodosHandler(
    remoteDataSource: //...
    localDataSource: //..
  ),
  paginationConfig: StaleMatePagePagination(
    pageSize: 10,
    zeroBasedIndexing: false,
  )
)

// Call fetch more on the loader to fetch more
final fetchMoreResult = await todosPaginatedLoader.fetchMore();

if (fetchMoreResult.hasData) {
     // The new data that you just fetched from the server
    final newData = fetchMoreResult.requireNewData;
    // The new data merged with the data that you already had
    final mergedData = fetchMoreResult.require
}

// You can manually decide which states to handle to update the UI
if (fetchMoreResult.isDone) {
    // No more items to fetch, change app state to stop fetching more
}
else if (fetchMoreResult.moreDataAvailable) {
    // Fetch was successful and the server has more data waiting for you
}
else if (fetchMoreResult.isFailure) {
    // The error that occurred while fetching more data
    final error = fetchMoreResult.requireError
}
else if (fetchMoreResult.isAlreadyFetching) {
    // Fetch more was called while fetch more was in progress
    // The loader just ignores it, you cannot do two simultaneous
    // fetch more requests
}

// There is also a utility function to handle success and failure
fetchMoreResult.on(
    success: (mergedData, newData, isDone) {
        if (isDone) {
            // 'Fetched more data successfully, received ${newData.length} items. The total amount of items is now ${mergedData.length}. There is no more data to fetch',
        } else {
            // 'Fetched more data successfully, received ${newData.length} items. The total amount of items is now ${mergedData.length}',
        }
    },
    failure: (error) {
        //  'Failed to fetch more data with error: $error',
    },
);
```

### StaleMatePagePagination

The **StaleMatePagePagination** configuration enables page-based pagination in the paginated loader. Here's an example of its usage:

```dart
// Pass this configuration to your paginated loader
StaleMatePagePagination(
    // Specify the number of items to fetch per page
    pageSize: 10,
    // Indicates whether pages start counting from zero or one.
    // true: First page is page number 0
    // false (default): First page is page number 1
    zeroBasedIndexing: false,
)
```

### StaleMateOffsetLimitPagination

The **StaleMateOffsetLimitPagination** configuration enables simple offset/limit-based pagination in the loader. Here's an example of its usage:

```dart
// Pass this configuration to your paginated loader
StaleMateOffsetLimitPagination(
    // Define the number of items returned by each request
    limit: 10,
)
```

> Note: Some APIs use skip/limit or similar parameters for pagination. In such cases, you can still use the **OffsetLimit** pagination and adjust your API call parameters in the overwritten getRemotePaginatedData method in your loader.

### StaleMateCursorPagination

The **StaleMateCursorPagination** configuration enables cursor-based pagination in the loader. Here's an example of its usage:

```dart
// Pass this configuration to your paginated loader
// Be sure to add the correct type so that the getCursor callback
// can provide an item of the appropriate type
StaleMateCursorPagination<ToDo>(
    // Specify the number of items returned per request
    limit: 10,
    // Define how to retrieve the cursor for each item
    // This is often the item's ID, but it can also be a timestamp
    // For the first request, the cursor is null and the
    // getCursor method is not called
    getCursor: (ToDo lastItem) => lastItem.id,
)
```

### Advanced pagination

For custom pagination needs, the **StaleMatePaginationConfig** can be extended. The **getQueryParams** method needs to be implemented and optionally, you can also override the **onReceivedData** method to create your own data merging function or to define when the loader has finished fetching data.

> If the **onReceivedData** is not overridden and the **canFetchMore** parameter set to false when it's appropriate, the **isDone** functionality of the **StaleMateFetchMoreResult** will not work.

Here's an example of how **StaleMateCursorPagination** is implemented:

```dart
class StaleMateCursorPagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per page
  final int limit;

  /// The function to retrieve the cursor for the next page
  /// The cursor is a string that can be used to fetch the next page of data,
  /// it is usually an id or a timestamp
  final String Function(T lastItem) getCursor;

  StaleMateCursorPagination({
    required this.limit,
    required this.getCursor,
  });

  @override
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem) {
    return {
      // Retrieve the cursor for the next page
      // This needs to be implemented by the user since
      // the cursor is usually an id or a timestamp, depending on the data
      'cursor': lastItem != null ? getCursor(lastItem) : null,
      'limit': limit,
    };
  }

  @override
  List<T> onReceivedData(List<T> newData, List<T> oldData) {
    // If the number of items received is less than the limit,
    // there are no more items to fetch.
    canFetchMore = newData.length == limit;

    // The default implementation simply returns a combination of old and new data
    // i.e., [...oldData, ...newData]
    return super.onReceivedData(newData, oldData);

    // Instead of returning the default implementation, you could implement your own merge
    // function here
  }
}
```

## StaleMate registry

The StaleMate library includes a registry for managing all loader instances. This registry offers global bulk operations and enables you to retrieve loader instances from anywhere within your application.

### How does it work?

Loaders automatically register and deregister themselves with the registry upon creation and disposal. This means there's no need for manual management.

### What can you do with it?

With the StaleMate registry, you can:

- Access the count of registered loaders.
- Retrieve all registered loaders.
- Refresh all loaders.
- Reset all loaders.
- Retrieve, refresh, and reset loaders with a specific **StaleMateHandler** type.
- Check if a loader with a **StaleMateHandler** of a specific type exists

### When to use the StaleMate Registry?

While direct use of the registry isn't always necessary, it can be quite useful depending on your application's structure. For instance, if you need to reset all loaders when a user logs out, refresh all loaders simultaneously, or fetch a loader of a certain type from a different part of your application.

> Note: If you maintain direct control of your loader instances and perform operations on them directly, you may not need to use the registry.

Here's an example demonstrating interactions with the StaleMate registry:

```dart
logoutUser() async {
    // do other logout logic

    // Reset all StaleMate loaders so a new user has no "hanging data"
    await StaleMate.resetAllLoaders();
}

refreshAllTodoLoaders() async {
    final List<StaleMateRefreshResult> refreshResults = await StaleMate.refreshLoaders<List<ToDo>, TodosHandler>();
}
```

# Final thoughts

We hope that this documentation helps you understand how to use the StaleMate library in your Flutter applications. The aim of this library is to simplify and optimize your data management and refresh strategies.

If you encounter any problems or have suggestions for future features, please [create an issue](https://github.com/karlasgeir/stalemate/issues) in our GitHub repository. We appreciate your feedback and will do our best to improve StaleMate based on your needs and experiences.

Remember, StaleMate is designed to be flexible and adaptable to your needs, so we encourage you to experiment and find the configurations and strategies that work best in your application's unique context.
