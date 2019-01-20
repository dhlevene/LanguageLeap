import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:core';

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
  String base64Image;
  String label;
  CameraController controller;
  bool _textFieldEnabled = false;
  String _answer;
  Language selectedLanguage = null;

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

    if(imagePath != null)
      setState(() {
          base64Image = processImage(imagePath);
      });

    if(base64Image != null){
      classifyImage(base64Image).then((String responseBody){
        setState(() {
          label = responseBody;
          print("label $label");
        });
      });
    }
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
        Text(
          label == null ? "English Word: " : "English Word: $label",
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  Future<String> translate(String text) async {
    GoogleTranslator translator = GoogleTranslator();
    var translation;
    if (selectedLanguage.language == 'Spanish')
    {
       translation = await translator.translate(text, from: 'en', to: 'es');
      print("translation: " + translation);
    }
    else if (selectedLanguage.language == 'French')
    {
       translation = await translator.translate(text, from: 'en', to: 'fr');
      print("translation: " + translation);
    }
    
    else if (selectedLanguage.language == 'German')
    {
       translation = await translator.translate(text, from: 'en', to: 'de');
      print("translation: " + translation);
    }
    
    


    return translation;
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

  String processImage(String imagePath){
    File file = new File(imagePath);
      
    List<int> fileBytes = file.readAsBytesSync();
    //print('filebytes: $fileBytes');
    String base64Image = base64Encode(fileBytes);
    //print('base64 $base64Image');
    return base64Image;
  }

  Future<String> classifyImage(String base64Image) async{

    String googleVisionEndpoint = "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyDKVljgt5f4I2dFcALCtwRBlRVnBCbHvy8";
    Map map = {
      "requests" : [
          {
            "image" : {
              "content" : base64Image
            },
            "features": [
              {
                "type" : "LABEL_DETECTION",
                "maxResults" : 1
              }
            ]
          }
        ]
      };
    
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(googleVisionEndpoint));

    request.headers.set('content-type', 'application/json');
    request.add(utf8.encode(json.encode(map)));

    HttpClientResponse response = await request.close();
    // todo - you should check the response.statusCode
    String reply = await response.transform(utf8.decoder).join();
    httpClient.close();
    
    Map<String, dynamic> test = jsonDecode(reply);

   print('Test json: $test');

    return test['responses'][0]['labelAnnotations'][0]['description'];
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

  
  Future checkAns(String ans) async {
    String s = await translate(label);
    ans = ans.toLowerCase();
    if (ans == s) {
      _onCorrect();
      _popup(true, ans, s);
      return;
    } else {
      _onIncorrect();
      _popup(false, ans, s);
      return;
    }
  }

  Future<void> _popup(bool correct, String ans, String correctAns) async {
    correct
      ? showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Answer: $ans'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('That is correct!'),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('YAY'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  )
  : showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Answer: $ans'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sorry, that was wrong.'),
                Text('The correct answer was: $correctAns'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Damn...'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            myController.clear();
            setState(() {
              _textFieldEnabled = false;
              _answer = text;
              checkAns(_answer);
            });
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

  List<Language> languages = <Language>[const Language('Spanish'), const Language('French'), const Language('German')];

  Widget dropdown() {
    return new Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: DropdownButton(
          elevation: 20,
          value: selectedLanguage,
          onChanged: (Language newValue) {
            setState(() {
              selectedLanguage = newValue;
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
