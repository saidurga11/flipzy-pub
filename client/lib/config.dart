class Config {
  static const String apiEndpoint = String.fromEnvironment(
    'API_ENDPOINT',
    defaultValue: 'http://localhost:8080',
  );
}
