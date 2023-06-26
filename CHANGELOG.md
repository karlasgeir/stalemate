## Version 0.0.1

Initial Version

Features:

- **StaleMateLoader:** Core loader for managing stale data and facilitating automatic refresh.
- **StaleMatePaginatedLoader:** A loader that supports paginating data from remote
- **StaleMateHandler:** The core interface for integrating with your data sources. By extending StaleMateHandler, you can easily manage fetching and storing data in both local and remote sources.
- **Automatic Refreshing:** Two built-in strategies for automatic data refreshing - stale period and time-of-day.
- **Custom Refresh Strategy:** Offers flexibility to define custom refresh strategies tailored to your application's specific needs.
- **StaleMateBuilder:** Stream-based builder for seamless UI updates based on the current data state.
- **StaleMateRegistry** Offers bulk operations on loaders to simplify common operations like clearing all loaders on logout
- **Example Application:** A simple example application to help you get started.
- **Documentation:** Documentation to guide you through the library's basic features and usage.
