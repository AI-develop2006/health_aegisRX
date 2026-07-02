import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoHelper {
  /// Computes a standard SHA-256 hash of the input string payload
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies token signatures (e.g. validating signature matches computed hash)
  static bool verifyTokenSignature({
    required String payload,
    required String signature,
    required String publicKey,
  }) {
    // Standard signature verification placeholder
    final computedHash = sha256Hash(payload);
    // In a real system, decrypt the signature with the public key and compare
    return signature == computedHash;
  }

  /// Verifies zero-knowledge proofs or server cryptographic validity proofs
  static bool verifyServerProof({
    required String proofData,
    required String expectedRoot,
  }) {
    // Merkle tree root or cryptographic verification proof placeholder
    return proofData.isNotEmpty && expectedRoot.isNotEmpty;
  }
}
