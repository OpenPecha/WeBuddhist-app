import 'dart:convert';

import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal, unsigned JWT (`header.payload.signature`) whose payload
/// carries the given [exp] (seconds since epoch). Signature is irrelevant to
/// the client-side expiry helpers, which only decode the payload.
String _jwtWithExp(int? exp) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = seg({'alg': 'RS256', 'typ': 'JWT'});
  final payload = seg({if (exp != null) 'exp': exp, 'sub': 'user-123'});
  return '$header.$payload.signature';
}

int _nowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

void main() {
  final auth = AuthService.instance;

  group('isJwtExpired', () {
    test('returns false for a token well within its lifetime', () {
      final jwt = _jwtWithExp(_nowSecs() + 3600);
      expect(auth.isJwtExpired(jwt), isFalse);
    });

    test('returns true for an already-expired token', () {
      final jwt = _jwtWithExp(_nowSecs() - 10);
      expect(auth.isJwtExpired(jwt), isTrue);
    });

    test('treats a token inside the buffer window as expired', () {
      // 60s left, default buffer is 120s ⇒ considered expired.
      final jwt = _jwtWithExp(_nowSecs() + 60);
      expect(auth.isJwtExpired(jwt), isTrue);
    });

    test('respects a custom buffer', () {
      final jwt = _jwtWithExp(_nowSecs() + 60);
      expect(auth.isJwtExpired(jwt, bufferSeconds: 30), isFalse);
    });

    test('treats malformed tokens as expired', () {
      expect(auth.isJwtExpired('not-a-jwt'), isTrue);
      expect(auth.isJwtExpired(_jwtWithExp(null)), isTrue);
    });
  });

  group('jwtRemainingTtlSeconds', () {
    test('returns the remaining lifetime for a live token', () {
      final jwt = _jwtWithExp(_nowSecs() + 300);
      final ttl = auth.jwtRemainingTtlSeconds(jwt);
      expect(ttl, inInclusiveRange(295, 300));
    });

    test('returns 0 for an expired token', () {
      final jwt = _jwtWithExp(_nowSecs() - 10);
      expect(auth.jwtRemainingTtlSeconds(jwt), 0);
    });

    test('returns 0 for a malformed token', () {
      expect(auth.jwtRemainingTtlSeconds('garbage'), 0);
      expect(auth.jwtRemainingTtlSeconds(_jwtWithExp(null)), 0);
    });
  });
}
