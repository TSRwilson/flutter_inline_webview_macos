import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inline_webview_macos/flutter_inline_webview_macos.dart';
import 'package:flutter_inline_webview_macos/flutter_inline_webview_macos/flutter_inline_webview_macos_controller.dart';
import 'package:flutter_inline_webview_macos/flutter_inline_webview_macos/types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hide = true;

  InlineWebViewMacOsController? _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _hide
            ? InlineWebViewMacOs(
                key: widget.key,
                width: double.infinity,
                height: double.infinity,
                onLoadStop: (controller, url) {
                  log("onLoadStop $url");
                  _controller!
                      .runJavascript(script: "TriggerPosApp('macos1.1')");
                },
                onReceivedData: (controller, message) {
                  log("onReceivedData $message");
                },
                onLoadError: (controller, url, code, message) {
                  log("onLoadError $message");
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  log("onLoadHttpError $description");
                },
                onWebViewCreated: (controller) {
                  _controller = controller;
                  _controller!.channelName(channelName: "menumizPosChannel");
                  _controller!.loadUrl(
                      urlRequest: URLRequest(
                          url: Uri.parse(
                              "https://app.menumiz.com/Apps/Device/macos.1.1")));
                },
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
