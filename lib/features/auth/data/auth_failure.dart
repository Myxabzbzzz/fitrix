import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthFailureKind { invalidCode, rateLimited, network, invalidEmail, unknown }

/// A sign-in error turned into something the user can act on.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);

  final AuthFailureKind kind;
  final String message;

  static const invalidCode = AuthFailure(
    AuthFailureKind.invalidCode,
    'That code is wrong or has expired. Check the latest email or send a new code.',
  );
  static const rateLimited = AuthFailure(
    AuthFailureKind.rateLimited,
    'Too many attempts. Please wait a minute and try again.',
  );
  static const network = AuthFailure(
    AuthFailureKind.network,
    'No connection. Check your internet and try again.',
  );
  static const invalidEmail = AuthFailure(
    AuthFailureKind.invalidEmail,
    'Enter a valid email address.',
  );
  static const unknown = AuthFailure(
    AuthFailureKind.unknown,
    'Something went wrong. Please try again.',
  );

  /// Maps errors from Supabase (or the network) to a failure. [verifying]
  /// is true for code checks, where the server answers a wrong code and an
  /// expired one the same way.
  static AuthFailure from(Object error, {bool verifying = false}) {
    if (error is AuthFailure) return error;
    if (error is TimeoutException) return network;
    if (error is AuthRetryableFetchException) {
      // No HTTP status: the request never got an answer.
      final status = int.tryParse(error.statusCode ?? '');
      return status == null || status >= 500 ? network : unknown;
    }
    if (error is AuthException) {
      final code = error.code ?? '';
      final status = error.statusCode ?? '';
      if (code.startsWith('over_') || status == '429') return rateLimited;
      if (code == 'otp_expired' ||
          (verifying && (status == '403' || status == '401'))) {
        return invalidCode;
      }
      if (code == 'email_address_invalid' ||
          code == 'validation_failed' ||
          error.message.toLowerCase().contains('invalid format')) {
        return verifying ? invalidCode : invalidEmail;
      }
      if (status.isEmpty || status.startsWith('5')) return network;
      return unknown;
    }
    // dart:io SocketException / http ClientException on web: offline.
    final type = error.runtimeType.toString();
    if (type.contains('SocketException') || type.contains('ClientException')) {
      return network;
    }
    return unknown;
  }

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Loose check before asking the server: something@something.tld
bool looksLikeEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
