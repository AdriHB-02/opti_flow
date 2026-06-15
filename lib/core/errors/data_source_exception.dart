class DataSourceException implements Exception {
  final String message;
  final Object? originalError;

  const DataSourceException(this.message, {this.originalError});

  @override
  String toString() => message;
}
