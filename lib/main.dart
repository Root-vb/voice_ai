import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'VOICE AI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  late ChewieController chewieController;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initVideo();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _initVideo() async {
    _controller = VideoPlayerController.network(
        'https://tryptomer-staging.s3.ap-south-1.amazonaws.com/hls-videos/index.m3u8')
      ..initialize().then((_) {
        setState(() {});
      });

    chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
    );
  }

  void _startListening() async {
    await _speechToText.listen(
        onResult: _onSpeechResult, localeId: "ru-RU", listenFor: Duration(seconds: 10));
    setState(() {});
  }

  void _onSpeechResult(result) {
    debugPrint("Result $result");
    setState(() {
      _lastWords = result.recognizedWords;
      if (_lastWords.contains("играть")) {
        chewieController.play();
      } else if (_lastWords.contains("пауза")) {
        chewieController.pause();
      } else if (_lastWords.contains("enter full screen")) {
        chewieController.enterFullScreen();
      } else if (_lastWords.contains("exit full screen")) {
        chewieController.exitFullScreen();
      }
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Chewie(
                      controller: chewieController,
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
          Text(
            _speechToText.isListening
                ? _lastWords
                : _speechEnabled
                    ? 'Tap the microphone to start listening...'
                    : 'Speech not available',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    chewieController.dispose();
  }
}
