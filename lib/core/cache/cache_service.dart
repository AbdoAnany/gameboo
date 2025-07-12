import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Core caching service implementing stale-while-revalidate pattern
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._internal();

  CacheService._internal();

  SharedPreferences? _prefs;
  final Connectivity _connectivity = Connectivity();

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if device is online
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.any(
      (connectivity) => connectivity != ConnectivityResult.none,
    );
  }

  /// Store data with timestamp for freshness tracking
  Future<void> store<T>(String key, T data, {Duration? ttl}) async {
    await initialize();

    final cacheEntry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );

    final jsonData = cacheEntry.toJson();
    await _prefs!.setString(key, jsonData);

    log('✅ Cached data for cacheEntry: ${cacheEntry.toJson()}');
    log('✅ Cached data for jsonData: ${jsonData}');
    log('✅ Cached data for key: $key');
  }

  /// Retrieve data with freshness check
  Future<CacheResult<T>?> retrieve<T>(
    String key, {
    required T Function(Map<String, dynamic>) fromJson,
    Duration? maxAge,
  }) async {
    await initialize();

    final jsonData = _prefs!.getString(key);
    
    print("jsonData key: $key");
    print("jsonData retrieve: $jsonData");
    if (jsonData == null) {
      log('❌  No cached data for key: $key');
      return null;
    }

    try {
      final Map<String, dynamic> cacheMap = json.decode(jsonData);
      final cacheEntry = CacheEntry<T>.fromJson(cacheMap, fromJson);

      final isStale = cacheEntry.isStale(maxAge);

      log('📋 Retrieved cached data for key: $key (stale: $isStale)');

      return CacheResult<T>(
        data: cacheEntry.data,
        isStale: isStale,
        timestamp: cacheEntry.timestamp,
      );
    } catch (e) {
      log('⚠️ Error retrieving cached data for key: $key - $e');
      return null;
    }
  }

  /// Remove cached data
  Future<void> remove(String key) async {
    await initialize();
    await _prefs!.remove(key);
    log('🗑️ Removed cached data for key: $key');
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    await initialize();
    await _prefs!.clear();
    log('🧹 Cleared all cached data');
  }

  /// Get all cached keys
  Set<String> getAllKeys() {
    return _prefs?.getKeys() ?? <String>{};
  }

  /// Check if data exists in cache
  bool hasKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}

/// Cache entry wrapper with metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration? ttl;

  const CacheEntry({required this.data, required this.timestamp, this.ttl});

  /// Check if the cache entry is stale
  bool isStale(Duration? maxAge) {
    final age = maxAge ?? ttl;
    if (age == null) return false;

    return DateTime.now().difference(timestamp) > age;
  }

  /// Convert to JSON for storage
  String toJson() {
    return json.encode({
      'data': _serializeData(data),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
    });
  }

  /// Create from JSON
  factory CacheEntry.fromJson(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) fromJsonFunc,
  ) {
    return CacheEntry<T>(
      data: fromJsonFunc(map['data'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      ttl: map['ttl'] != null
          ? Duration(milliseconds: map['ttl'] as int)
          : null,
    );
  }

  /// Serialize data for JSON storage
  dynamic _serializeData(T data) {
    if (data is Map<String, dynamic>) return data;
    if (data is List) return data;
    if (data is String || data is num || data is bool) return data;

    // For custom objects, they should implement toJson()
    try {
      return (data as dynamic).toJson();
    } catch (e) {
      throw Exception(
        'Data type ${T.toString()} must implement toJson() method',
      );
    }
  }
}

/// Result wrapper for cached data retrieval
class CacheResult<T> {
  final T data;
  final bool isStale;
  final DateTime timestamp;

  const CacheResult({
    required this.data,
    required this.isStale,
    required this.timestamp,
  });

  /// Age of the cached data
  Duration get age => DateTime.now().difference(timestamp);
}

/// Cache configuration constants
class CacheConfig {
  static const Duration profileCacheTTL = Duration(minutes: 15);
  static const Duration characterCacheTTL = Duration(hours: 1);
  static const Duration charactersCacheTTL = Duration(hours: 1);
  static const Duration shopCacheTTL = Duration(minutes: 30);
  static const Duration progressionCacheTTL = Duration(minutes: 10);
  static const Duration gameDataCacheTTL = Duration(hours: 2);

  // Cache keys
  static const String profileKey = 'user_profile';
  static const String charactersKey = 'characters_data';
  static const String shopKey = 'shop_data';
  static const String progressionKey = 'progression_data';
  static const String gameStatsKey = 'game_stats';
  static const String achievementsKey = 'achievements_data';
  static const String settingsKey = 'app_settings';
}
