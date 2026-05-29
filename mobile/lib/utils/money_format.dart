class MoneyFormat {
  static String usd(double amount) => '\$${amount.toStringAsFixed(2)}';

  static String pricePerGeneration(double amount) {
    if (amount < 1) {
      final cents = (amount * 100).round();
      return '$cents¢ за генерацию';
    }
    return '${usd(amount)} за генерацию';
  }
}
