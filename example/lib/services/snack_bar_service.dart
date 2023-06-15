import 'package:flutter/material.dart';

/// Just a simple service to simplify showing snack bars.
class SnackBarService {
  final ScaffoldMessengerState _scaffoldMessengerState;

  SnackBarService._(BuildContext context)
      : _scaffoldMessengerState = ScaffoldMessenger.of(context);

  factory SnackBarService.of(BuildContext context) {
    return SnackBarService._(context);
  }

  void show(String message) {
    _scaffoldMessengerState.showSnackBar(
      SnackBar(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        content: Text(message),
      ),
    );
  }
}
