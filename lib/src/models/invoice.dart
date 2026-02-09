class Invoice {
  final String id;
  final String? orderId;
  final String? orderDescription;
  final double priceAmount;
  final String priceCurrency;
  final String payCurrency;
  final String status;
  final DateTime createdAt;
  final DateTime expiredAt;
  final String? address;
  final double amountExpected;
  final String successUrl;
  final String cancelUrl;
  final String? projectName;
  final bool isDonation;

  Invoice({
    required this.id,
    this.orderId,
    this.orderDescription,
    required this.priceAmount,
    required this.priceCurrency,
    required this.payCurrency,
    required this.status,
    required this.createdAt,
    required this.expiredAt,
    this.address,
    required this.amountExpected,
    required this.successUrl,
    required this.cancelUrl,
    this.projectName,
    required this.isDonation,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      orderId: json['orderId'],
      orderDescription: json['orderDescription'],
      priceAmount: (json['priceAmount'] as num).toDouble(),
      priceCurrency: json['priceCurrency'],
      payCurrency: json['payCurrency'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      expiredAt: DateTime.parse(json['expiredAt']),
      address: json['address'],
      amountExpected: (json['amountExpected'] as num).toDouble(),
      successUrl: json['successUrl'],
      cancelUrl: json['cancelUrl'],
      projectName: json['projectName'],
      isDonation: json['isDonation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderDescription': orderDescription,
      'priceAmount': priceAmount,
      'priceCurrency': priceCurrency,
      'payCurrency': payCurrency,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiredAt': expiredAt.toIso8601String(),
      'address': address,
      'amountExpected': amountExpected,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
      'projectName': projectName,
      'isDonation': isDonation,
    };
  }
}
