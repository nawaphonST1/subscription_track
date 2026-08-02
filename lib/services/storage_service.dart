import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/utils/logger.dart';

class StorageService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    logger.i('StorageService initialized');
  }

  Either<Failure, T?> get<T>(String key) {
    try {
      final value = _prefs.get(key);
      if (value == null) return right(null);
      
      if (T == String) return right(value as T?);
      if (T == int) return right(value as T?);
      if (T == bool) return right(value as T?);
      if (T == double) return right(value as T?);
      if (T == List<String>) return right(value as T?);
      
      // For complex objects, assume JSON string
      if (value is String) {
        return right(jsonDecode(value) as T?);
      }
      
      return right(value as T?);
    } catch (e) {
      logger.e('Storage get error: $e');
      return left(Failure.cacheError(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> save(String key, dynamic value) async {
    try {
      bool success;
      if (value is String) {
        success = await _prefs.setString(key, value);
      } else if (value is int) {
        success = await _prefs.setInt(key, value);
      } else if (value is bool) {
        success = await _prefs.setBool(key, value);
      } else if (value is double) {
        success = await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        success = await _prefs.setStringList(key, value);
      } else {
        success = await _prefs.setString(key, jsonEncode(value));
      }
      
      if (success) return right(unit);
      return left(const Failure.cacheError('Failed to save'));
    } catch (e) {
      logger.e('Storage save error: $e');
      return left(Failure.cacheError(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> delete(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) return right(unit);
      return left(const Failure.cacheError('Failed to delete'));
    } catch (e) {
      logger.e('Storage delete error: $e');
      return left(Failure.cacheError(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> clear() async {
    try {
      final success = await _prefs.clear();
      if (success) return right(unit);
      return left(const Failure.cacheError('Failed to clear'));
    } catch (e) {
      logger.e('Storage clear error: $e');
      return left(Failure.cacheError(e.toString()));
    }
  }
}
