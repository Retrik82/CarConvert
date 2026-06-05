import 'package:carconvert/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('returns error for empty email', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });

    test('returns error for invalid format', () {
      expect(Validators.email('not-an-email'), 'Invalid email format');
      expect(Validators.email('a@b'), 'Invalid email format');
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for empty password', () {
      expect(Validators.password(''), 'Password is required');
    });

    test('returns error for short password', () {
      expect(Validators.password('1234567'), 'Password must be at least 8 characters');
    });

    test('returns null for valid password', () {
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('returns error when passwords differ', () {
      expect(Validators.confirmPassword('abc', 'xyz'), 'Passwords do not match');
    });

    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('secret', 'secret'), isNull);
    });
  });

  group('Validators.required', () {
    test('returns error for empty value', () {
      expect(Validators.required('', 'Name'), 'Name is required');
      expect(Validators.required('   ', 'Name'), 'Name is required');
    });

    test('returns null for non-empty value', () {
      expect(Validators.required('John', 'Name'), isNull);
    });
  });

  group('Validators.price', () {
    test('returns error for invalid price', () {
      expect(Validators.price(''), 'Price is required');
      expect(Validators.price('abc'), 'Price must be greater than 0');
      expect(Validators.price('0'), 'Price must be greater than 0');
      expect(Validators.price('1.234'), 'Maximum 2 decimal places');
    });

    test('returns null for valid price', () {
      expect(Validators.price('0.10'), isNull);
      expect(Validators.price('1,50'), isNull);
      expect(Validators.price('10'), isNull);
    });
  });
}
