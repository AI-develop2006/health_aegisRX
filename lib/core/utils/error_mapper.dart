import 'package:flutter/foundation.dart';

class ErrorMapper {
  /// Maps network, HTTP, or exception messages to human-readable text.
  /// If [kDebugMode] is true, returns the raw error details for debugging.
  static String map(dynamic error, {int? statusCode}) {
    final rawMessage = error.toString();
    
    if (kDebugMode) {
      // Complete details for development stage
      return 'Developer Error: $rawMessage${statusCode != null ? ' [HTTP $statusCode]' : ''}';
    }

    // Production-ready friendly messages
    if (statusCode == 401 || statusCode == 403) {
      return 'Unauthorized Access: Invalid session or credentials. Please log in again.';
    }
    if (statusCode == 404) {
      return 'Data Not Found: The requested medical record or node endpoint could not be retrieved.';
    }
    if (statusCode == 409) {
      return 'Conflict: This action has already been processed or single-use token was already burned.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server Maintenance: The backend node is experiencing server issues. Please retry in a few moments.';
    }

    final lower = rawMessage.toLowerCase();
    if (lower.contains('socketexception') || 
        lower.contains('connection failed') || 
        lower.contains('failed host lookup') || 
        lower.contains('network is unreachable')) {
      return 'No Internet Connection: Please check your network connectivity and try again.';
    }
    
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Connection Timeout: The AegisRx node took too long to respond. Please try again.';
    }

    if (lower.contains('empty') || lower.contains('not found') || lower.contains('no records')) {
      return 'No Data Found: No active logs or records match your search.';
    }

    return 'Unexpected Error: Something went wrong. Please check your inputs and try again later.';
  }
}
