import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../virex_payment.dart';

enum VirexPaymentStatus {
  success,
  cancelled,
  error,
}

class VirexPaymentModal extends StatefulWidget {
  final String invoiceId;
  final VirexClient client;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentError;
  final VoidCallback? onClosed;

  const VirexPaymentModal({
    super.key,
    required this.invoiceId,
    required this.client,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.onClosed,
  });

  static Future<VirexPaymentStatus?> show(
    BuildContext context, {
    required String invoiceId,
    required VirexClient client,
    VoidCallback? onPaymentSuccess,
    VoidCallback? onPaymentError,
    VoidCallback? onClosed,
  }) {
    return showModalBottomSheet<VirexPaymentStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirexPaymentModal(
        invoiceId: invoiceId,
        client: client,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentError: onPaymentError,
        onClosed: onClosed,
      ),
    );
  }

  @override
  State<VirexPaymentModal> createState() => _VirexPaymentModalState();
}

class _VirexPaymentModalState extends State<VirexPaymentModal> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  bool _paymentSuccess = false;

  // Mock Data matching the Web Frontend
  final List<Map<String, String>> _coins = [
    {'code': 'BTC', 'name': 'Bitcoin', 'network': 'Bitcoin'},
    {'code': 'ETH', 'name': 'Ethereum', 'network': 'ERC20'},
    {'code': 'LTC', 'name': 'Litecoin', 'network': 'Litecoin'},
    {'code': 'TRX', 'name': 'Tron', 'network': 'TRC20'},
    {'code': 'TON', 'name': 'Toncoin', 'network': 'TON'},
    {'code': 'BNB', 'name': 'BNB', 'network': 'BSC'},
    {'code': 'USDT_TRC20', 'name': 'Tether USD', 'network': 'TRC20'},
    {'code': 'USDT_ERC20', 'name': 'Tether USD', 'network': 'ERC20'},
    {'code': 'USDT_BEP20', 'name': 'Tether USD', 'network': 'BSC'},
    {'code': 'USDC_ERC20', 'name': 'USD Coin', 'network': 'ERC20'},
    {'code': 'USDC_TRC20', 'name': 'USD Coin', 'network': 'TRC20'},
    {'code': 'BUSD_BEP20', 'name': 'BUSD', 'network': 'BSC'},
    {'code': 'DOGE', 'name': 'Dogecoin', 'network': 'Dogecoin'},
    {'code': 'SOL', 'name': 'Solana', 'network': 'Solana'},
    {'code': 'XRP', 'name': 'XRP', 'network': 'Ripple'},
    {'code': 'ADA', 'name': 'Cardano', 'network': 'Cardano'},
    {'code': 'MATIC', 'name': 'Polygon', 'network': 'Polygon'},
    {'code': 'DOT', 'name': 'Polkadot', 'network': 'Polkadot'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _fetchInvoice(isPolling: true);
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _fetchInvoice({bool isPolling = false}) async {
    try {
      final invoice = await widget.client.getInvoice(widget.invoiceId);

      if (mounted) {
        // Only update state if something changed or it's the first load
        if (_invoice?.status != invoice.status || _invoice == null) {
          setState(() {
            _invoice = invoice;
            if (!isPolling) {
              _isLoading = false;
              final now = DateTime.now();
              if (invoice.expiredAt.isAfter(now)) {
                _timeLeft = invoice.expiredAt.difference(now);
                if (_countdownTimer == null || !_countdownTimer!.isActive) {
                  _startCountdown();
                }
              } else {
                _timeLeft = Duration.zero;
              }
            }
          });
        }

        if (invoice.status == 'Confirmed' ||
            invoice.status == 'Paid' ||
            invoice.status == 'Completed') {
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          setState(() {
            _paymentSuccess = true;
          });
          widget.onPaymentSuccess?.call();

          // Show success message for 3 seconds then close
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context, VirexPaymentStatus.success);
            }
          });
        }
      }
    } catch (e) {
      if (!isPolling && mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        widget.onPaymentError?.call();
        // Optional: Auto-close on critical error?
        // For now keep open to show error, but if we wanted to close:
        // Navigator.pop(context, VirexPaymentStatus.error);
      }
    }
  }

  Future<void> _changeCurrency(String currencyCode) async {
    if (_invoice == null) return;
    if (_invoice!.payCurrency == currencyCode) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedInvoice =
          await widget.client.changeCurrency(_invoice!.id, currencyCode);
      setState(() {
        _invoice = updatedInvoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to change currency: $e';
        _isLoading = false;
      });
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _error = null);
      });
    }
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select Cryptocurrency',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: _coins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final coin = _coins[index];
                      final isSelected = _invoice?.payCurrency == coin['code'];

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _changeCurrency(coin['code']!);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor.withValues(alpha: 0.1)
                                : theme.cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Icon Placeholder
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      theme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  coin['code']!.substring(0, 1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coin['name']!,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      coin['network']!,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: theme.primaryColor),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_outline,
                          color: theme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Secure Payment',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onClosed?.call();
                    Navigator.pop(context, VirexPaymentStatus.cancelled);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: $_error',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ))
                    : _invoice == null
                        ? const Center(child: Text('Invoice not found'))
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _paymentSuccess
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 48),
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle_outline,
                                            size: 80,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Payment Successful!',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Redirecting back to app...',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: theme.hintColor),
                                        ),
                                        const SizedBox(height: 48),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Currency Dropdown Trigger
                                        InkWell(
                                          onTap: _showCurrencySelector,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              border: Border.all(
                                                  color: theme.dividerColor),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Pay with ${_invoice!.payCurrency}',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 16),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Amount
                                        Column(
                                          children: [
                                            Text(
                                              'Total Amount',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: theme.hintColor),
                                            ),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => _copyToClipboard(
                                                  _invoice!.amountExpected
                                                      .toString(),
                                                  'Amount'),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${_invoice!.amountExpected} ${_invoice!.payCurrency.split('_')[0]}',
                                                    style: theme
                                                        .textTheme.headlineLarge
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.copy,
                                                      size: 18,
                                                      color: theme.hintColor),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 32),

                                        // QR Code with Border
                                        if (_invoice!.address != null)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .white, // QR Code always on white
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                              border: Border.all(
                                                  color: Colors.grey[200]!),
                                            ),
                                            child: QrImageView(
                                              data: _invoice!.address!,
                                              version: QrVersions.auto,
                                              size: 200.0,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Colors.black,
                                              ),
                                              dataModuleStyle:
                                                  const QrDataModuleStyle(
                                                dataModuleShape:
                                                    QrDataModuleShape.square,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),

                                        const SizedBox(height: 32),

                                        // Address Box
                                        if (_invoice!.address != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: theme.dividerColor),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Send to ${_invoice!.payCurrency} Address',
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                                color: theme
                                                                    .hintColor),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _invoice!.address!,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontFamily:
                                                                'monospace',
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.copy_rounded,
                                                      color:
                                                          theme.primaryColor),
                                                  onPressed: () =>
                                                      _copyToClipboard(
                                                          _invoice!.address!,
                                                          'Address'),
                                                ),
                                              ],
                                            ),
                                          ),

                                        const SizedBox(height: 32),

                                        // Timer & Status
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons.timer_outlined,
                                                      size: 16,
                                                      color: Colors.red),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _formatDuration(_timeLeft),
                                                    style: const TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.amber
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                children: [
                                                  SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.amber),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Awaiting Payment',
                                                    style: TextStyle(
                                                        color: Colors.amber,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),
                                        Text(
                                          'Please send the exact amount to the address above.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: theme.hintColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
          ),

          // Safety Padding for Bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
