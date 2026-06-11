import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const String routeName = '/privacy-policy';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  Timer? loadingTimeout;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    // Set a timeout for loading
    loadingTimeout?.cancel();
    loadingTimeout = Timer(const Duration(seconds: 30), () {
      if (isLoading) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Page took too long to load. Please check your internet connection.';
        });
      }
    });

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            loadingTimeout?.cancel();
            setState(() {
              isLoading = false;
              hasError = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            loadingTimeout?.cancel();
            debugPrint('WebView error: ${error.description}');
            setState(() {
              isLoading = false;
              hasError = true;
              errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://webuddhist.com/privacy-policy'));
  }

  @override
  void dispose() {
    loadingTimeout?.cancel();
    super.dispose();
  }

  void _retry() {
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        title: Text(
          l10n.legal_privacy_policy,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (!hasError) WebViewWidget(controller: controller),
            if (hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load page',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage ?? 'Unable to load the privacy policy page.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            if (isLoading)
              Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
