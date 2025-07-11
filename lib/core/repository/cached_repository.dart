import 'dart:developer';
import '../cache/cache_service.dart';

/// Base repository class implementing stale-while-revalidate pattern
abstract class CachedRepository<T> {
  final CacheService _cacheService = CacheService.instance;

  /// Cache key for this repository
  String get cacheKey;

  /// TTL for cached data
  Duration get cacheTTL;

  /// Convert entity to JSON
  Map<String, dynamic> toJson(T entity);

  /// Create entity from JSON
  T fromJson(Map<String, dynamic> json);

  /// Fetch fresh data from remote source
  Future<T> fetchFromRemote();

  /// Get data with stale-while-revalidate pattern
  Future<T> getData({bool forceRefresh = false}) async {
    try {
      // If force refresh, skip cache
      if (forceRefresh) {
        log('🔄 Force refresh requested for $cacheKey');
        return await _fetchAndCache();
      }

      // Try to get cached data
      final cacheResult = await _cacheService.retrieve<T>(
        cacheKey,
        fromJson: fromJson,
        maxAge: cacheTTL,
      );

      if (cacheResult == null) {
        log('💾 No cached data for $cacheKey, fetching fresh');
        return await _fetchAndCache();
      }

      // If data is fresh, return it
      if (!cacheResult.isStale) {
        log('✨ Fresh cached data for $cacheKey');
        return cacheResult.data;
      }

      // Data is stale - return cached data and fetch fresh in background
      log('⏰ Stale cached data for $cacheKey, returning cached and refreshing');

      // Return cached data immediately
      final cachedData = cacheResult.data;

      // Fetch fresh data in background (don't await)
      _fetchAndCache()
          .then((_) {
            log('🔄 Background refresh completed for $cacheKey');
          })
          .catchError((error) {
            log('⚠️ Background refresh failed for $cacheKey: $error');
          });

      return cachedData;
    } catch (e) {
      log('❌ Error in getData for $cacheKey: $e');

      // Try to return any cached data as fallback
      final cacheResult = await _cacheService.retrieve<T>(
        cacheKey,
        fromJson: fromJson,
      );

      if (cacheResult != null) {
        log('🛡️ Returning stale cached data as fallback for $cacheKey');
        return cacheResult.data;
      }

      rethrow;
    }
  }

  /// Update data and cache
  Future<T> updateData(T data) async {
    try {
      // Store in cache immediately for optimistic updates
      await _cacheService.store(cacheKey, toJson(data), ttl: cacheTTL);

      // Update remote source
      await updateRemote(data);

      log('💾 Updated and cached data for $cacheKey');
      return data;
    } catch (e) {
      log('❌ Error updating data for $cacheKey: $e');
      rethrow;
    }
  }

  /// Update remote source (override in subclasses)
  Future<void> updateRemote(T data) async {
    // Default implementation does nothing
    // Override in subclasses to implement remote updates
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await _cacheService.remove(cacheKey);
    log('🗑️ Cleared cache for $cacheKey');
  }

  /// Fetch and cache data
  Future<T> _fetchAndCache() async {
    final freshData = await fetchFromRemote();
    await _cacheService.store(cacheKey, toJson(freshData), ttl: cacheTTL);
    return freshData;
  }
}

/// Repository for collections/lists
abstract class CachedListRepository<T> {
  final CacheService _cacheService = CacheService.instance;

  /// Cache key for this repository
  String get cacheKey;

  /// TTL for cached data
  Duration get cacheTTL;

  /// Convert entity to JSON
  Map<String, dynamic> toJson(T entity);

  /// Create entity from JSON
  T fromJson(Map<String, dynamic> json);

  /// Fetch fresh data from remote source
  Future<List<T>> fetchFromRemote();

  /// Get list data with caching
  Future<List<T>> getList({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        return await _fetchAndCacheList();
      }

      final cacheResult = await _cacheService.retrieve<List<dynamic>>(
        cacheKey,
        fromJson: (json) => json['items'] as List<dynamic>,
        maxAge: cacheTTL,
      );

      if (cacheResult == null) {
        return await _fetchAndCacheList();
      }

      final List<T> cachedList = (cacheResult.data)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      if (!cacheResult.isStale) {
        return cachedList;
      }

      // Return cached and refresh in background
      _fetchAndCacheList()
          .then((_) {
            log('🔄 Background list refresh completed for $cacheKey');
          })
          .catchError((error) {
            log('⚠️ Background list refresh failed for $cacheKey: $error');
          });

      return cachedList;
    } catch (e) {
      log('❌ Error in getList for $cacheKey: $e');
      rethrow;
    }
  }

  /// Update list and cache
  Future<List<T>> updateList(List<T> data) async {
    await _cacheService.store(cacheKey, {
      'items': data.map((item) => toJson(item)).toList(),
      'count': data.length,
    }, ttl: cacheTTL);

    await updateRemoteList(data);
    return data;
  }

  /// Update remote list (override in subclasses)
  Future<void> updateRemoteList(List<T> data) async {
    // Override in subclasses
  }

  /// Fetch and cache list
  Future<List<T>> _fetchAndCacheList() async {
    final freshData = await fetchFromRemote();
    await _cacheService.store(cacheKey, {
      'items': freshData.map((item) => toJson(item)).toList(),
      'count': freshData.length,
    }, ttl: cacheTTL);
    return freshData;
  }
}
