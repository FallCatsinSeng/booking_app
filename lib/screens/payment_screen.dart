import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the Midtrans Snap payment page. The backend webhook is the source of
/// truth for payment status; this screen just hosts the hosted payment UI.
class PaymentScreen extends StatefulWidget {
  final String redirectUrl;
  const PaymentScreen({super.key, required this.redirectUrl});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _launchUrl();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ))
        ..loadRequest(Uri.parse(widget.redirectUrl));
    }
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.redirectUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka halaman pembayaran')),
        );
      }
    }
    setState(() => _loading = false);
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
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.open_in_new, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Halaman pembayaran telah dibuka di tab/jendela baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan selesaikan pembayaran Anda di sana. Jika sudah selesai, klik ikon Centang (Selesai) di pojok kanan atas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _launchUrl,
                      icon: const Icon(Icons.payment),
                      label: const Text('Buka Ulang Halaman Pembayaran'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(children: [
              if (_controller != null) WebViewWidget(controller: _controller!),
              if (_loading) const LinearProgressIndicator(),
            ]),
    );
  }
}
