# VirexPayment Flutter SDK

[![pub package](https://img.shields.io/pub/v/virex_payment.svg)](https://pub.dev/packages/virex_payment)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)

A powerful, native Flutter SDK for integrating **VirexPayment** into your mobile applications. Provide a premium, high-performance crypto checkout experience with support for multiple cryptocurrencies, native UI, and automatic theme adaptation.

![Virex Payment SDK Modal Preview](screenshots/preview.png)

---

## 🚀 Features

- **✅ Native Payment UI**: No WebViews. A fully native, smooth, and secure payment modal.
- **🔄 Dynamic Currency Switching**: Users can switch between dozens of supported cryptocurrencies (BTC, ETH, USDT, SOL, etc.) directly within the modal.
- **🌓 Auto-Theming**: Automatically adapts to your app's Light or Dark mode.
- **⏱️ Real-time Polling**: Automatic payment status tracking with live updates.
- **📥 Typed Results**: Get precise payment outcomes (Success, Cancelled, Error) using `Future` returns.
- **📱 QR Code Generation**: Instant local QR code generation for easy mobile-to-mobile payments.
- **📋 Clipboard Integration**: One-tap copying for wallet addresses and amounts.

---

## Example App

A complete, working example app is included in the `example` directory. It demonstrates:
- How to initialize `VirexClient` and handle errors.
- Implementing an invoice creation flow.
- Awaiting and handling the `VirexPaymentStatus` from the modal.

To run it:
```bash
cd example
flutter run
```

---

## 📦 Installation

Add `virex_payment` to your `pubspec.yaml` using the Git repository URL:

```yaml
dependencies:
  virex_payment:
    git:
      url: https://github.com/VirexPayment/virex_flutter_sdk.git
      ref: main
```

Or run:
```bash
flutter pub add 'virex_payment:{"git":{"url":"https://github.com/VirexPayment/virex_flutter_sdk.git"}}'
```

---

## 🛠️ Quick Start

### 1. Initialize the Client

Initialize the `VirexClient` with your API Key.

```dart
import 'package:virex_payment/virex_payment.dart';

final client = VirexClient(
  apiKey: 'YOUR_API_KEY_HERE',
);
```

### 2. Create an Invoice & Show Modal

You can create an invoice and show the native payment modal directly using `VirexPaymentModal.show()`.

```dart
Future<void> handlePayment(BuildContext context) async {
  // 1. Prepare Invoice Request
  final request = CreateInvoiceRequest(
    priceAmount: 100.0,
    priceCurrency: 'USD',
    payCurrency: 'USDT', // Initial selected currency
    orderId: 'INV-12345',
    orderDescription: 'Premium Subscription',
  );

  try {
    // 2. Create Invoice
    final response = await client.createInvoice(request);

    // 3. Show Native Modal and Wait for Result
    final result = await VirexPaymentModal.show(
      context,
      invoiceId: response.id,
      client: client,
    );

    // 4. Handle results based on VirexPaymentStatus
    if (result == VirexPaymentStatus.success) {
      // Payment Completed Successfully!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success!')),
      );
    } else if (result == VirexPaymentStatus.cancelled) {
      // User closed the modal before paying
      print("Payment Cancelled");
    }
  } catch (e) {
    print("Error: $e");
  }
}
```

---

## 🎨 Advanced Usage

### 🌑 Theming

The SDK is built to be "Zero Configuration". It uses your app's `Theme.of(context)` to automatically match your design system:

- **Colors**: Uses `scaffoldBackgroundColor`, `primaryColor`, `cardColor`, and `textTheme`.
- **Modes**: Switches automatically between Dark and Light mode based on your `MaterialApp` settings.

### 📊 Payment Statuses

The `show` method returns a `VirexPaymentStatus` enum:

| Status | Description |
|---|---|
| `VirexPaymentStatus.success` | Payment was detected and confirmed by the network. |
| `VirexPaymentStatus.cancelled` | User manually closed the payment sheet. |
| `VirexPaymentStatus.error` | A critical error occurred (e.g., invoice expired). |

---

## 📄 License

This SDK is released under the [MIT License](LICENSE).
