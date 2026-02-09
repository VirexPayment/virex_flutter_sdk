import 'package:flutter/material.dart';
import 'package:virex_payment/virex_payment.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virex Payment Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Virex Payment SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Replace these with your actual API key and secret for testing
  final _client = VirexClient(
    apiKey: 'df5SFI7v.df5SFI7vNPkSKitkOm4rILuiD8BDBL9u5ENHvkWMbZQ',
    // baseUrl: 'http://localhost:5000', // Uncomment to test against local backend
  );

  String _result = 'Press the button to create an invoice';
  bool _isLoading = false;

  // Unused method removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Test Invoice Creation:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          setState(() {
                            _isLoading = true;
                            _result = 'Creating invoice...';
                          });

                          final request = CreateInvoiceRequest(
                            priceAmount: 10.0,
                            priceCurrency: 'USD',
                            payCurrency: 'USDT',
                            successUrl: 'https://example.com/success',
                            cancelUrl: 'https://example.com/cancel',
                            orderId:
                                'ORDER-${DateTime.now().millisecondsSinceEpoch}',
                            orderDescription: 'Test Order from Flutter SDK',
                          );

                          try {
                            final response = await _client.createInvoice(
                              request,
                            );

                            if (!mounted) return;

                            // Open Modal Directly
                            // ignore: use_build_context_synchronously
                            final result = await VirexPaymentModal.show(
                              context,
                              invoiceId: response.id,
                              client: _client,
                              // Callbacks are still supported, but now we can also await the result!
                            );

                            if (!mounted) return;

                            if (result == VirexPaymentStatus.success) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment Successful!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (result == VirexPaymentStatus.cancelled) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment Cancelled by User'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else if (result == VirexPaymentStatus.error) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment Error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }

                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _result = 'Invoice Created & Modal Opened';
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                                _result = 'Error: $e';
                              });
                            }
                          }
                        },
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Pay with Virex (Open Modal)'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
