import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../application/app_theme/color_scheme.dart';

class InputTag extends StatefulWidget {
  const InputTag({Key? key}) : super(key: key);

  @override
  InputTagState createState() => InputTagState();
}

class InputTagState extends State<InputTag> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Row(
                children: [
                  BackButton(color: ColorManager.white,),
                ],
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: const Text(
                  'Recognized words:',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                         _lastWords,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: 'hf_no_number:|hf_commands:input|',
        button: true,
        onTap:  _speechToText.isNotListening ? _startListening : _stopListening,
        child: FloatingActionButton(
          onPressed:
          // If not yet listening for speech start, otherwise stop
          _speechToText.isNotListening ? _startListening : _stopListening,
          tooltip: 'Listen',
          child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
        ),
      ),
    );
  }
}