import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoHelper {
  static const String _hexChars = '0123456789abcdef';

  // Calculate deterministic key shift based on NPI digits
  static int _getShift(String doctorId) {
    int sum = 0;
    for (int i = 0; i < doctorId.length; i++) {
      int? val = int.tryParse(doctorId[i]);
      if (val != null) sum += val;
    }
    if (sum == 0) sum = doctorId.hashCode.abs();
    return (sum % 14) + 1; // shift range 1-14
  }

  // SHA-256 Hashing of payload
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Asymmetric Private Key Shift Simulation
  static String sign(String hash, String doctorId) {
    final shift = _getShift(doctorId);
    return _shiftHex(hash, shift);
  }

  // Asymmetric Public Key Shift Simulation (reversing shifts)
  static String decrypt(String signature, String doctorId) {
    final shift = _getShift(doctorId);
    return _shiftHex(signature, -shift);
  }

  static String _shiftHex(String hex, int shift) {
    final sb = StringBuffer();
    for (int i = 0; i < hex.length; i++) {
      final char = hex[i].toLowerCase();
      final idx = _hexChars.indexOf(char);
      if (idx != -1) {
        int newIdx = (idx + shift) % 16;
        if (newIdx < 0) newIdx += 16;
        sb.write(_hexChars[newIdx]);
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }
}
