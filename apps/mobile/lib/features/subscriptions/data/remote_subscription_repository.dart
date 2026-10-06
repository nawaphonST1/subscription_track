import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_repository.dart';

class RemoteSubscriptionRepository implements SubscriptionRepository {
  RemoteSubscriptionRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client is AuthenticatedHttpClient
            ? client
            : AuthenticatedHttpClient(
                readToken: RemoteAuthRepository.readStoredAuthToken,
                inner: client,
              ),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final uri = Uri.parse('$_baseUrl/subscriptions');
    final response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final dynamic rawList =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (rawList is List) {
        return rawList
            .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return const [];
    }
    throw Exception(
        'Failed to load subscriptions (HTTP ${response.statusCode})');
  }

  @override
  Future<Subscription> getSubscriptionById(String id) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/$id');
    final response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final dynamic data =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (data is Map<String, dynamic>) {
        return Subscription.fromJson(data);
      }
    }
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(id);
    }
    throw Exception(
        'Failed to get subscription (HTTP ${response.statusCode})');
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    final uri = Uri.parse('$_baseUrl/subscriptions');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(subscription.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception(
        'Failed to add subscription (HTTP ${response.statusCode})');
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/${subscription.id}');
    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(subscription.toJson()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(subscription.id);
    }
    throw Exception(
        'Failed to update subscription (HTTP ${response.statusCode})');
  }

  @override
  Future<void> deleteSubscription(String id, {String? pin}) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/$id');
    final headers = <String, String>{
      if (pin != null) 'x-security-pin': pin,
    };
    final response = await _client.delete(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(id);
    }
    throw Exception(
        'Failed to delete subscription (HTTP ${response.statusCode})');
  }

  @override
  Future<void> toggleSelection(String id) async {
    // Selection state is client-side only
  }
}
