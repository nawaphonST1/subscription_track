import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/notifications/data/remote_notification_repository.dart';
import 'package:subscription_track/features/notifications/domain/notification_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';

  group('RemoteNotificationRepository.getNotifications', () {
    test('maps backend fields (message/is_read/created_at/type) to AppNotification',
        () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {
              'unread_count': 1,
              'notifications': [
                {
                  'id': 'n1',
                  'title': 'Netflix จะต่ออายุเร็ว ๆ นี้',
                  'message': 'ยอดชำระ ฿419 จะถูกหักอัตโนมัติ',
                  'type': 'RENEWAL_ALERT',
                  'is_read': false,
                  'created_at': '2026-10-06T07:00:00.000Z',
                },
                {
                  'id': 'n2',
                  'title': 'รหัส PIN ถูกเปลี่ยน',
                  'message': 'มีการเปลี่ยนรหัส PIN ของคุณ',
                  'type': 'SECURITY_ALERT',
                  'is_read': true,
                  'created_at': '2026-10-05T07:00:00.000Z',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final feed = await repository.getNotifications();

      expect(feed.unreadCount, 1);
      expect(feed.items, hasLength(2));
      expect(feed.items[0].id, 'n1');
      expect(feed.items[0].body, 'ยอดชำระ ฿419 จะถูกหักอัตโนมัติ');
      expect(feed.items[0].type, 'upcoming_bill'); // RENEWAL_ALERT mapped
      expect(feed.items[0].isRead, isFalse);
      expect(feed.items[0].createdAt, isNotNull);
      expect(feed.items[0].scheduledAt, feed.items[0].createdAt);
      expect(feed.items[1].type, 'security_alert'); // SECURITY_ALERT mapped
      expect(feed.items[1].isRead, isTrue);
    });

    test('empty notifications list maps to an empty feed, not an error',
        () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'unread_count': 0, 'notifications': <Map>[]},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final feed = await repository.getNotifications();
      expect(feed.items, isEmpty);
      expect(feed.unreadCount, 0);
    });
  });

  group('RemoteNotificationRepository.markAsRead', () {
    test('PATCHes /notifications/:id/read', () async {
      http.Request? capturedRequest;
      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'statusCode': 200, 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );
      final repository = RemoteNotificationRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      await repository.markAsRead('n1');

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/notifications/n1/read');
      expect(capturedRequest!.headers['Authorization'], 'Bearer $testToken');
    });

    test('throws NotificationNotFoundException on HTTP 404', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 404,
            'message': 'Notification not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.markAsRead('nonexistent'),
        throwsA(isA<NotificationNotFoundException>()),
      );
    });
  });

  group('RemoteNotificationRepository.markAllAsRead', () {
    test('PATCHes /notifications/read-all', () async {
      http.Request? capturedRequest;
      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'statusCode': 200, 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      await repository.markAllAsRead();

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/notifications/read-all');
    });
  });

  group('RemoteNotificationRepository.dismiss', () {
    test('DELETEs /notifications/:id', () async {
      http.Request? capturedRequest;
      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'statusCode': 200, 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      await repository.dismiss('n1');

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/notifications/n1');
    });

    test('throws NotificationNotFoundException on HTTP 404', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'statusCode': 404}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.dismiss('nonexistent'),
        throwsA(isA<NotificationNotFoundException>()),
      );
    });
  });

  group('RemoteNotificationRepository.clearAll', () {
    test('DELETEs /notifications with no :id segment', () async {
      http.Request? capturedRequest;
      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'statusCode': 200, 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteNotificationRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      await repository.clearAll();

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/notifications');
    });
  });
}
