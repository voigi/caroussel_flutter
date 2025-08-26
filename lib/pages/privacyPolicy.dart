import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String htmlContent = '';

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final content = await rootBundle.loadString('assets/privacy.html');
    setState(() {
      htmlContent = content;
    });
  }

  Future<NavigationDecision> _handleNavigationRequest(NavigationRequest request) async {
    final Uri uri = Uri.parse(request.url);

    if (uri.scheme == 'mailto') {
      final String mail =  // mail extrait du .env
          dotenv.env['mail'] ?? '';

      final Uri mailtoUri = Uri(
        scheme: 'mailto',
        path: mail,
        queryParameters: {
          'subject': "Question concernant l'application Mon Carrousel",
          'body': "Bonjour, j'ai une question au sujet de l'application Mon Carrousel :",
        },
      );

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        return NavigationDecision.prevent;
      }
    }
    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: htmlContent.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (BuildContext context) {
                final controller = WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..setNavigationDelegate(
                    NavigationDelegate(
                      onNavigationRequest: _handleNavigationRequest,
                    ),
                  )
                  ..loadRequest(
                    Uri.dataFromString(
                      htmlContent,
                      mimeType: 'text/html',
                      encoding: const Utf8Codec(),
                    ),
                  );
                return WebViewWidget(controller: controller);
              },
            ),
    );
  }
}
