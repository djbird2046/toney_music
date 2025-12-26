import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// macOS security-scoped bookmark helper.
///
/// On other platforms all methods are no-ops.
class SecurityScopedBookmarks {
  SecurityScopedBookmarks._();

  static const _channelName = 'security_scoped_access';
  static const _channel = MethodChannel(_channelName);

  /// Cache of active access tokens per path to avoid duplicate starts.
  static final Map<String, String> _activeTokens = {};

  /// Create a bookmark for [path] on macOS. Returns base64 bookmark or null.
  static Future<String?> createBookmark(String path) async {
    if (!Platform.isMacOS) return null;
    try {
      return await _channel.invokeMethod<String>(
        'createBookmark',
        {'path': path},
      );
    } catch (error) {
      debugPrint('createBookmark failed for $path: $error');
      return null;
    }
  }

  /// Start a security-scoped access session for the given [path]/[bookmark].
  ///
  /// Returns a token string that should be passed to [stopAccess] when no
  /// longer needed. If already active, returns the existing token.
  static Future<String?> startAccess({
    required String path,
    String? bookmark,
  }) async {
    if (!Platform.isMacOS) return null;
    if (bookmark == null || bookmark.isEmpty) return null;
    final existing = _activeTokens[path];
    if (existing != null) return existing;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startAccess',
        {'bookmark': bookmark},
      );
      final token = result?['token'] as String?;
      if (token != null) {
        _activeTokens[path] = token;
      }
      return token;
    } catch (error) {
      debugPrint('startAccess failed for $path: $error');
      return null;
    }
  }

  /// Stop a previously started access session for [path].
  static Future<void> stopAccess(String path) async {
    if (!Platform.isMacOS) return;
    final token = _activeTokens.remove(path);
    if (token == null) return;
    try {
      await _channel.invokeMethod('stopAccess', {'token': token});
    } catch (error) {
      debugPrint('stopAccess failed for $path: $error');
    }
  }
}
