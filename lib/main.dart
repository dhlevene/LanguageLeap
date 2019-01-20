import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:translator/translator.dart';

import 'dart:async';
import 'dart:io';

class Language {
  const Language(this.language);

  final String language;
}

List<CameraDescription> cameras;

Future<void> main() async {
  cameras = await availableCameras();
  runApp(MyApp());
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Leap',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Language Leap'),
        ),
        body: Center(
          child: MyHomePage(),
      ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _MyHomePageState extends State<MyHomePage> {
  int _score = 0;
  int _numWrong = 0;
  int _numRight = 0;
  String imagePath;
  CameraController controller;
  bool _textFieldEnabled = false;
  String _answer;

  void _onCorrect() {
    setState(() {
      _score += 50;
      _numRight++;
    });
  }

  void _onIncorrect() {
    setState(() {
      _numWrong++;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    myController.dispose();
    super.dispose();
  }

  void onTakePictureButtonPressed() {
    print('took a picture!');
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
        });
      }
    });
  }  

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  Widget _captureIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.deepOrange,
          iconSize: 30,
          tooltip: 'Take Picture',
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      return null;
    }

    // final Directory extDir = await getTemporaryDirectory();
    // final String dirPath = '${extDir.path}/Pictures/flutter_test';
    // await Directory(dirPath).create(recursive: true);
    // final String filePath = '$dirPath/${timestamp()}.jpg';
    // print('path: $filePath');

    final Directory extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    print('path: $filePath');

    // final Directory extDir = await getApplicationDocumentsDirectory();
    // final String dirPath = '${extDir.path}/Pictures/flutter_test';
    // await Directory(dirPath).create(recursive: true);
    // final String filePath = '$dirPath/${timestamp()}.jpg';
    // print('path: $filePath');

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    setState(() {
      _textFieldEnabled = true;
    });
    print("text field enabled");

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }



  Widget camera() {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureIcon(),
        ],
      ),
    );
  }

  final myController = TextEditingController();

  void _checkAnswer() {
    print('checking answer...');
    // compare text to another language
  }

  Widget inputText() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: TextField(
          enabled: _textFieldEnabled,
          controller: myController,
          onChanged: (text) {
            print("Text field: $text");
          },
          onSubmitted: (String text) {
            setState(() {_answer = text;});
            _checkAnswer();
          },
          decoration: InputDecoration(
            hintText: 'You get points for answering right',
            labelText: 'What is the picture of?' ,
          ),
          style: new TextStyle(
            fontSize: 15.0,
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w300,
            fontFamily: "Roboto",
          )
        ),
      ),
    );
  }

  

  Language selectedUser;
  List<Language> languages = <Language>[const Language('Spanish'), const Language('French'), const Language('German')];

  Widget dropdown() {
    return new Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: DropdownButton(
          elevation: 20,
          value: selectedUser,
          onChanged: (Language newValue) {
            setState(() {
              selectedUser = newValue;
            });
          },
          items: languages.map((Language language) {
            return new DropdownMenuItem<Language>(
              value: language,
              child: new Text(
                language.language,
                style: new TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Score: $_score   Wrong: $_numWrong   Right: $_numRight',
                    style: Theme.of(context).textTheme.body1,
                  ),
                )
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: controller.value.isInitialized == false
                  ? Container()
                  : Container(
                    height: 400.0,
                    width: 265.0,
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: camera(),
                    ),
                  ),
                ),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    height: 50.0,
                    width: 250.0,
                    child: inputText(),
                  ),
                ),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Container(
                    height: 40,
                    width: 81.0,
                    child: dropdown(),
                  ),
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }
}
