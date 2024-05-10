import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wfveflutterexample/application/app_theme/color_scheme.dart';


class WebView extends StatefulWidget {
  const WebView({super.key});

  @override
  WebViewState createState() =>  WebViewState();
}

class WebViewState extends State<WebView> {

 late InAppWebViewController _webViewController;
  Uri? url;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(children: <Widget>[
              const Row(
                children: [
                  BackButton(color: ColorManager.white,),
                  const Text(
                    '3D Object',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ],
              ),

              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: progress < 1.0
                      ? LinearProgressIndicator(value: progress, color: ColorManager.secondary,)
                      : Container()),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration:
                  BoxDecoration(border: Border.all(color: ColorManager.primary)),
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: Uri.tryParse("https://dev-app.dropslab.com//#/threed?urn=dXJuOmFkc2sub2JqZWN0czpvcy5vYmplY3Q6NzM2YzJjNGQtOWNiNy00M2IyLWExYTItNDM3YmRhMWE0OWM1eGpoNGUvTG93cG9seV90cmVlX3NhbXBsZS5vYmo&token=t4pvLXdHAn7_Dlf-OvOsErCpv5FfXLcp32i8M00FYX46YLom_jALHOMlimKab6oKI2hjCbxxoJzoy1QFU2htHcAedwrq-9D4MRpTBTZnGvFXaKhfZufrn07lG75E7AGfsgCcIHPJ8IKzXrgYy3CFyXG7PYWweSVMPDt_nyy_G4on92ki80VIbFHY2Kmvn88fmSShYKBk2T38wJCMBmXUGOAsOfzUihuqlflaUVXPw6HwYy80vjpMeAqDDPSJRzIImKPXEMQR0j7bwgbl6CMaWMV3c2N_NahIQsDSjS1Ns02scSo6sen3QNqER-sdoUPFRc97EdqxNi66JhrI7_p7D2IvCK2sIWd9cor-w5X2v0l0CKn7w_k75xuJwdC-kaFvBkHWT4gecbiGH-C-Q7k5FUlJ8KZcQaTWM_rUhQojTDRv1PPddr4tXxyXNrEu6b4IDc8U-wdG1DHJGZ-ku4WnjCj4FicfTxxaZm63a_4pdhAfKhJp6DJFcEf5LFYqOhhHqWLcs0OekX_9twM0KsylyBepZDS9agtkviGZC76v-HAOKpZ8saiQp3nydn3_jHHhbrVqyb5oi9Zk0L1-Ms1d8-z4i1qbN0zN6bgHFbGx16Kor5ZVfxkgJcy-jrzL1p1U")),
                    initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(),
                      android: AndroidInAppWebViewOptions(),
                      ios: IOSInAppWebViewOptions()
                    ),
                    onWebViewCreated: (InAppWebViewController controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (InAppWebViewController controller, Uri? url) {
                      setState(() {
                        this.url = url;
                      });
                    },
                    onLoadStop: (InAppWebViewController controller, Uri? url) async {
                      setState(() {
                        this.url = url;
                      });
                    },

                    onProgressChanged: (InAppWebViewController controller, int progress) {
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                  ),
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: <Widget>[
                  Semantics(
                    label: 'hf_no_number:|hf_commands:go back|hf_commands:back|',
                    button: true,
                    onTap: () {_webViewController.goBack();},
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {_webViewController.goBack();},
                    ),
                  ),
                  Semantics(
                    label: 'hf_no_number:|hf_commands:go forward|hf_commands:forward|',
                    button: true,
                    onTap: () {_webViewController.goForward();},
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {_webViewController.goForward();},
                    ),
                  ),
                  Semantics(
                    label: 'hf_no_number:|hf_commands:reload|hf_commands:refresh|',
                    button: true,
                    onTap: () {_webViewController.reload();},
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {_webViewController.reload();},
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      );

  }
}