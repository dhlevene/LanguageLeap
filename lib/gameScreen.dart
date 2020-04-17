import 'package:flutter/material.dart';

void main() => runApp(GameScreen());

class GameScreen extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Take A Picture"),
      ),
      body: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CurrentGameState createState() => _CurrentGameState();
}

class _CurrentGameState extends State<CameraScreen> {
  int _score = 0;
  int _numWrong = 0;
  int _numRight = 0;

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
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Score: $_score   Wrong: $_numWrong   Right: $_numRight',
                    style: Theme.of(context).textTheme.title,
                  ),
                )
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
              ]
            ),
          ],
        ),
      ),
    );
  }
}
