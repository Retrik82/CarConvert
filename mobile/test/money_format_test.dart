import 'package:carconvert/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormat.usd', () {
    test('formats with two decimal places', () {
      expect(MoneyFormat.usd(0.1), '\$0.10');
      expect(MoneyFormat.usd(10), '\$10.00');
      expect(MoneyFormat.usd(99.999), '\$100.00');
    });
  });

  group('MoneyFormat.pricePerGeneration', () {
    test('formats sub-dollar amounts in cents', () {
      expect(MoneyFormat.pricePerGeneration(0.10), '10¢ за генерацию');
      expect(MoneyFormat.pricePerGeneration(0.05), '5¢ за генерацию');
    });

    test('formats dollar amounts', () {
      expect(MoneyFormat.pricePerGeneration(1.0), '\$1.00 за генерацию');
      expect(MoneyFormat.pricePerGeneration(2.5), '\$2.50 за генерацию');
    });
  });
}
