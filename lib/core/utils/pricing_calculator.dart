enum DiscountType {
  fixed('Nominal (Rp)'),
  percentage('Persentase (%)');

  final String label;
  const DiscountType(this.label);
}

class OrderPricingResult {
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double grandTotal;

  const OrderPricingResult({
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.grandTotal,
  });

  double calculateChange(double paymentAmount) {
    if (paymentAmount < grandTotal) return 0.0;
    return (paymentAmount - grandTotal).roundToDouble();
  }

  bool isPaymentValid(double paymentAmount) {
    return paymentAmount >= grandTotal;
  }
}

class PricingCalculator {
  PricingCalculator._();

  static OrderPricingResult calculate({
    required double subtotal,
    DiscountType discountType = DiscountType.fixed,
    double discountValue = 0.0,
    double taxRate = 0.0, // in percent, e.g. 11 for 11%
  }) {
    final cleanSubtotal = subtotal.clamp(0.0, double.infinity).roundToDouble();

    // 1. Calculate discount
    double calculatedDiscount = 0.0;
    if (discountType == DiscountType.percentage) {
      final pct = discountValue.clamp(0.0, 100.0);
      calculatedDiscount = ((cleanSubtotal * pct) / 100.0).roundToDouble();
    } else {
      calculatedDiscount = discountValue.clamp(0.0, cleanSubtotal).roundToDouble();
    }
    calculatedDiscount = calculatedDiscount.clamp(0.0, cleanSubtotal);

    // 2. Calculate taxable amount
    final taxableAmount = (cleanSubtotal - calculatedDiscount).roundToDouble();

    // 3. Calculate tax
    double calculatedTax = 0.0;
    if (taxRate > 0) {
      calculatedTax = ((taxableAmount * taxRate) / 100.0).roundToDouble();
    }

    // 4. Grand Total
    final grandTotal = (taxableAmount + calculatedTax).roundToDouble();

    return OrderPricingResult(
      subtotal: cleanSubtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: calculatedDiscount,
      taxRate: taxRate,
      taxAmount: calculatedTax,
      grandTotal: grandTotal,
    );
  }
}
