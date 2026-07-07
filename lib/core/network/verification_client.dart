import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Possible state phases of the verification operation
enum VerificationState {
  idle,
  submitting,
  verificationPending,
  completed,
  failed,
}

/// Custom domain exceptions for resilient error handling
class VerificationException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  VerificationException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'VerificationException: $message (Status: $statusCode)';
}

class ValidationException extends VerificationException {
  ValidationException(String message, {dynamic details})
      : super(message, statusCode: 422, details: details);
}

class NetworkTimeoutException extends VerificationException {
  NetworkTimeoutException(String message) : super(message, statusCode: 504);
}

class ClientVerificationException extends ChangeNotifier {
  final String gatewayUrl;
  final http.Client _client = http.Client();

  VerificationState _state = VerificationState.idle;
  String? _referenceToken;
  String? _errorMessage;

  ClientVerificationException({required this.gatewayUrl});

  // Getters
  VerificationState get state => _state;
  String? get referenceToken => _referenceToken;
  String? get errorMessage => _errorMessage;

  void _updateState(VerificationState newState, {String? error}) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Initiates verification with exponential backoff retry logic
  Future<String> initiateVerification(String payload) async {
    _updateState(VerificationState.submitting);

    try {
      final responseBody = await _postWithRetry(
        url: '$gatewayUrl/api/verify/initiate',
        body: {'payload': payload},
      );

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final token = data['reference_token'] as String?;
      if (token == null) {
        throw VerificationException('Missing reference token in server response');
      }

      _referenceToken = token;
      _updateState(VerificationState.verificationPending);
      return token;
    } catch (e) {
      _updateState(VerificationState.failed, error: e.toString());
      rethrow;
    }
  }

  /// Confirms verification step (OTP verification) with backoff retry logic
  Future<Map<String, dynamic>> confirmVerification(String code) async {
    if (_referenceToken == null) {
      throw VerificationException('No active verification session reference');
    }

    _updateState(VerificationState.submitting);

    try {
      final responseBody = await _postWithRetry(
        url: '$gatewayUrl/api/verify/confirm',
        body: {
          'reference_token': _referenceToken,
          'code': code,
        },
      );

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      _updateState(VerificationState.completed);
      return data;
    } catch (e) {
      _updateState(VerificationState.failed, error: e.toString());
      rethrow;
    }
  }

  /// Resets the client to the idle state
  void reset() {
    _referenceToken = null;
    _updateState(VerificationState.idle);
  }

  /// Sends a POST request with exponential backoff retry for transient network/server failures
  Future<String> _postWithRetry({
    required String url,
    required Map<String, dynamic> body,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      attempts++;
      try {
        debugPrint('[ResilientClient] POST $url - Attempt $attempts of $maxRetries');
        final response = await _client.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 5)); // 5-second connection/response timeout

        // Process HTTP Status Codes (Interceptors)
        if (response.statusCode == 200) {
          return response.body;
        } else if (response.statusCode == 422) {
          final decoded = jsonDecode(response.body);
          throw ValidationException(
            'Unprocessable Entity / Validation failure',
            details: decoded['detail'] ?? decoded,
          );
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw VerificationException(
            'Authentication / Authorization rejected',
            statusCode: response.statusCode,
          );
        } else if (response.statusCode >= 500) {
          // Internal server errors can be retried if under retry limits
          throw VerificationException(
            'Server returned internal error',
            statusCode: response.statusCode,
          );
        } else {
          throw VerificationException(
            'Request failed with status code: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      } on SocketException catch (e) {
        debugPrint('[ResilientClient] SocketException caught: $e');
        if (attempts >= maxRetries) {
          throw VerificationException('Network connection failed: check your internet connection or server.');
        }
      } on TimeoutException catch (e) {
        debugPrint('[ResilientClient] Request timeout: $e');
        if (attempts >= maxRetries) {
          throw NetworkTimeoutException('Gateway timeout: server took too long to respond.');
        }
      } on ValidationException {
        // Do not retry validation client errors (status 422)
        rethrow;
      } on VerificationException catch (e) {
        // Do not retry 401/403 client errors
        if (e.statusCode == 401 || e.statusCode == 403 || attempts >= maxRetries) {
          rethrow;
        }
      } catch (e) {
        debugPrint('[ResilientClient] Unexpected error: $e');
        if (attempts >= maxRetries) {
          throw VerificationException('Unexpected execution error: $e');
        }
      }

      // Exponential backoff sleep
      debugPrint('[ResilientClient] Retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
      delay = delay * 2; // double the delay time
    }
  }
}
