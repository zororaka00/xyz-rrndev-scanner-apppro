import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:getwidget/getwidget.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

final qrKey = GlobalKey();

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({Key? key}) : super(key: key);

  @override
  _GenerateScreenState createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  TextEditingController _textEditingController = TextEditingController();
  String generatedText = '';

  void generateText() {
    setState(() {
      generatedText = _textEditingController.text;
    });
  }

  void resetText() {
    setState(() {
      _textEditingController.text = '';
      generatedText = '';
    });
  }

  Future<void> pasteTextFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _textEditingController.text = data.text!;
      });
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(5.0),
          child: SingleChildScrollView(
            child: GFCard(
              content: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Generate QR Code',
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
                    TextField(
                        controller: _textEditingController,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Input Text',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.paste),
                            onPressed: pasteTextFromClipboard,
                          ),
                        )),
                    SizedBox(height: 5.0),
                    GFButton(
                      onPressed: _textEditingController.text.isEmpty
                          ? null
                          : generateText,
                      text: 'Generate',
                      shape: GFButtonShape.pills,
                    ),
                    SizedBox(height: 5.0),
                    GFButton(
                      onPressed: _textEditingController.text.isEmpty
                          ? null
                          : resetText,
                      text: 'Reset',
                      color: GFColors.DANGER,
                      shape: GFButtonShape.pills,
                    ),
                    SizedBox(height: 5.0),
                    if (generatedText.isNotEmpty)
                      GFButton(
                        onPressed: downloadQrCode,
                        text: 'Download',
                        color: GFColors.SUCCESS,
                        shape: GFButtonShape.pills,
                      ),
                    Visibility(
                        visible: generatedText.isNotEmpty,
                        child: Column(children: [
                          SizedBox(height: 5.0),
                          RepaintBoundary(
                            key: qrKey,
                            child: CustomPaint(
                              painter: QrPainter(
                                  data: generatedText,
                                  options: const QrOptions(
                                      shapes: QrShapes(
                                          darkPixel: QrPixelShapeRoundCorners(
                                              cornerFraction: .5),
                                          frame: QrFrameShapeRoundCorners(
                                              cornerFraction: .25),
                                          ball: QrBallShapeRoundCorners(
                                              cornerFraction: .25)),
                                      colors: QrColors(
                                          dark: QrColorLinearGradient(
                                              colors: [
                                            Color.fromARGB(255, 255, 0, 0),
                                            Color.fromARGB(255, 0, 0, 255),
                                          ],
                                              orientation: GradientOrientation
                                                  .leftDiagonal)))),
                              size: const Size(200, 200),
                            ),
                          ),
                        ]))
                  ],
                ),
              ),
            ),
          )),
    );
  }

  Future<void> downloadQrCode() async {
    const double qrSize = 400.0; // adjust size as needed

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final QrPainter painter = QrPainter(
        data: generatedText,
        options: const QrOptions(
            shapes: QrShapes(
                darkPixel: QrPixelShapeRoundCorners(cornerFraction: .5),
                frame: QrFrameShapeRoundCorners(cornerFraction: .25),
                ball: QrBallShapeRoundCorners(cornerFraction: .25)),
            colors: QrColors(
                dark: QrColorLinearGradient(colors: [
              ui.Color.fromARGB(255, 255, 0, 0),
              ui.Color.fromARGB(255, 0, 0, 255),
            ], orientation: GradientOrientation.leftDiagonal))));

    painter.paint(canvas, ui.Size.square(qrSize));

    final ui.Image qrImage =
        await recorder.endRecording().toImage(qrSize.toInt(), qrSize.toInt());

    ByteData? byteData =
        await qrImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final result = await ImageGallerySaver.saveImage(pngBytes);

    if (result['isSuccess']) {
      MotionToast.success(
              title: Text("Success"),
              description: Text("File saved successfully"),
              position: MotionToastPosition.top)
          .show(context);
    } else {
      MotionToast.error(
              title: Text("Error"),
              description: Text("Failed to save file"),
              position: MotionToastPosition.top)
          .show(context);
    }
  }
}
