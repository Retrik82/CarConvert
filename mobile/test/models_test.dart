import 'package:carconvert/models/car.dart';
import 'package:carconvert/models/hint_response.dart';
import 'package:carconvert/models/process_job.dart';
import 'package:carconvert/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('fromJson parses admin and balance', () {
      final user = User.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'display_name': 'Alice',
        'balance': '12.50',
        'role': 'admin',
        'is_admin': true,
        'email_verified': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(user.isAdmin, isTrue);
      expect(user.balance, 12.5);
      expect(user.displayName, 'Alice');
    });

    test('copyWith updates display name', () {
      final user = User.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'display_name': 'Alice',
        'balance': 1,
        'role': 'user',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      final updated = user.copyWith(displayName: 'Bob');
      expect(updated.displayName, 'Bob');
      expect(updated.email, 'a@b.com');
    });
  });

  group('Car', () {
    test('lastRender returns most recent render', () {
      final car = Car(
        id: 'c1',
        name: 'Test',
        createdAt: DateTime(2024),
        renders: [
          RenderResult(
            id: 'r1',
            jobId: 'j1',
            createdAt: DateTime(2024, 1, 1),
          ),
          RenderResult(
            id: 'r2',
            jobId: 'j2',
            createdAt: DateTime(2024, 1, 2),
          ),
        ],
      );

      expect(car.lastRender?.id, 'r2');
    });
  });

  group('HintResponse', () {
    test('normalizes confidence above 1', () {
      final hint = HintResponse.fromJson({
        'hint': 'perfect_frame',
        'confidence': 95,
      });

      expect(hint.confidence, closeTo(0.95, 0.001));
      expect(hint.isPerfect, isTrue);
    });

    test('defaults missing fields', () {
      final hint = HintResponse.fromJson({});

      expect(hint.hint, 'align_car');
      expect(hint.overlay.arrow, 'none');
    });
  });

  group('PhotoResult', () {
    test('status helpers', () {
      expect(
        PhotoResult.fromJson({'job_id': 'j1', 'status': 'completed'}).isCompleted,
        isTrue,
      );
      expect(
        PhotoResult.fromJson({'job_id': 'j1', 'status': 'failed'}).isFailed,
        isTrue,
      );
      expect(
        PhotoResult.fromJson({'job_id': 'j1', 'status': 'processing'}).isPending,
        isTrue,
      );
    });
  });
}
