import 'package:flutter/material.dart';

class GlobalErrorHandler {
  static void handleError(Object error, StackTrace? stackTrace) {
    debugPrint('Global Error Caught: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
    // In a real app, you might send this to Sentry/Crashlytics
  }

  static Widget errorBuilder(FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
