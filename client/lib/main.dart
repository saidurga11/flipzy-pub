import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

// Provider for backend health status
final backendHealthProvider = FutureProvider<bool>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('${Config.apiEndpoint}/health'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'ok';
    }
    return false;
  } catch (e) {
    return false;
  }
});

void main() {
  runApp(
    const ProviderScope(
      child: FlipzyApp(),
    ),
  );
}

class FlipzyApp extends StatelessWidget {
  const FlipzyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flipzy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthStatus = ref.watch(backendHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flipzy'),
        centerTitle: true,
      ),
      body: Center(
        child: healthStatus.when(
          data: (isConnected) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  size: 64,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  isConnected
                      ? 'Flipzy — Connected to backend'
                      : 'Disconnected',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'API Endpoint: ${Config.apiEndpoint}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(backendHealthProvider);
                  },
                  child: const Text('Retry Connection'),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Disconnected',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(backendHealthProvider);
                },
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
