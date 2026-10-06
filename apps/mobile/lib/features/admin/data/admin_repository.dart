import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/admin/domain/admin_package.dart';
import 'package:subscription_track/features/admin/domain/admin_stats.dart';
import 'package:subscription_track/features/admin/domain/admin_user.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

import 'package:subscription_track/features/admin/domain/admin_user_detail.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminStats>> getStats();
  Future<Either<Failure, List<AdminUser>>> getUsers();
  Future<Either<Failure, AdminUserDetail>> getUserDetail(String id);
  Future<Either<Failure, void>> updateUser(
    String id, {
    String? name,
    String? role,
    double? monthlyIncome,
  });
  Future<Either<Failure, void>> updateSubscription(
    String subId, {
    String? name,
    String? category,
    double? price,
    String? billingCycle,
    String? status,
    DateTime? nextRenewalDate,
    String? notes,
    String? brandColor,
  });
  Future<Either<Failure, void>> deleteSubscription(String subId);
  Future<Either<Failure, void>> deleteUser(String id);
  Future<Either<Failure, List<AdminPackage>>> getPackages();
  Future<Either<Failure, AdminPackage>> createPackage({
    required String name,
    required String category,
    required double defaultPrice,
    String billingCycle = 'MONTHLY',
    String brandColor = '#3B82F6',
    String? iconUrl,
    String? description,
  });
  Future<Either<Failure, AdminPackage>> updatePackage(
    String id, {
    String? name,
    String? category,
    double? defaultPrice,
    String? billingCycle,
    String? brandColor,
    String? iconUrl,
    String? description,
  });
  Future<Either<Failure, AdminPackage>> togglePackageActive(
    String id,
    bool isActive,
  );
  Future<Either<Failure, void>> deletePackage(
    String id, {
    bool permanent = false,
  });
}



class RemoteAdminRepository implements AdminRepository {
  RemoteAdminRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ??
            AuthenticatedHttpClient(
              readToken: RemoteAuthRepository.readStoredAuthToken,
            ),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<Either<Failure, AdminStats>> getStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      return unwrapEnvelope<AdminStats>(
        response,
        (data) => AdminStats.fromJson(data),
      );
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {'Content-Type': 'application/json'},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (decoded is Map ? decoded['data'] : decoded) as List?;
        if (list == null) return right([]);
        final users = list
            .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
            .toList();
        return right(users);
      }
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, AdminUserDetail>> getUserDetail(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/admin/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        return right(AdminUserDetail.fromJson(data as Map<String, dynamic>));
      }
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(
    String id, {
    String? name,
    String? role,
    double? monthlyIncome,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/admin/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (role != null) 'role': role,
          if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(null);
      }
      final decoded = jsonDecode(response.body);
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, void>> updateSubscription(
    String subId, {
    String? name,
    String? category,
    double? price,
    String? billingCycle,
    String? status,
    DateTime? nextRenewalDate,
    String? notes,
    String? brandColor,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/admin/subscriptions/$subId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (price != null) 'price': price,
          if (billingCycle != null) 'billing_cycle': billingCycle,
          if (status != null) 'status': status,
          if (nextRenewalDate != null)
            'next_renewal_date': nextRenewalDate.toIso8601String(),
          if (notes != null) 'notes': notes,
          if (brandColor != null) 'brand_color': brandColor,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(null);
      }
      final decoded = jsonDecode(response.body);
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, void>> deleteSubscription(String subId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/admin/subscriptions/$subId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(null);
      }
      final decoded = jsonDecode(response.body);
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }


  @override
  Future<Either<Failure, void>> deleteUser(String id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/admin/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(null);
      }
      final decoded = jsonDecode(response.body);
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, List<AdminPackage>>> getPackages() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/admin/packages'),
        headers: {'Content-Type': 'application/json'},
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = (decoded is Map ? decoded['data'] : decoded) as List?;
        if (list == null) return right([]);
        final packages = list
            .map((item) => AdminPackage.fromJson(item as Map<String, dynamic>))
            .toList();
        return right(packages);
      }
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, AdminPackage>> createPackage({
    required String name,
    required String category,
    required double defaultPrice,
    String billingCycle = 'MONTHLY',
    String brandColor = '#3B82F6',
    String? iconUrl,
    String? description,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/admin/packages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'category': category,
          'default_price': defaultPrice,
          'billing_cycle': billingCycle,
          'brand_color': brandColor,
          if (iconUrl != null) 'icon_url': iconUrl,
          if (description != null) 'description': description,
        }),
      );

      return unwrapEnvelope<AdminPackage>(
        response,
        (data) => AdminPackage.fromJson(data),
      );
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, AdminPackage>> updatePackage(
    String id, {
    String? name,
    String? category,
    double? defaultPrice,
    String? billingCycle,
    String? brandColor,
    String? iconUrl,
    String? description,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/admin/packages/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (defaultPrice != null) 'default_price': defaultPrice,
          if (billingCycle != null) 'billing_cycle': billingCycle,
          if (brandColor != null) 'brand_color': brandColor,
          if (iconUrl != null) 'icon_url': iconUrl,
          if (description != null) 'description': description,
        }),
      );

      return unwrapEnvelope<AdminPackage>(
        response,
        (data) => AdminPackage.fromJson(data),
      );
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, AdminPackage>> togglePackageActive(
    String id,
    bool isActive,
  ) async {
    try {
      final endpoint = isActive ? 'enable' : 'disable';
      final response = await _client.patch(
        Uri.parse('$_baseUrl/admin/packages/$id/$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      return unwrapEnvelope<AdminPackage>(
        response,
        (data) => AdminPackage.fromJson(data),
      );
    } catch (_) {
      return left(const Failure.networkError());
    }
  }

  @override
  Future<Either<Failure, void>> deletePackage(
    String id, {
    bool permanent = false,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/admin/packages/$id?permanent=$permanent'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return right(null);
      }
      final decoded = jsonDecode(response.body);
      return left(failureFromErrorBody(
        decoded is Map<String, dynamic> ? decoded : {},
        response.statusCode,
      ));
    } catch (_) {
      return left(const Failure.networkError());
    }
  }
}
