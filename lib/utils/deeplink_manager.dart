import 'dart:async';
import 'dart:developer';
import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/helper/widgets.dart';
import 'package:ebroker/data/repositories/property_repository.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/extensions/lib/custom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeepLinkManager {
  static const MethodChannel _channel =
      MethodChannel('app.channel.shared.data');
  static const EventChannel _eventChannel =
      EventChannel('app.channel.shared.data/link');

  static bool _isInitialLinkHandled = false;
  static StreamSubscription<dynamic>? _deepLinkSubscription;
  static String? _pendingInitialLink;
  static final Set<String> _processingLinks = <String>{};

  // Cache for property data to avoid duplicate API calls
  static final Map<String, dynamic> _propertyCache = <String, dynamic>{};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};

  static Future<void> initDeepLinks(BuildContext context) async {
    // Handle initial link
    await _handleInitialLink(context);

    // Listen for subsequent deep links
    _setupDeepLinkListener(context);
  }

  static Future<void> _handleInitialLink(BuildContext context) async {
    try {
      final initialLink = await _getInitialLink();

      if (initialLink != null && initialLink.isNotEmpty) {
        _pendingInitialLink = initialLink;

        // If navigator is ready, handle immediately
        if (Constant.navigatorKey.currentState != null &&
            !_isInitialLinkHandled) {
          _handlePendingInitialLink(context);
        } else {
          // Wait for navigator to be ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePendingInitialLink(context);
          });
        }
      }
    } on Exception catch (e) {
      _logError('Error getting initial deep link: $e');
    }
  }

  static void _handlePendingInitialLink(BuildContext context) {
    if (_pendingInitialLink != null && !_isInitialLinkHandled) {
      _isInitialLinkHandled = true;
      final uri = Uri.tryParse(_pendingInitialLink!);
      if (uri != null) {
        handleDeepLinks(context, uri, _extractSlugFromUri(uri));
      }
      _pendingInitialLink = null;
    }
  }

  static Future<String?> _getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on PlatformException catch (e) {
      _logError('Failed to get initial link: ${e.message}');
      return null;
    }
  }

  static void _setupDeepLinkListener(BuildContext context) {
    // Cancel any existing subscription
    _deepLinkSubscription?.cancel();

    // Listen to new links
    _deepLinkSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final link = event.toString().trim();
        if (link.isNotEmpty) {
          final uri = Uri.tryParse(link);
          if (uri != null) {
            handleDeepLinks(context, uri, _extractSlugFromUri(uri));
          }
        }
      },
      onError: (Object error) {
        _logError('Error receiving deep link: $error');
      },
    );
  }

  static String? _extractSlugFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return null;
  }

  static Future<void> handleDeepLinks(
    BuildContext context,
    Uri? uri,
    String? slug,
  ) async {
    if (uri == null || slug == null || slug.isEmpty) {
      return;
    }

    // Prevent duplicate processing
    final linkKey = uri.toString();
    if (_processingLinks.contains(linkKey)) {
      return;
    }
    _processingLinks.add(linkKey);

    try {
      if (uri.path.contains('/property-details/')) {
        await _handlePropertyDeepLink(context, slug);
      }
      // Add other deep link handlers here
    } finally {
      _processingLinks.remove(linkKey);
    }
  }

  static Future<void> _handlePropertyDeepLink(
      BuildContext context, String slug) async {
    try {
      // Check cache first
      dynamic propertyData = _getCachedProperty(slug);
      final showLoader = propertyData == null;

      if (showLoader) {
        unawaited(Widgets.showLoader(context));
      }

      // Fetch from API if not cached
      if (propertyData == null) {
        propertyData = await PropertyRepository().fetchBySlug(slug);
        _cacheProperty(slug, propertyData);
      }

      // Navigate using post frame callback to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (showLoader) {
          Widgets.hideLoader(context);
        }
        _navigateToPropertyDetails(propertyData);
      });
    } on Exception catch (e, st) {
      _logError('Error handling property deeplink: $e $st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Widgets.hideLoader(context);
        _showErrorSnackBar(context, 'Failed to load property details');
      });
    }
  }

  static dynamic _getCachedProperty(String slug) {
    if (_propertyCache.containsKey(slug) &&
        _cacheTimestamps.containsKey(slug)) {
      final timestamp = _cacheTimestamps[slug]!;
      if (DateTime.now().difference(timestamp) < _cacheTimeout) {
        return _propertyCache[slug];
      } else {
        // Cache expired, remove it
        _propertyCache.remove(slug);
        _cacheTimestamps.remove(slug);
      }
    }
    return null;
  }

  static void _cacheProperty(String slug, dynamic propertyData) {
    _propertyCache[slug] = propertyData;
    _cacheTimestamps[slug] = DateTime.now();
  }

  static void _navigateToPropertyDetails(dynamic propertyData) {
    final navigatorState = Constant.navigatorKey.currentState;
    final context = Constant.navigatorKey.currentContext;

    if (navigatorState != null && context != null) {
      // Check if we're already on the property details page with the same data
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute == Routes.propertyDetails) {
        // Pop current route and push new one to refresh
        navigatorState.pop();
      }

      navigatorState.pushNamed(
        Routes.propertyDetails,
        arguments: {
          'propertyData': propertyData,
        },
      );
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _logError(String message) {
    if (kDebugMode) {
      log(message, name: 'DeepLinkManager');
    }
  }

  static void clearCache() {
    _propertyCache.clear();
    _cacheTimestamps.clear();
  }

  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _processingLinks.clear();
    clearCache();
    _isInitialLinkHandled = false;
    _pendingInitialLink = null;
  }
}
