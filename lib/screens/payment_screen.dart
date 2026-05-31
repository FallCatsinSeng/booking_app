import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens the Midtrans Snap payment page. The backend webhook is the source of
/// truth for payment status; this screen just hosts the hosted payment UI.
class PaymentScreen extends StatefulWidget {
  final String redirectUrl;
  const PaymentScreen({super.key, required this.redirectUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        actions: [
          IconButton(
            tooltip: 'Selesai',
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const LinearProgressIndicator(),
      ]),
    );
  }
}
