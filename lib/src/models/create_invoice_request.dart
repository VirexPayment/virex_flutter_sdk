class CreateInvoiceRequest {
  final double priceAmount;
  final String priceCurrency;
  final String payCurrency;
  final String successUrl;
  final String cancelUrl;
  final String? orderId;
  final String? orderDescription;
  final String? apiKeyId;
  final bool isDonation;

  CreateInvoiceRequest({
    required this.priceAmount,
    required this.priceCurrency,
    required this.payCurrency,
    required this.successUrl,
    required this.cancelUrl,
    this.orderId,
    this.orderDescription,
    this.apiKeyId,
    this.isDonation = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'priceAmount':
          priceAmount
              .toString(), // Backend expects string for decimal safe binding sometimes, or double. DTO says string.
      'priceCurrency': priceCurrency,
      'payCurrency': payCurrency,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
      'orderId': orderId,
      'orderDescription': orderDescription,
      'apiKeyId': apiKeyId,
      'isDonation': isDonation,
    };
  }
}
