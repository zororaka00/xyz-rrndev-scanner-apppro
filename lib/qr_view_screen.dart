import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:getwidget/getwidget.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRViewScreen extends StatefulWidget {
  const QRViewScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewScreenState();
}

class _QRViewScreenState extends State<QRViewScreen> {
  TextEditingController _textResultController = TextEditingController();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void resetText() {
    setState(() {
      _textResultController.text = '';
      result = null;
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: result != null
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                  child: GFCard(
                      padding: const EdgeInsets.all(5.0),
                      content: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'QR Scan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                            SizedBox(height: 20.0),
                            GFTextFieldRounded(
                              controller: _textResultController,
                              editingbordercolor: GFColors.PRIMARY,
                              idlebordercolor: GFColors.PRIMARY,
                              borderwidth: 2,
                              cornerradius: 15,
                              hintText: '',
                              readOnly: true,
                            ),
                            SizedBox(height: 5.0),
                            GFButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: _textResultController.text));
                                MotionToast.success(
                                        title: Text("Success"),
                                        description:
                                            Text("File saved successfully"),
                                        position: MotionToastPosition.top)
                                    .show(context);
                              },
                              text: 'Copy Text',
                              shape: GFButtonShape.pills,
                              color: Colors.orange,
                            ),
                            SizedBox(height: 5.0),
                            GFButton(
                              onPressed: () {
                                final Uri url =
                                    Uri.parse(_textResultController.text);
                                canLaunchUrl(url)
                                    .then((value) => launchUrl(url,
                                        mode: LaunchMode.externalApplication))
                                    .catchError(() => MotionToast.error(
                                            title: Text("Error"),
                                            description:
                                                Text("Result is not URL"),
                                            position: MotionToastPosition.top)
                                        .show(context));
                              },
                              text: 'Open URL',
                              shape: GFButtonShape.pills,
                            ),
                            SizedBox(height: 5.0),
                            GFButton(
                              onPressed: resetText,
                              text: 'Reset',
                              color: GFColors.DANGER,
                              shape: GFButtonShape.pills,
                            ),
                          ],
                        ),
                      ))))
          : Column(
              children: [
                Expanded(flex: 4, child: _buildQrView(context)),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GFButton(
                            shape: GFButtonShape.pills,
                            fullWidthButton: true,
                            color: GFColors.SUCCESS,
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text(snapshot.data == false
                                    ? 'Enable Flash'
                                    : 'Disable Flash');
                              },
                            ),
                          ),
                          SizedBox(height: 5.0),
                          GFButton(
                            shape: GFButtonShape.pills,
                            fullWidthButton: true,
                            color: GFColors.PRIMARY,
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            ),
                          ),
                        ]),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _textResultController.text = result!.code.toString();
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    _textResultController.dispose();
    controller?.dispose();
    super.dispose();
  }
}
