**StaleMate** is a data synchronization library for Flutter applications. Its primary purpose is to simplify the process of keeping remote and local data in sync while offering a flexible and agnostic approach to data storage and retrieval. With StaleMate, you are free to utilize any data storage or fetching method that suits your needs, be it Hive, Isar, secure storage, shared preferences, or any HTTP client for remote data retrieval.

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

## Create a loader

To create a loader using StaleMate, you need to extend the StaleMateLoader class and implement the getLocalData, getRemoteData, storeLocalData, and removeLocalData methods. However, it's not necessary to implement all these methods. If you only have local data, or if you don't want to store the remote data locally, you can omit the relevant method(s).

Here's an example of a simple ToDo loader implementation:

```dart
class TodosLoader extends StaleMateLoader<List<ToDo>> {
  // This is the remote datasource that will be used to fetch data from the
  // remote server.
  final TodoRemoteDatasource remoteDataSource;
  // This is the local datasource that will be used to store data locally.
  final TodoLocalDatasource localDataSource;

  TodosLoader({
    required this.remoteDataSource,
    required this.localDataSource,
  }) : super(
          // You need to provide an empty value for the loader. This value will be
          // added to the data stream when the loader is reset.
          emptyValue: [],
          // Update on init indicates if you want to retrieve data from remote when the loader is initialized.
          // If there is local data, it will be retrieved as soon as initialize() is called.
          // updateOnInit: true (default), the loader will subsequently retrive the remote data.
          // updateOnInit: false
          //    Have local data: the loader will not retrieve the remote data until refresh is called on the loader
          //    No local data: the loader will retrieve the remote data when initialized.
          updateOnInit: true,
          // Show local data on error indicates if you want to show local data when an error occurs.
          // showLocalDataOnError: true (default), local data shown on error, if available.
          // showLocalDataOnError: false, error shown on error, even if local data is available.
          // If you want to show the user an error on refresh, the refresh call returns a
          // [StaleMateRefreshResult] object which incidates if the refresh was successful or not.
          showLocalDataOnError: true,
        );

  @override
  Future<List<ToDo>> getLocalData() async {
    // This is where you should retrieve the local data.
    // If you don't want to cache data locally, you con't need to override this method.
    return localDataSource.getTodos();
  }

  @override
  Future<List<ToDo>> getRemoteData() async {
    // This is where you should retrieve the remote data.
    // If you only have local data and don't want to retrieve remote data, you don't need to override this method.
    return remoteDataSource.getTodos();
  }

  @override
  Future<void> storeLocalData(List<ToDo> data) async {
    // This is where you should store the local data.
    // If you don't want to cache data locally, you con't need to override this method.
    localDataSource.storeTodos(data);
  }

  @override
  Future<void> removeLocalData() async {
    // This is where you should remove the local data.
    // If you don't want to cache data locally, you con't need to override this method.
    localDataSource.removeTodos();
  }
}
```

## Simple usage

### Managing a StaleMateLoader

The _StaleMateLoader_ can be placed wherever it fits best within your application's architecture. It could be used as a singleton, injected via dependency injection, or placed within a repository where it interfaces with both local and remote data sources. This is entirely up to your preference and the specific needs of your application.

For the purpose of this example, we'll keep things simple by placing the loader directly within a StatefulWidget.

```dart
class _TodosStatefulState extends State<TodosStateful> {
    final TodosLoader _todosLoader = TodosLoader(
        localDataSource: TodoLocalDatasource(),
        remoteDataSource: TodoRemoteDatasource(),
    );
}
```

Remember to initialize and close the loader in the initState and dispose methods respectively:

```dart
@override
void initState() {
    super.initState();
    // Initialize the loader.
    _todosLoader.initialize();
}

@override
void dispose() {
    // Close the loader.
    _todosLoader.close();
    super.dispose();
  }
```

### Displaying data

The most straightforward way to display data is to use the **StaleMateBuilder** widget:

```dart
@override
  Widget build(BuildContext context) {
    return StaleMateBuilder(
      loader: _todosLoader,
      builder: (context, data) {
        // when is a utility class that you can use to
        // render different widgets based on the state of the data
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
      stream: _todosLoader.stream,
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

You can manually refresh data by calling the refresh method on the loader. The refresh call returns a **StaleMateRefreshResult** object, indicating whether the refresh was successful:

```dart
final result = await _todosLoader.refresh();
if (result.isSuccess) {
    // Get the updated data if needed
    // The loader has already been updated with the data
    // This is just if you want to show something to the user after
    // refresh
    final updatedData = result.requireData;
} else if (result.isFailure) {
     // You can use the error here if you need to show different messages
     // to the user depending on the error
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

You can reset the loader to its initial empty state and remove any local data by calling the reset method:

```dart
_todosLoader.reset();
```

### Manually adding data

StaleMate provides the flexibility to manually add data to the loader. This data is subsequently stored locally. This feature proves useful when you've made changes on the server and want to reflect those changes in the loader without executing a full refresh operation.

Here's an illustration:

```dart
addTodo(ToDo todo) {
    // Update the todos on the server and receive the created todo
    final addedTodo = await todosRepository.addTodo(todo);
    // Copy the current todos to ensure immutability
    final updatedTodos = List<ToDo>.from(_todosLoader.value);
    // Add the new todo
    updatedTodos.add(addedTodo);
    // Add the todos to the loader
    // This will also store the new todos locally
    _todosLoader.addData(updatedTodos);
}
```

## Automatic Refreshing

StaleMate offers automatic refreshing, which can be enabled by providing refresh config to the loader:

```dart
TodosLoader({
    required this.repository,
  }) : super(
          emptyValue: [],
          updateOnInit: true,
          showLocalDataOnError: true,
          // The loader will update the data automatically
          // every hour
          refreshConfig: StalePeriodRefreshConfig(
            stalePeriod: const Duration(
              hours: 1,
            ),
          ),
        );
```

> Please note: The loader will not attempt to fetch data while the app is in the background. However, if the data becomes stale while the app is inactive, a new fetch will occur when the app is resumed.

StaleMate offers two built-in refresh strategies: the Stale Period and the Time-of-Day Refresh.

### Stale Period

The Stale Period is a predefined duration after which the data in your application is considered "stale" or outdated. When the data becomes stale, StaleMate will automatically refresh it, ensuring it remains up-to-date. You have full control over this duration, allowing you to tailor the refresh rate to the specific needs of your application.

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

Though StaleMate currently provides two automatic refetch strategies, you can create your own custom refresh strategy by extending the StaleMateRefreshConfig class and overriding the getNextRefreshDelay method.

Here's an example of how you might implement a custom StalePeriodRefreshConfig:

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

## StaleMate registry

The StaleMate library provides a registry to manage all loader instances. It gives you access to global bulk operations and the ability to retrieve loader instances from anywhere in your application.

### How does it work?

Loaders automatically register and deregister themselves with the registry when they are created and disposed. This means you do not need to worry about manual management

### What can you do with it?

With the StaleMate registry, you can perform the following operations:

- Access the count of registered loaders.
- Retrieve all registered loaders.
- Refresh all loaders.
- Reset all loaders.
- Retrieve loaders of a specific type.
- Refresh all loaders of a specific type.
- Reset all loaders of a specific type.
- Check if a loader of a specific type exists.
- Retrieve the first loader of a specific type.
- Refresh the first loader of a specific type.
- Reset the first loader of a specific type.

### When to use the StaleMate Registry?

While you don't need to use the registry directly in many cases, it can be extremely useful depending on the structure of your application. If you want to reset all loaders when a user logs out of the application, refresh all loaders at once, or retrieve a loader of a specific type from a different part of your application, the StaleMate registry provides you with these capabilities.

> Keep in mind that in many cases you maintain control of your loader instances and perform operations on their instances directly, you might not need to use the registry.

Here's an example of how you can interact with the StaleMate registry:

```dart
logoutUser() async {
    // do other logout logic

    // Reset all StaleMate loaders so a new user has no "hanging data"
    await StaleMate.resetAllLoaders();
}

refreshAllTodoLoaders() async {
    final List<StaleMateRefreshResult> refreshResults = await StaleMate.refreshLoaders<TodosLoader>();
}

List<ToDo> getTodosFromFirstTodoLoader() {
    return StaleMate.getFirstLoader<TodosLoader>?.value ?? [];
}
```

**Please remember to handle potential null values and exceptions when using the registry.**

# Final thoughts

We hope that this documentation helps you understand how to effectively use the StaleMate library in your Flutter applications. The aim of this library is to simplify and optimize your data management and refresh strategies.

If you encounter any problems or have suggestions for future features, please [create an issue](https://github.com/karlasgeir/stalemate/issues) in our GitHub repository. We appreciate your feedback and will do our best to improve StaleMate based on your needs and experiences.

Remember, StaleMate is designed to be flexible and adaptable to your needs, so we encourage you to experiment and find the configurations and strategies that work best for your the unique context of your application.
